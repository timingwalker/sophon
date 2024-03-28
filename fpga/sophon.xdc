
# Genesys 2 has a quad SPI flash
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]

## 
set_property -dict {PACKAGE_PIN AD27 IOSTANDARD LVCMOS33} [get_ports JTAG_TCK]
set_property -dict {PACKAGE_PIN W29 IOSTANDARD LVCMOS33} [get_ports JTAG_TMS]
set_property -dict {PACKAGE_PIN W27 IOSTANDARD LVCMOS33} [get_ports JTAG_TDI]
set_property -dict {PACKAGE_PIN W28 IOSTANDARD LVCMOS33} [get_ports JTAG_TDO]

set_property -dict {PACKAGE_PIN Y23 IOSTANDARD LVCMOS33} [get_ports UART_TX]
set_property -dict {PACKAGE_PIN Y20 IOSTANDARD LVCMOS33} [get_ports UART_RX]

set_property -dict {PACKAGE_PIN T28 IOSTANDARD LVCMOS33} [get_ports LED0]
set_property -dict {PACKAGE_PIN V19 IOSTANDARD LVCMOS33} [get_ports LED1]
set_property -dict {PACKAGE_PIN U30 IOSTANDARD LVCMOS33} [get_ports LED2]
set_property -dict {PACKAGE_PIN U29 IOSTANDARD LVCMOS33} [get_ports LED3]
set_property -dict {PACKAGE_PIN V20 IOSTANDARD LVCMOS33} [get_ports LED4]
set_property -dict {PACKAGE_PIN V26 IOSTANDARD LVCMOS33} [get_ports LED5]
set_property -dict {PACKAGE_PIN W24 IOSTANDARD LVCMOS33} [get_ports LED6]

set_property -dict {PACKAGE_PIN AD11 IOSTANDARD LVDS} [get_ports SYSCLK_N]
set_property -dict {PACKAGE_PIN AD12 IOSTANDARD LVDS} [get_ports SYSCLK_P]
set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVCMOS33} [get_ports RESETN]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets JTAG_TCK_IBUF]


## creat_generated_clock -name sys_clock -source [get_pins i_clk_wiz/clk_in1_p] -divide_by 8 -add -master_clock sysclk_p [get_pins i_clk_wiz/clk_out1]


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

