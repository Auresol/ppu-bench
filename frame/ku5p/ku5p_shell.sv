`default_nettype none


// The shell of the ku5p frame: FPGA-only logic with no pin of its own but the oscillator. The chip's clock is the board's 100 MHz LVDS
// oscillator (H23/H24, ku5p.xdc) through an MMCM (100 MHz x 10 / 20 = 50 MHz). The reset is a power-on count after the MMCM locks.
// Its outputs are what wiring.yaml names (shell.clk, shell.rst_n). IBUFDS, MMCME4_BASE and BUFG are Xilinx primitives; the chip's RTL never
// instantiates them.

module ku5p_shell (
    input  wire clk_100_p,    // the board's 100 MHz oscillator (ku5p.xdc)
    input  wire clk_100_n,
    output wire eth_clk125,       // 125 MHz for the Ethernet MAC
    output wire eth_clk125_90,    // 125 MHz at 90 degrees: the RGMII transmit clock
    output wire eth_rst,          // active high: the MAC's reset, released synchronously with eth_clk125
    output wire eth_phy_rst_n,    // the PHY's reset, active low, held 16.8 ms after the lock
    output wire clk,          // 50 MHz from the MMCM, on a global buffer
    output wire rst_n         // active low: until the MMCM locks and the power-on count ends
);

wire clk_100, clk_fb, clk_mmcm, locked;

IBUFDS u_ibufds (.I(clk_100_p), .IB(clk_100_n), .O(clk_100));

MMCME4_BASE #(
    .CLKIN1_PERIOD    (10.000),   // 100 MHz
    .DIVCLK_DIVIDE    (1),
    .CLKFBOUT_MULT_F  (10.000),   // VCO 1000 MHz
    .CLKOUT1_DIVIDE   (8),        // 125 MHz
    .CLKOUT2_DIVIDE   (8),        // 125 MHz
    .CLKOUT2_PHASE    (90.0),     // 90 degrees
    .CLKOUT0_DIVIDE_F (20.000)    // 50 MHz
) u_mmcm (
    .CLKIN1   (clk_100),
    .CLKFBIN  (clk_fb),
    .CLKFBOUT (clk_fb),
    .CLKOUT0  (clk_mmcm),
    .CLKOUT1  (clk125_mmcm),
    .CLKOUT2  (clk125_90_mmcm),
    .LOCKED   (locked),
    .PWRDWN   (1'b0),
    .RST      (1'b0)
);

BUFG u_bufg (.I(clk_mmcm), .O(clk));

// Power-on reset: 2^16 clk (~1.3 ms at 50 MHz) after the MMCM locks, released synchronised to clk. Asserts at once on a lost lock.
reg [16:0] por = 0;
always @(posedge clk)
    if (!locked) por <= 0;
    else if (!por[16]) por <= por + 1'b1;

reg [3:0] rst_pipe = 4'hF;
always @(posedge clk)
    rst_pipe <= {rst_pipe[2:0], ~por[16]};

assign rst_n = ~rst_pipe[3];

// The Ethernet clocks (phy: rgmii, guide/host-link.md): 125 MHz, and the same at 90 degrees for the RGMII transmit clock. Both stay on while
// the MMCM is locked; eth_rst (active high) holds the MAC and the link until then, released synchronised to eth_clk125.
wire clk125_mmcm, clk125_90_mmcm;
BUFG u_bufg125 (.I(clk125_mmcm), .O(eth_clk125));
BUFG u_bufg125_90 (.I(clk125_90_mmcm), .O(eth_clk125_90));

reg [3:0] eth_rst_pipe = 4'hF;
always @(posedge eth_clk125)
    eth_rst_pipe <= {eth_rst_pipe[2:0], ~locked};

assign eth_rst = eth_rst_pipe[3];

// The PHY's reset (ETH_RST, J10) is held low for 2^21 clocks of 125 MHz (16.8 ms, more than the 10 ms the PHY needs) after the MMCM locks, then released.
reg [20:0] phy_cnt = 0;
always @(posedge eth_clk125)
    if (!locked) phy_cnt <= 0;
    else if (!phy_cnt[20]) phy_cnt <= phy_cnt + 1'b1;

assign eth_phy_rst_n = phy_cnt[20];

endmodule
