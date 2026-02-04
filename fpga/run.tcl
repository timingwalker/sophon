source "utils.tcl"

set top_module "SOPHON_FPGA_TOP"

set fpga_board ""
set part_number ""
set xdc ""

set pattern {^`define.*ARTY_A7_35T}
set result [regex_search_file "fpga_config.sv" $pattern]
if {[string length $result] > 0} {
    set fpga_board "ARTY_A7_35T"
    set part_number "xc7a35ticsg324-1L"
    set xdc "sophon_arty_a7.xdc"
}

set pattern {^`define.*GENESYS2}
set result [regex_search_file "fpga_config.sv" $pattern]
if {[string length $result] > 0} {
    set fpga_board "GENESYS2"
    set part_number "xc7k325tffg900-2"
    set xdc "sophon_genesys2.xdc"
}

set date [clock format [clock seconds] -format "%Y_%m_%d"]
set target "sophon_$fpga_board"
append target "_" $date
set outputDir ./output/$target

if {[string length $fpga_board] == 0} {
    puts "ERROR: You should define the fpga board used in fpga_config.sv!"
    exit 0
} else {
    puts "####################################"
    puts "    fpga_board : $fpga_board"
    puts "    part_number: $part_number"
    puts "    xdc        : $xdc"
    puts "    target     : $target"
    puts "    outputDir  : $outputDir"
    puts "####################################"
}

file mkdir $outputDir

source read_design.tcl

read_xdc ./$xdc
#read_xdc ./sophon_arty_a7.xdc

read_ip {\
"ip/clk_gen/clk_wiz_0.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xci"\
"ip/ila/ila_0.srcs/sources_1/ip/ila_0/ila_0.xci"\
}

set_part $part_number
#set_part xc7k325tffg900-2 
#set_part xc7a35ticsg324-1L



## run synthesis
set_param general.maxThreads 32

synth_design -flatten_hierarchy none -top $top_module -part $part_number
# synth_design -top SOPHON_FPGA_TOP -part xc7k325tffg900-2 

write_checkpoint -force $outputDir/post_synth.dcp
report_timing_summary -file $outputDir/post_synth_timing_summary.rpt
report_utilization -file $outputDir/post_synth_util.rpt


# run logic optimization, placement and physical logic optimization, 
opt_design

place_design
report_clock_utilization -file $outputDir/clock_util.rpt

phys_opt_design
# Optionally run optimization if there are timing violations after placement
#
# if {[get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]] < 
# 0} {
#     puts "Found setup timing violations => running physical optimization"
#   phys_opt_design
# }

write_checkpoint -force $outputDir/post_place.dcp
report_utilization -hierarchical -file $outputDir/post_place_util.rpt
report_timing_summary -file $outputDir/post_place_timing_summary.rpt

# run the router
# report the routing status, report timing, power, and DRC, and finally save the Verilog netlist.
route_design

write_checkpoint -force $outputDir/post_route.dcp
report_route_status -file $outputDir/post_route_status.rpt
report_timing_summary -file $outputDir/post_route_timing_summary.rpt
report_power -file $outputDir/post_route_power.rpt
report_drc -file $outputDir/post_imp_drc.rpt

write_verilog -force $outputDir/sophon_impl_netlist.v -mode timesim -sdf_anno true

# generate a bitstream
write_bitstream -force $outputDir/$target.bit
write_debug_probes $outputDir/$target.ltx

write_cfgmem -format mcs -interface SPIx4 -size 16 -loadbit "up 0x0 $outputDir/$target.bit" -file "$outputDir/$target.mcs" -force

start_gui
