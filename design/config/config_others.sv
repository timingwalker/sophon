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

`ifdef SOPHON_EEI
    `ifndef EEI_RS_MAX
        `define EEI_RS_MAX 8
    `endif
    `ifndef EEI_RD_MAX
        `define EEI_RD_MAX 8
    `endif
`endif

`ifdef SOPHON_EEI_GPIO
    `ifndef SOPHON_EEI_RS_LOCK
        `define SOPHON_EEI_RS_LOCK
    `endif
    `ifndef FGPIO_NUM
        `define FGPIO_NUM 32
    `endif
`endif


