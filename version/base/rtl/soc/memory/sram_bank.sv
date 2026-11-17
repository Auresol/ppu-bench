// Single-port SRAM bank with one AHB-Lite slave port. Zero wait states, one write buffer.
//
// One copy of this file serves FPGA, simulation and ASIC. The storage is `sram_bank_array`
// (adr/sram-storage/): hw-proj generates it for FPGA / simulation, a vendor array.sv stands for it on ASIC.
// Its contract: single port, rising edge of clk; a read (en && !we) gives rdata in the NEXT cycle only,
// a write (en && we) stores the bytes wmask selects.
//
// Timing (cycle N = address phase of an access, N+1 = its data phase):
//   read  : issued to the array in cycle N, so rdata is valid in N+1, the AHB data phase. hrdata = rdata.
//   write : its data (hwdata) arrives in N+1. It is written to the array in N+1 if no read address phase
//           uses the array in that cycle, else it is held in the one-entry write buffer and written in
//           the first later cycle without a read address phase.
// One array port per cycle, priority: read address phase > buffered write > write in its data phase.
//
// Why the buffer holds at most one write: it is filled in cycle C-1 only when a write is in its data
// phase there AND a read has its address phase there. Then cycle C is a read's data phase, so no write
// is in its data phase in C and the buffer cannot be filled again before it is drained.
//
// Forwarding: a read whose array access happened before the buffered write landed returns stale bytes.
// While the buffer is full, a read data phase on the buffer's address takes the buffer's bytes
// (byte-wise by mask) over rdata.
//
// rst_n (asynchronous, active low) clears the data phase registers and the buffer. The array has no reset (contract).

`default_nettype none

module sram_bank #(
    parameter DEPTH = 2048,   // words (sram22 2048x32; keep equal to doc/sram_bank.yaml, the top passes no DEPTH)
    parameter WIDTH = 32,     // bits per word (32 only: haddr/hwdata are 32 bits)
    // FPGA / simulation: $readmemh image for this bank (DEPTH words), passed to the array. "" = none.
    // Ignored by a vendor array on ASIC.
    parameter INIT_FILE = ""
) (
    input wire clk,
    input wire rst_n,   // asynchronous, active low

    // Single AHB-Lite port (haddr above the bank, htrans[0] are not needed)
    /* verilator lint_off UNUSEDSIGNAL */
    input  wire [31:0] haddr,
    input  wire        hwrite,
    input  wire [1:0]  htrans,
    /* verilator lint_on UNUSEDSIGNAL */
    input  wire [2:0]  hsize,
    input  wire [31:0] hwdata,
    output wire [31:0] hrdata,
    output wire        hready,
    output wire        hresp,
    output wire        hexokay
);

localparam AW = $clog2(DEPTH);

// ----------------------------------------------------------------------------
// Address phase decode

wire [AW-1:0] word_addr = haddr[AW+1:2];
wire          active    = htrans[1];
wire          rd_now    = active && !hwrite;   // read address phase: the array is used this cycle

// Byte strobes from hsize and the address offset
wire [3:0] wstrb = (hsize == 3'b000) ? (4'b0001 << haddr[1:0]) :
                   (hsize == 3'b001) ? (4'b0011 << haddr[1:0]) :
                                        4'b1111;

// ----------------------------------------------------------------------------
// Data phase registers (the address phase of the previous cycle)

reg [AW-1:0] dp_addr;
reg          dp_read;
reg          dp_write;
reg [3:0]    dp_wstrb;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dp_addr  <= '0;
        dp_read  <= 1'b0;
        dp_write <= 1'b0;
        dp_wstrb <= 4'b0;
    end else begin
        dp_addr  <= word_addr;
        dp_read  <= rd_now;
        dp_write <= active && hwrite;
        dp_wstrb <= wstrb;
    end
end

// ----------------------------------------------------------------------------
// Write buffer

reg          wb_valid;
reg [AW-1:0] wb_addr;
reg [3:0]    wb_wstrb;
reg [31:0]   wb_data;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wb_valid <= 1'b0;
        wb_addr  <= '0;
        wb_wstrb <= 4'b0;
        wb_data  <= 32'b0;
    end else if (rd_now && dp_write) begin
        // the array is busy with a read: hold the write that is in its data phase
        wb_valid <= 1'b1;
        wb_addr  <= dp_addr;
        wb_wstrb <= dp_wstrb;
        wb_data  <= hwdata;
    end else if (!rd_now) begin
        wb_valid <= 1'b0;   // the array takes the buffered write this cycle (if any)
    end
end

// ----------------------------------------------------------------------------
// Array port

wire             arr_en    = rd_now || wb_valid || dp_write;
wire             arr_we    = !rd_now;
wire [AW-1:0]    arr_addr  = rd_now ? word_addr : wb_valid ? wb_addr : dp_addr;
wire [3:0]       arr_wmask = wb_valid ? wb_wstrb : dp_wstrb;
wire [31:0]      arr_wdata = wb_valid ? wb_data : hwdata;
wire [WIDTH-1:0] rdata;

sram_bank_array #(
    .DEPTH    (DEPTH),
    .WIDTH    (WIDTH),
    .INIT_FILE(INIT_FILE)
) u_array (
    .clk  (clk),
    .en   (arr_en),
    .we   (arr_we),
    .wmask(arr_wmask),
    .addr (arr_addr),
    .wdata(arr_wdata),
    .rdata(rdata)
);

// ----------------------------------------------------------------------------
// Read data: the array's bytes, the buffer's bytes where a buffered write is newer

wire fwd = dp_read && wb_valid && (wb_addr == dp_addr);

assign hrdata = {
    (fwd && wb_wstrb[3]) ? wb_data[31:24] : rdata[31:24],
    (fwd && wb_wstrb[2]) ? wb_data[23:16] : rdata[23:16],
    (fwd && wb_wstrb[1]) ? wb_data[15: 8] : rdata[15: 8],
    (fwd && wb_wstrb[0]) ? wb_data[ 7: 0] : rdata[ 7: 0]
};

assign hready  = 1'b1;
assign hresp   = 1'b0;
assign hexokay = 1'b0;

endmodule
