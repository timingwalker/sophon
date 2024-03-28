`ifdef SYNTHESIS
    //`define ASIC
`endif

// -----------------------------------
// Do NOT CHANGE
// -----------------------------------
`ifdef SOPHON_EXT_INST
    `define SOPHON_EXT_INST_DATA
`endif
`ifdef SOPHON_EXT_DATA
    `ifndef SOPHON_EXT_INST_DATA
        `define SOPHON_EXT_INST_DATA
    `endif
`endif

