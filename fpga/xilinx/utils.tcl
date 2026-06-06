
proc regex_search_file {filename pattern} {
    set fp [open $filename r]
    set line_number 0
    set matches [list]
    
    while {[gets $fp line] >= 0} {
        incr line_number
        if {[regexp $pattern $line]} {
            lappend matches [list $line_number $line]
            
            if {[regexp $pattern $line matched]} {
                puts "match: $matched : ${line_number}"
            }
        }
    }
    
    close $fp
    return $matches
}
