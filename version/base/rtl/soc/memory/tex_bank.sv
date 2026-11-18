// The texture SRAM tex0 (doc/tex_bank.yaml): a single-port SRAM with one AHB-Lite slave port whose data is WIDTH bits, the
// data_width of bus tex (32 in the base, 64 or 128 in the bus-width versions). Taken from hw-proj's wide-bus example
// (src/cmd/testdata/widebus/rtl/fbram.sv). Zero wait states, one write buffer: the same bus side as sram_bank, with the
// byte strobes computed for WIDTH/8 lanes from hsize and the low address bits.
//
//   read  : issued to the array in the address phase, rdata is valid in the data phase (hrdata = rdata).
//   write : its data arrives in the data phase; it goes to the array then, or, when a read address phase uses the
//           array in that cycle, into the one-entry write buffer and is written in the first cycle without one.
// A read whose array access came before the buffered write landed takes the buffer's bytes (lane by lane).

`default_nettype none

module tex_bank #(
    parameter DEPTH = 16384,  // words (keep equal to doc/tex_bank.yaml)
    parameter WIDTH = 32      // bits per word: the data width of the bus it sits on (no INIT_FILE: doc/tex_bank.yaml)
) (
    input wire clk,
    input wire rst_n,

    /* verilator lint_off UNUSEDSIGNAL */
    input  wire [31:0]      haddr,
    input  wire             hwrite,
    input  wire [1:0]       htrans,
    /* verilator lint_on UNUSEDSIGNAL */
    input  wire [2:0]       hsize,
    input  wire [WIDTH-1:0] hwdata,
    output wire [WIDTH-1:0] hrdata,
    output wire             hready,
    output wire             hresp
);

localparam LANES = WIDTH / 8;
localparam LB    = $clog2(LANES);
localparam AW    = $clog2(DEPTH);

wire [AW-1:0] word_addr = haddr[AW+LB-1:LB];
wire          active    = htrans[1];
wire          rd_now    = active && !hwrite;

// the lanes a transfer of 2**hsize bytes at haddr covers (the address is aligned to the size)
function automatic [LANES-1:0] lanes(input [2:0] size, input [LB-1:0] off);
    integer n, base, i;
    begin
        n = 1 << size;
        base = (int'(off) / n) * n;
        lanes = '0;
        for (i = 0; i < LANES; i = i + 1)
            if (i >= base && i < base + n) lanes[i] = 1'b1;
    end
endfunction

wire [LANES-1:0] wstrb = lanes(hsize, haddr[LB-1:0]);

reg [AW-1:0]    dp_addr;
reg             dp_read;
reg             dp_write;
reg [LANES-1:0] dp_wstrb;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dp_addr  <= '0;
        dp_read  <= 1'b0;
        dp_write <= 1'b0;
        dp_wstrb <= '0;
    end else begin
        dp_addr  <= word_addr;
        dp_read  <= rd_now;
        dp_write <= active && hwrite;
        dp_wstrb <= wstrb;
    end
end

reg             wb_valid;
reg [AW-1:0]    wb_addr;
reg [LANES-1:0] wb_wstrb;
reg [WIDTH-1:0] wb_data;

`ifndef SYNTHESIS
initial wb_valid = 1'b0;
`endif

always @(posedge clk) begin
    if (rd_now && dp_write) begin
        wb_valid <= 1'b1;
        wb_addr  <= dp_addr;
        wb_wstrb <= dp_wstrb;
        wb_data  <= hwdata;
    end else if (!rd_now) begin
        wb_valid <= 1'b0;
    end
end

wire             arr_en    = rd_now || wb_valid || dp_write;
wire             arr_we    = !rd_now;
wire [AW-1:0]    arr_addr  = rd_now ? word_addr : wb_valid ? wb_addr : dp_addr;
wire [LANES-1:0] arr_wmask = wb_valid ? wb_wstrb : dp_wstrb;
wire [WIDTH-1:0] arr_wdata = wb_valid ? wb_data : hwdata;
wire [WIDTH-1:0] rdata;

tex_bank_array #(
    .DEPTH    (DEPTH),
    .WIDTH    (WIDTH),
    .INIT_FILE("")
) u_array (
    .clk  (clk),
    .en   (arr_en),
    .we   (arr_we),
    .wmask(arr_wmask),
    .addr (arr_addr),
    .wdata(arr_wdata),
    .rdata(rdata)
);

wire fwd = dp_read && wb_valid && (wb_addr == dp_addr);

genvar g;
generate
    for (g = 0; g < LANES; g = g + 1) begin : lane
        assign hrdata[8*g +: 8] = (fwd && wb_wstrb[g]) ? wb_data[8*g +: 8] : rdata[8*g +: 8];
    end
endgenerate

assign hready = 1'b1;
assign hresp  = 1'b0;

endmodule
