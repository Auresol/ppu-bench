# The shell's own constraints (frame-spec.yaml shell: xdc:), read after synthesis (a get_pins needs the netlist).

# The chip's clock clk_pin is the MMCM's CLKOUT0 (the clock is derived from the oscillator's create_clock in ku5p.xdc), so no create_clock here.

# The chip clock (50 MHz), the Ethernet clocks (125 MHz and its 90 degree copy, one domain) and the PHY's receive clock are unrelated as far as
# timing goes: the crossings between them are the asynchronous FIFOs of the link core and of the MAC, which synchronise their Gray pointers.
set_clock_groups -asynchronous \
    -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *u_mmcm/CLKOUT0}]] \
    -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *u_mmcm/CLKOUT1}]] [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *u_mmcm/CLKOUT2}]] \
    -group [get_clocks eth_rx_clk]
