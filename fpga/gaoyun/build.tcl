set project_name sophon_gaoyun_top
set script_dir [file dirname [file normalize [info script]]]

open_project [file join $script_dir $project_name "${project_name}.gprj"]
run all
