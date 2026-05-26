source "../../utils.tcl"

set part_number ""

set pattern {^`define.*ARTY_A7_35T}
set result [regex_search_file "../../fpga_config.sv" $pattern]
if {[string length $result] > 0} {
    set part_number "xc7a35ticsg324-1L"
}

set pattern {^`define.*ARTY_A7_100T}
set result [regex_search_file "../../fpga_config.sv" $pattern]
if {[string length $result] > 0} {
    set part_number "xc7a100tcsg324-1"
}

set pattern {^`define.*GENESYS2}
set result [regex_search_file "../../fpga_config.sv" $pattern]
if {[string length $result] > 0} {
    set part_number "xc7k325tffg900-2"
}

set partNumber $part_number

set ipName ila_0

create_project $ipName . -force -part $partNumber

create_ip -name ila -vendor xilinx.com -library ip -module_name $ipName


if {[string equal -nocase $partNumber "xc7a35ticsg324-1L"]} {
    set_property -dict [list  CONFIG.C_NUM_OF_PROBES {12} \
                              CONFIG.C_PROBE0_WIDTH {32}  \
                              CONFIG.C_DATA_DEPTH {1024}  \
                              CONFIG.C_INPUT_PIPE_STAGES {1} \
                        ] [get_ips $ipName]
}

if {[string equal -nocase $partNumber "xc7a100tcsg324-1"]} {
    set_property -dict [list  CONFIG.C_NUM_OF_PROBES {12} \
                              CONFIG.C_PROBE0_WIDTH {32}  \
                              CONFIG.C_DATA_DEPTH {1024}  \
                              CONFIG.C_INPUT_PIPE_STAGES {1} \
                        ] [get_ips $ipName]
}

if {[string equal -nocase $partNumber "xc7k325tffg900-2"]} {
    set_property -dict [list  CONFIG.C_NUM_OF_PROBES {12} \
                              CONFIG.C_PROBE0_WIDTH {32}  \
                              CONFIG.C_PROBE1_WIDTH {32}  \
                              CONFIG.C_PROBE2_WIDTH {32}  \
                              CONFIG.C_PROBE3_WIDTH {32}  \
                              CONFIG.C_DATA_DEPTH {65536}  \
                              CONFIG.C_INPUT_PIPE_STAGES {1} \
                        ] [get_ips $ipName]
}

generate_target {instantiation_template} [get_files ./$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
generate_target all [get_files  ./$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
create_ip_run [get_files -of_objects [get_fileset sources_1] ./$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
launch_run -jobs 8 ${ipName}_synth_1
wait_on_run ${ipName}_synth_1
