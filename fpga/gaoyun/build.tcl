set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir build_config.tcl]

open_project [file join $project_dir "${project_name}.gprj"]
run all
