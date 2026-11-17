// The texture loader (doc/texld.yaml): the core's window into bus tex. An access at window offset k on bus main becomes one access
// at address k on bus tex, carried out by this module's master port; the main bus waits (s_hready low) until it is done.
// While lock is high (the render unit has started) every access gets the AHB two-cycle error and nothing reaches bus tex: the
// textures are static from then on, and bus tex belongs to the render unit alone.
//
// One access at a time. The crossbar presents an address phase (s_htrans[1]) only while s_hready is high, so an access is
// taken in a ready state (IDLE, DONE, ERR2) and its data phase starts in the next cycle:
//   ST_ADDR  main data phase, s_hready low: capture the write data, put the address phase on bus tex until it is accepted
//   ST_DATA  bus tex data phase: the captured write data on m_hwdata, wait for m_hready, keep the read data
//   ST_DONE  s_hready high with the read data: the main access completes
//   ST_ERR2  the second cycle of the error response (the first is ST_ADDR with lock high)
// Wait states on bus main: 2 when bus tex answers at once (ST_ADDR, ST_DATA), as doc/texld.yaml says (wait: {max: 3}).

`default_nettype none

module texld (
    input  wire        clk,
    input  wire        rst_n,

    // slave on bus main
    input  wire [31:0] s_haddr,
    input  wire        s_hwrite,
    input  wire [1:0]  s_htrans,
    input  wire [2:0]  s_hsize,
    input  wire [31:0] s_hwdata,
    output wire [31:0] s_hrdata,
    output wire        s_hready,
    output wire        s_hresp,

    // master on bus tex
    output wire [31:0] m_haddr,
    output wire        m_hwrite,
    output wire [1:0]  m_htrans,
    output wire [2:0]  m_hsize,
    output wire [31:0] m_hwdata,
    input  wire [31:0] m_hrdata,
    input  wire        m_hready,
    /* verilator lint_off UNUSEDSIGNAL */
    input  wire        m_hresp,   // bus tex maps the whole window: no error can come back
    /* verilator lint_on UNUSEDSIGNAL */

    input  wire        lock
);

localparam [1:0] HTRANS_IDLE = 2'b00, HTRANS_NONSEQ = 2'b10;
localparam [2:0] ST_IDLE = 3'd0, ST_ADDR = 3'd1, ST_DATA = 3'd2, ST_DONE = 3'd3, ST_ERR2 = 3'd4;

reg [2:0]  state;
reg [15:0] addr_r;    // the window is 64kb: bus tex address = window offset
reg        write_r;
reg [2:0]  size_r;
reg [31:0] wdata_r;
reg [31:0] rdata_r;

wire ready_state = (state == ST_IDLE) || (state == ST_DONE) || (state == ST_ERR2);
wire take        = ready_state && s_htrans[1];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state   <= ST_IDLE;
        addr_r  <= 16'h0;
        write_r <= 1'b0;
        size_r  <= 3'b0;
        wdata_r <= 32'h0;
        rdata_r <= 32'h0;
    end else begin
        if (take) begin
            addr_r  <= s_haddr[15:0];
            write_r <= s_hwrite;
            size_r  <= s_hsize;
        end
        case (state)
            ST_ADDR: begin
                if (lock) begin
                    state <= ST_ERR2;
                end else begin
                    wdata_r <= s_hwdata;   // held by the main master for the whole data phase; keep it for bus tex's
                    if (m_hready) state <= ST_DATA;
                end
            end
            ST_DATA: begin
                if (m_hready) begin
                    rdata_r <= m_hrdata;
                    state   <= ST_DONE;
                end
            end
            default: state <= take ? ST_ADDR : ST_IDLE;   // ST_IDLE, ST_DONE, ST_ERR2
        endcase
    end
end

// bus main
assign s_hready = ready_state;
assign s_hresp  = (state == ST_ADDR && lock) || (state == ST_ERR2);
assign s_hrdata = rdata_r;

// bus tex: the address phase in ST_ADDR (unless refused), the data phase in ST_DATA
assign m_htrans = (state == ST_ADDR && !lock) ? HTRANS_NONSEQ : HTRANS_IDLE;
assign m_haddr  = {16'h0, addr_r};
assign m_hwrite = write_r;
assign m_hsize  = size_r;
assign m_hwdata = wdata_r;

wire _unused = &{1'b0, s_haddr[31:16], s_htrans[0]};

endmodule
