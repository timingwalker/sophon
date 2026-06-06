`define FPGA
`define TANG_NANO_9K
`undef PROBE

`undef CORE_COMPLEX_AXI_SLV
`undef CORE_COMPLEX_AXI_MST

`ifdef TANG_NANO_9K
    `undef SOPHON_ITCM_SIZE
    `undef SOPHON_DTCM_SIZE
    `define SOPHON_ITCM_SIZE 32'h0000_2000
    `define SOPHON_DTCM_SIZE 32'h0000_2000
`endif

`undef SOPHON_RVDEBUG
`undef SOPHON_EEI
`undef SOPHON_EEI_SREG
`undef SOPHON_EEI_GPIO
//`define SOPHON_RVE

`define SOPHON_ZICSR
`define SOPHON_CLINT
                         