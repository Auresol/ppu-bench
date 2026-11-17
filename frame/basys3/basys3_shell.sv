`default_nettype none


// The shell of the Basys3 frame: FPGA-only logic with no physical pins. Its inputs are xdc ports of the same name
// (clk: the 100 MHz oscillator, btnC: the centre button, active high), its outputs are what wiring.yaml names
// (shell.sys_clk, shell.por_n). The chip runs at 100 MHz (system.yaml clk_pin freq_mhz), the board oscillator is
// 100 MHz: an MMCM divides it. MMCME2_BASE and BUFG are Xilinx primitives; the chip's RTL never instantiates them.

module basys3_shell (
    input  wire clk,       // W5, 100 MHz
    input  wire btnC,      // the centre button, active high: the reset
    output wire sys_clk,   // the chip's clock (clk_pin)
    output wire por_n      // active low, de-asserted two sys_clk cycles after the MMCM locks
);

wire clkfb, clkfb_b, clk_div, locked;

// VCO = 100 MHz * 10 / 1 = 1000 MHz (Artix-7 -1: 600..1200); CLKOUT0 = 1000 / 10.000 = 100 MHz
MMCME2_BASE #(
    .BANDWIDTH        ("OPTIMIZED"),
    .CLKIN1_PERIOD    (10.0),
    .DIVCLK_DIVIDE    (1),
    .CLKFBOUT_MULT_F  (10.0),
    .CLKOUT0_DIVIDE_F (10.000)
) u_mmcm (
    .CLKIN1   (clk),
    .CLKFBIN  (clkfb_b),
    .CLKFBOUT (clkfb),
    .CLKOUT0  (clk_div),
    .LOCKED   (locked),
    .PWRDWN   (1'b0),
    .RST      (btnC)
);

BUFG u_fb  (.I(clkfb), .O(clkfb_b));
BUFG u_clk (.I(clk_div), .O(sys_clk));

// Reset: asserted while the MMCM is not locked or the button is down; released synchronously
wire arst = ~locked | btnC;
/* verilator lint_off SYNCASYNCNET */   // the usual reset synchroniser: asynchronous assert, synchronous release
reg [1:0] q;   // reset by arst below
always @(posedge sys_clk or posedge arst) begin
    if (arst) q <= 2'b00;
    else      q <= {q[0], 1'b1};
end
/* verilator lint_on SYNCASYNCNET */
assign por_n = q[1];

endmodule
