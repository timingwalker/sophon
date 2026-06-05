create_clock -name sys_clk -period 37.037 -waveform {0 18.519} [get_ports {sys_clk}]
create_clock -name core_clk -period 100.000 -waveform {0 50.000} [get_nets {core_clk}]
