`ifdef SYNTHESIS
    //`define ASIC
`endif

// -----------------------------------
// Do NOT CHANGE
// -----------------------------------

`ifdef SOPHON_CLINT
    `define SOPHON_EXT_DATA
`endif

`ifdef SOPHON_RVDEBUG
    `ifndef SOPHON_EXT_ACCESS
        `define SOPHON_EXT_ACCESS
    `endif
    `ifndef SOPHON_EXT_INST
        `define SOPHON_EXT_INST
    `endif
    `ifndef SOPHON_EXT_DATA
        `define SOPHON_EXT_DATA
    `endif
`endif

`ifdef BOOT_ADDR
    `ifndef SOPHON_EXT_ACCESS
        `define SOPHON_EXT_ACCESS
    `endif
    `ifndef SOPHON_EXT_DATA
        `define SOPHON_EXT_DATA
    `endif
`endif

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
        `define EEI_RS_MAX 10
    `endif
    `ifndef EEI_RD_MAX
        `define EEI_RD_MAX 10
    `endif
`endif

`ifdef SOPHON_EEI_GPIO
    // `ifndef SOPHON_EEI_RS_LOCK
    //     `define SOPHON_EEI_RS_LOCK
    // `endif
    `ifndef FGPIO_NUM
        `define FGPIO_NUM 24
    `endif
`endif


