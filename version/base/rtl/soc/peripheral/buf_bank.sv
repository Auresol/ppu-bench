// A RAM bank with one AHB-Lite slave port, zero wait states: the bus side of sram_bank (rtl/soc/memory/sram_bank.sv) with the
// storage inferred here instead of sram_bank_array, so that the module is no `memory: sram` and so no firmware RAM (doc/buf_bank.yaml).
// The timing, the write buffer and the forwarding are those of sram_bank; read its header for them.

`default_nettype none

module buf_bank #(
    parameter DEPTH = 256     // words of 32 bits (keep equal to doc/buf_bank.yaml)
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
wire [31:0]      rdata;

// Inferred single-port RAM: byte-masked write, read data in the next cycle (the sram_bank_array contract)
reg [31:0] mem [0:DEPTH-1];
reg [31:0] rd;

always @(posedge clk) begin
    if (arr_en && arr_we) begin
        if (arr_wmask[0]) mem[arr_addr][ 7: 0] <= arr_wdata[ 7: 0];
        if (arr_wmask[1]) mem[arr_addr][15: 8] <= arr_wdata[15: 8];
        if (arr_wmask[2]) mem[arr_addr][23:16] <= arr_wdata[23:16];
        if (arr_wmask[3]) mem[arr_addr][31:24] <= arr_wdata[31:24];
    end
    if (arr_en && !arr_we) rd <= mem[arr_addr];
end

assign rdata = rd;

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
