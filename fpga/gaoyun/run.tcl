set top_module SOPHON_FPGA_TOP
set script_dir [file dirname [file normalize [info script]]]
set repo_dir [file normalize [file join $script_dir ../..]]
set config_file [file join $script_dir fpga_config.sv]

set fpga_board ""
set part_number ""
set device_version ""
set cst ""
set sdc ""

proc regex_search_file {filename pattern} {
    set fp [open $filename r]
    set matches [list]
    while {[gets $fp line] >= 0} {
        if {[regexp $pattern $line]} {
            lappend matches $line
        }
    }
    close $fp
    return $matches
}

proc replace_in_file {file_path from_text to_text} {
    set fp [open $file_path r]
    set data [read $fp]
    close $fp

    set data [string map [list $from_text $to_text] $data]

    set fp [open $file_path w]
    puts -nonewline $fp $data
    close $fp
}

proc set_include_paths {file_path paths} {
    set include_text "\"IncludePath\" : \[\n"
    set path_count [llength $paths]
    for {set i 0} {$i < $path_count} {incr i} {
        set comma ""
        if {$i < $path_count - 1} {
            set comma ","
        }
        append include_text "  \"[lindex $paths $i]\"$comma\n"
    }
    append include_text " \],"

    replace_in_file $file_path "\"IncludePath\" : \[\n\n \]," $include_text
}

proc write_gowin_config {file_path} {
    set fp [open $file_path w]
    puts $fp "`include \"../../design/config/config_feature.sv\""
    puts $fp "`include \"fpga_config.sv\""
    puts $fp "`include \"../../design/config/config_others.sv\""
    close $fp
}

proc move_filelist_entry_first {file_path pattern} {
    set fp [open $file_path r]
    set data [read $fp]
    close $fp

    set lines [split $data "\n"]
    set selected ""
    set filtered [list]
    foreach line $lines {
        if {$selected eq "" && [string first $pattern $line] >= 0} {
            set selected $line
        } else {
            lappend filtered $line
        }
    }

    if {$selected eq ""} {
        puts "ERROR: Could not find $pattern in $file_path"
        exit 1
    }

    set output [list]
    set inserted 0
    foreach line $filtered {
        lappend output $line
        if {!$inserted && [string first "<FileList>" $line] >= 0} {
            lappend output $selected
            set inserted 1
        }
    }

    set fp [open $file_path w]
    puts -nonewline $fp [join $output "\n"]
    close $fp
}

set pattern {^`define.*TANG_NANO_9K}
set result [regex_search_file $config_file $pattern]
if {[string length $result] > 0} {
    set fpga_board TANG_NANO_9K
    set part_number GW1NR-LV9QN88PC6/I5
    set device_version C
    set cst tang_nano_9k.cst
    set sdc tang_nano_9k.sdc
}

if {[string length $fpga_board] == 0} {
    puts "ERROR: You should define the Gowin FPGA board used in fpga_config.sv!"
    exit 1
}

set date [clock format [clock seconds] -format "%Y%m%d"]
set target "sophon_$fpga_board"
append target "_" $date
set output_root [file join $script_dir output]
set output_dir [file join $output_root $target]
set project_name $target

puts "####################################"
puts "    fpga_board    : $fpga_board"
puts "    part_number   : $part_number"
puts "    device_version: $device_version"
puts "    cst           : $cst"
puts "    sdc           : $sdc"
puts "    target        : $target"
puts "    output_dir    : $output_dir"
puts "####################################"

file mkdir $output_root
create_project -name $project_name -dir $output_root -pn $part_number -device_version $device_version -force
write_gowin_config \
    [file join $script_dir 0_gowin_config.sv]
source [file join $script_dir read_design.tcl]
if {[string length $cst] > 0} {
    add_file [file join $script_dir $cst]
}
if {[string length $sdc] > 0} {
    add_file [file join $script_dir $sdc]
}
move_filelist_entry_first \
    [file join [pwd] "${project_name}.gprj"] \
    "0_gowin_config.sv"
set_option -top_module $top_module

set process_config [file join [pwd] impl "${project_name}_process_config.json"]
replace_in_file $process_config \
    "\"Verilog_Standard\" : \"Vlg_Std_2001\"" \
    "\"Verilog_Standard\" : \"Vlg_Std_Sysv2017\""
set_include_paths $process_config [list \
    [file join $repo_dir design/open-source/axi/include] \
    [file join $repo_dir design/open-source/common_cells/include] \
    [file join $repo_dir design/open-source/reqrsp_interface/include] \
]

file copy -force $process_config [file join [pwd] impl project_process_config.json]

set fp [open [file join $script_dir build_config.tcl] w]
puts $fp "set project_name \"$project_name\""
puts $fp "set project_dir \"[pwd]\""
close $fp
