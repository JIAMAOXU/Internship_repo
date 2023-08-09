create_clock -period 20.000 -name sys_clk_pin -waveform {0.000 10.000} -add [get_ports clk]
set_property -dict {PACKAGE_PIN V4 IOSTANDARD LVCMOS12} [get_ports clk]

set_property -dict {PACKAGE_PIN E21 IOSTANDARD LVCMOS12} [get_ports {leds[0]}]
set_property -dict {PACKAGE_PIN D21 IOSTANDARD LVCMOS12} [get_ports {leds[1]}]
set_property -dict {PACKAGE_PIN E22 IOSTANDARD LVCMOS12} [get_ports {leds[2]}]
set_property -dict {PACKAGE_PIN D22 IOSTANDARD LVCMOS12} [get_ports {leds[3]}]





set_property PACKAGE_PIN R14 [get_ports rstn]
set_property IOSTANDARD LVCMOS12 [get_ports rstn]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_IBUF_BUFG]
