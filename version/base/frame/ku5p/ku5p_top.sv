module ku5p_top (
    // Board side: the ports of the master xdc that this wiring uses (ku5p_pins.xdc constrains them)
    input  wire clk_100_p,
    input  wire clk_100_n,
    input  wire eth_rx_clk,
    input  wire eth_rx_ctl,
    input  wire [3:0] eth_rxd,
    output wire eth_tx_clk,
    output wire eth_tx_ctl,
    output wire [3:0] eth_txd,
    output wire eth_rst_n,
    output wire eth_mdc
);

    // hw-proj: GENERATE BEGIN

    // Signals shared by the parts below
    // Pad bundle, between the chip top and the board wiring below
    wire [61:0] pad_out;
    wire [61:0] pad_oe;
    wire [61:0] pad_in;

    // Named pins and pins: of system.yaml, between the chip top and the board
    wire pin_clk;
    wire pin_porb;

    // Taps of the host link (HWPROJ_TAP)
    wire tap_racer0_pix_stb;

    // Outputs of the shell ku5p_shell (frame-spec.yaml shell:)
    wire shell_eth_clk125;
    wire shell_eth_clk125_90;
    wire shell_eth_rst;
    wire shell_eth_phy_rst_n;
    wire shell_clk;
    wire shell_rst_n;

    // Outputs of the device link (module hwlink_ku5p, wiring.yaml external:)
    wire        dev_link_s_tready;
    wire [7:0]  dev_link_m_tdata;
    wire        dev_link_m_tvalid;
    wire        dev_link_m_tlast;
    wire [10:0] dev_link_m_len;
    wire [47:0] dev_link_m_peer;
    wire        dev_link_quiet;

    // Outputs of the device eth (module hwlink_eth, wiring.yaml external:)
    wire        dev_eth_rgmii_tx_clk;
    wire [3:0]  dev_eth_rgmii_txd;
    wire        dev_eth_rgmii_tx_ctl;
    wire        dev_eth_phy_rst_n;
    wire        dev_eth_mdc;
    wire [7:0]  dev_eth_s_tdata;
    wire        dev_eth_s_tvalid;
    wire        dev_eth_s_tlast;
    wire [47:0] dev_eth_s_peer;
    wire        dev_eth_m_tready;

    // Module instances
    // The shell: FPGA-only logic with no physical pins (frame/ku5p/ku5p_shell.sv)
    ku5p_shell u_shell (
        .clk_100_p(clk_100_p),
        .clk_100_n(clk_100_n),
        .eth_clk125(shell_eth_clk125),
        .eth_clk125_90(shell_eth_clk125_90),
        .eth_rst(shell_eth_rst),
        .eth_phy_rst_n(shell_eth_phy_rst_n),
        .clk(shell_clk),
        .rst_n(shell_rst_n)
    );

    // The chip top: it reaches the outside only through the pad bundle and its named pins; keep_hierarchy keeps its port names through Vivado synthesis, the clock checks name them
    (* keep_hierarchy = "yes" *) ppu_bench u_chip (
        .pad_out(pad_out),
        .pad_oe(pad_oe),
        .pad_in(pad_in),
        .clk(pin_clk),
        .porb(pin_porb),
        .tap_racer0_pix_stb(tap_racer0_pix_stb)
    );

    // Device models on the pads and the board
    // Devices: the RTL models of what the board has outside the chip (wiring.yaml external: module:); device/ holds their files
    hwlink_ku5p #(
        .IP(32'hc0a83202),
        .PORT(4747),
        .LCLK_HZ(125000000),
        .REVERT_MS(500),
        .FLUSH_US(1000)
    ) u_dev_link (
        .lclk(shell_eth_clk125),
        .lrst_n(~shell_eth_rst),
        .s_tdata(dev_eth_s_tdata),
        .s_tvalid(dev_eth_s_tvalid),
        .s_tready(dev_link_s_tready),
        .s_tlast(dev_eth_s_tlast),
        .s_peer(dev_eth_s_peer),
        .m_tdata(dev_link_m_tdata),
        .m_tvalid(dev_link_m_tvalid),
        .m_tready(dev_eth_m_tready),
        .m_tlast(dev_link_m_tlast),
        .m_len(dev_link_m_len),
        .m_peer(dev_link_m_peer),
        .quiet(dev_link_quiet),
        .cclk(pin_clk),
        .crst_n(pin_porb),
        .vga_pad({pad_out[59], pad_out[58], pad_out[57], pad_out[56], pad_out[55], pad_out[54], pad_out[53], pad_out[52], pad_out[51], pad_out[50], pad_out[49], pad_out[48], pad_out[61], pad_out[60]}),
        .vga_stb(tap_racer0_pix_stb)
    );
    hwlink_eth #(
        .IP(32'hc0a83202),
        .PORT(4747),
        .MAC(48'h020000000001)
    ) u_dev_eth (
        .clk125(shell_eth_clk125),
        .clk125_90(shell_eth_clk125_90),
        .rst(shell_eth_rst),
        .phy_rst_n_in(shell_eth_phy_rst_n),
        .rgmii_rx_clk(eth_rx_clk),
        .rgmii_rxd(eth_rxd),
        .rgmii_rx_ctl(eth_rx_ctl),
        .rgmii_tx_clk(dev_eth_rgmii_tx_clk),
        .rgmii_txd(dev_eth_rgmii_txd),
        .rgmii_tx_ctl(dev_eth_rgmii_tx_ctl),
        .phy_rst_n(dev_eth_phy_rst_n),
        .mdc(dev_eth_mdc),
        .s_tdata(dev_eth_s_tdata),
        .s_tvalid(dev_eth_s_tvalid),
        .s_tready(dev_link_s_tready),
        .s_tlast(dev_eth_s_tlast),
        .s_peer(dev_eth_s_peer),
        .m_tdata(dev_link_m_tdata),
        .m_tvalid(dev_link_m_tvalid),
        .m_tready(dev_eth_m_tready),
        .m_tlast(dev_link_m_tlast),
        .m_len(dev_link_m_len),
        .m_peer(dev_link_m_peer)
    );
    assign eth_tx_clk = dev_eth_rgmii_tx_clk; // device eth drives the xdc port
    assign eth_txd = dev_eth_rgmii_txd; // device eth drives the xdc port
    assign eth_tx_ctl = dev_eth_rgmii_tx_ctl; // device eth drives the xdc port
    assign eth_rst_n = dev_eth_phy_rst_n; // device eth drives the xdc port
    assign eth_mdc = dev_eth_mdc; // device eth drives the xdc port

    // Named pins of the chip, from the xdc ports and the shell, and to the xdc ports
    assign pin_clk = shell_clk;
    assign pin_porb = shell_rst_n;

    // Pads wired to no xdc port read 0
    assign pad_in = 62'h0;

    // hw-proj: GENERATE END

endmodule
