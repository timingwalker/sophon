
# STEP#1: define the output directory area.
set outputDir ./output 
file mkdir $outputDir


## STEP#2: setup design sources and constraints
source read_design.tcl
read_xdc ./sophon.xdc

set_part xc7k325tffg900-2 
read_ip {\
"ip/clk_gen/clk_wiz_0.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xci"\
"ip/ila/ila_0.srcs/sources_1/ip/ila_0/ila_0.xci"\
}


## STEP#3: run synthesis, write design checkpoint, report timing, 
## and utilization estimates

set_param general.maxThreads 32

synth_design -top SOPHON_FPGA_TOP -part xc7k325tffg900-2 
write_checkpoint -force $outputDir/post_synth.dcp
report_timing_summary -file $outputDir/post_synth_timing_summary.rpt
report_utilization -file $outputDir/post_synth_util.rpt


# STEP#4: run logic optimization, placement and physical logic optimization, 
# write design checkpoint, report utilization and timing estimates
opt_design
place_design
report_clock_utilization -file $outputDir/clock_util.rpt
# Optionally run optimization if there are timing violations after placement
if {[get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]] < 
0} {
    puts "Found setup timing violations => running physical optimization"
    phys_opt_design
}
write_checkpoint -force $outputDir/post_place.dcp
report_utilization -hierarchical -file $outputDir/post_place_util.rpt
report_timing_summary -file $outputDir/post_place_timing_summary.rpt


# STEP#5: run the router, write the post-route design checkpoint, report the routing
# status, report timing, power, and DRC, and finally save the Verilog netlist.
route_design
write_checkpoint -force $outputDir/post_route.dcp
report_route_status -file $outputDir/post_route_status.rpt
report_timing_summary -file $outputDir/post_route_timing_summary.rpt
report_power -file $outputDir/post_route_power.rpt
report_drc -file $outputDir/post_imp_drc.rpt
write_verilog -force $outputDir/sophon_impl_netlist.v -mode timesim -sdf_anno true


# STEP#6: generate a bitstream
write_bitstream -force $outputDir/sophon.bit
write_debug_probes $outputDir/sophon.ltx

# start_gui
