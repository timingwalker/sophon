//`define ARTY_A7_35T
//`define ARTY_A7_100T
`define GENESYS2
//`define TANG_NANO_9K

//`define PROBE

`undef CORE_COMPLEX_AXI_SLV
`undef CORE_COMPLEX_AXI_MST
`undef SOPHON_RVDEBUG
    
`ifdef TANG_NANO_9K
    `undef SOPHON_ITCM_SIZE
    `undef SOPHON_DTCM_SIZE
    `define SOPHON_ITCM_SIZE 32'h0000_2000
    `define SOPHON_DTCM_SIZE 32'h0000_2000
`endif

//`undef SOPHON_EEI
//`undef SOPHON_EEI_SREG
//`undef SOPHON_EEI_GPIO

