`define FPGA
`define TANG_NANO_9K
`undef GOWIN_RESOURCE_ANALYSIS
`undef PROBE

`undef CORE_COMPLEX_AXI_SLV
`undef CORE_COMPLEX_AXI_MST

`ifdef TANG_NANO_9K
    `undef SOPHON_ITCM_SIZE
    `undef SOPHON_DTCM_SIZE
    `define SOPHON_ITCM_SIZE 32'h0000_2000
    `define SOPHON_DTCM_SIZE 32'h0000_2000
`endif

`ifdef GOWIN_RESOURCE_ANALYSIS
    `undef SOPHON_ITCM_SIZE
    `undef SOPHON_DTCM_SIZE
    `define SOPHON_ITCM_SIZE 32'h0001_0000
    `define SOPHON_DTCM_SIZE 32'h0001_0000
`endif

`undef SOPHON_RVDEBUG
`undef SOPHON_EEI
`undef SOPHON_EEI_SREG
`undef SOPHON_EEI_GPIO
//`define SOPHON_RVE

`define SOPHON_ZICSR
`define SOPHON_CLINT
//`define SOPHON_CLIC
                                
// SubFeature
`ifdef SOPHON_EEI
    `define SOPHON_EEI_NOALIGN
    `define SOPHON_EEI_SREG
    `define SOPHON_EEI_GPIO
    `define EEI_RS_MAX 10
    `define EEI_RD_MAX 10
`endif

// SubSubFeature
`ifdef SOPHON_EEI_GPIO
    `define FGPIO_NUM 24
`endif
