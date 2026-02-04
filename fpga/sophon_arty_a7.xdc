
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]

set_property -dict {PACKAGE_PIN C2 IOSTANDARD LVCMOS33} [get_ports RESETN]
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports SYSCLK]

set_property -dict {PACKAGE_PIN G13 IOSTANDARD LVCMOS33} [get_ports JTAG_TCK]
set_property -dict {PACKAGE_PIN B11 IOSTANDARD LVCMOS33} [get_ports JTAG_TMS]
set_property -dict {PACKAGE_PIN A11 IOSTANDARD LVCMOS33} [get_ports JTAG_TDI]
set_property -dict {PACKAGE_PIN D12 IOSTANDARD LVCMOS33} [get_ports JTAG_TDO]

set_property -dict {PACKAGE_PIN D10 IOSTANDARD LVCMOS33} [get_ports UART_TX]
set_property -dict {PACKAGE_PIN A9  IOSTANDARD LVCMOS33} [get_ports UART_RX]

set_property -dict {PACKAGE_PIN E15 IOSTANDARD LVCMOS33} [get_ports GPIO[0 ]]
set_property -dict {PACKAGE_PIN E16 IOSTANDARD LVCMOS33} [get_ports GPIO[1 ]]
set_property -dict {PACKAGE_PIN D15 IOSTANDARD LVCMOS33} [get_ports GPIO[2 ]]
set_property -dict {PACKAGE_PIN C15 IOSTANDARD LVCMOS33} [get_ports GPIO[3 ]]
set_property -dict {PACKAGE_PIN J17 IOSTANDARD LVCMOS33} [get_ports GPIO[4 ]]
set_property -dict {PACKAGE_PIN J18 IOSTANDARD LVCMOS33} [get_ports GPIO[5 ]]
set_property -dict {PACKAGE_PIN K15 IOSTANDARD LVCMOS33} [get_ports GPIO[6 ]]
set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS33} [get_ports GPIO[7 ]]

set_property -dict {PACKAGE_PIN U12 IOSTANDARD LVCMOS33} [get_ports GPIO[8 ]]
set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33} [get_ports GPIO[9 ]]
set_property -dict {PACKAGE_PIN V10 IOSTANDARD LVCMOS33} [get_ports GPIO[10]]
set_property -dict {PACKAGE_PIN V11 IOSTANDARD LVCMOS33} [get_ports GPIO[11]]
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports GPIO[12]]
set_property -dict {PACKAGE_PIN V14 IOSTANDARD LVCMOS33} [get_ports GPIO[13]]
set_property -dict {PACKAGE_PIN T13 IOSTANDARD LVCMOS33} [get_ports GPIO[14]]
set_property -dict {PACKAGE_PIN U13 IOSTANDARD LVCMOS33} [get_ports GPIO[15]]

set_property -dict {PACKAGE_PIN D4 IOSTANDARD LVCMOS33} [get_ports GPIO[16]]
set_property -dict {PACKAGE_PIN D3 IOSTANDARD LVCMOS33} [get_ports GPIO[17]]
set_property -dict {PACKAGE_PIN F4 IOSTANDARD LVCMOS33} [get_ports GPIO[18]]
set_property -dict {PACKAGE_PIN F3 IOSTANDARD LVCMOS33} [get_ports GPIO[19]]
set_property -dict {PACKAGE_PIN E2 IOSTANDARD LVCMOS33} [get_ports GPIO[20]]
set_property -dict {PACKAGE_PIN D2 IOSTANDARD LVCMOS33} [get_ports GPIO[21]]
set_property -dict {PACKAGE_PIN H2 IOSTANDARD LVCMOS33} [get_ports GPIO[22]]
set_property -dict {PACKAGE_PIN G2 IOSTANDARD LVCMOS33} [get_ports GPIO[23]]

set_property -dict {PACKAGE_PIN H5  IOSTANDARD LVCMOS33} [get_ports LED0]
set_property -dict {PACKAGE_PIN J5  IOSTANDARD LVCMOS33} [get_ports LED1]
set_property -dict {PACKAGE_PIN T9  IOSTANDARD LVCMOS33} [get_ports LED2]
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports LED3]
set_property -dict {PACKAGE_PIN G6  IOSTANDARD LVCMOS33} [get_ports LED4]
set_property -dict {PACKAGE_PIN F6  IOSTANDARD LVCMOS33} [get_ports LED5]
set_property -dict {PACKAGE_PIN E1  IOSTANDARD LVCMOS33} [get_ports LED6]


set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets JTAG_TCK_IBUF]


set CLK_JTAG 1000
set INPUT_DELAY_RATIO  0.2
set OUTPUT_DELAY_RATIO 0.2

create_clock -period $CLK_JTAG -name tck [get_ports JTAG_TCK]

set JTAG_I_PORT {JTAG_TDI JTAG_TMS}
set JTAG_O_PORT {JTAG_TDO}

set_input_delay -max  [expr $INPUT_DELAY_RATIO*$CLK_JTAG] -clock tck $JTAG_I_PORT 
set_input_delay -min 0 -clock tck $JTAG_I_PORT

set_output_delay -max [expr $OUTPUT_DELAY_RATIO*$CLK_JTAG] -clock tck $JTAG_O_PORT
set_output_delay -min 0 -clock tck $JTAG_O_PORT

