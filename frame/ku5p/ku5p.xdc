# Master constraints of the ku5p frame. The board's 100 MHz differential oscillator is on H23/H24 (bank 66, GC pair L14), found by a clock
# probe (100.0 MHz; the same rate is on MGTREFCLK0_227 K7/K6). It is read as LVDS without termination, as the probe read it; the bank's VCCO is
# not known, so no internal termination. The other connectors of the board (FMC HPC, QSFP, a PCIe edge) are not used; the bitstream loads over JTAG.
set_property -dict {PACKAGE_PIN H23 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE} [get_ports clk_100_p]
set_property -dict {PACKAGE_PIN H24 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE} [get_ports clk_100_n]
create_clock -name sys_clk_100 -period 10.000 [get_ports clk_100_p]

# The RGMII Ethernet (host link, phy: rgmii): the pins of the owner's schematic, banks 86 and 87, as LVCMOS33. Bank 86 is 3.3 V (the PCIe reset
# on K9 is LVCMOS33 in the vendor's constraints); bank 87's VCCO was not seen, 3.3 V is assumed (the PHY is 3.3 V and drives the bank directly).
# PHY RTL8211E-VB-CG, address 001, 25 MHz crystal, RXDLY pulled up (the PHY delays RXC), TXDLY unstrapped. Transmit data is launched on the
# opposite clock edge, so at 100M (25 MHz) the edge lands mid window whatever TXDLY is; only gigabit needs the delay settled.
set_property -dict {PACKAGE_PIN E13 IOSTANDARD LVCMOS33} [get_ports eth_rx_clk]
set_property -dict {PACKAGE_PIN D14 IOSTANDARD LVCMOS33} [get_ports eth_rx_ctl]
set_property -dict {PACKAGE_PIN C14 IOSTANDARD LVCMOS33} [get_ports {eth_rxd[0]}]
set_property -dict {PACKAGE_PIN E12 IOSTANDARD LVCMOS33} [get_ports {eth_rxd[1]}]
set_property -dict {PACKAGE_PIN F12 IOSTANDARD LVCMOS33} [get_ports {eth_rxd[2]}]
set_property -dict {PACKAGE_PIN D13 IOSTANDARD LVCMOS33} [get_ports {eth_rxd[3]}]
set_property -dict {PACKAGE_PIN F13 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports eth_tx_clk]
set_property -dict {PACKAGE_PIN H14 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports eth_tx_ctl]
set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {eth_txd[0]}]
set_property -dict {PACKAGE_PIN G12 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {eth_txd[1]}]
set_property -dict {PACKAGE_PIN G14 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {eth_txd[2]}]
set_property -dict {PACKAGE_PIN H13 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12} [get_ports {eth_txd[3]}]
set_property -dict {PACKAGE_PIN J10 IOSTANDARD LVCMOS33} [get_ports eth_rst_n]
set_property -dict {PACKAGE_PIN G11 IOSTANDARD LVCMOS33} [get_ports eth_mdc]
# MDIO (H11) is not used: the PHY runs on its straps. MDC is driven low.
# The PHY's receive clock E13 (clock capable). 8 ns is the gigabit clock; the same logic serves 100M (40 ns) and 10M, so the stricter period is
# the one constrained: timing that meets it meets the slower speeds.
create_clock -name eth_rx_clk -period 8.000 [get_ports eth_rx_clk]
