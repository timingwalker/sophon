// ----------------------------------------------------------------------
//  Feature define
// ----------------------------------------------------------------------

`define CORE_COMPLEX_AXI_MST
`define CORE_COMPLEX_AXI_SLV

`define SOPHON_EXT_ACCESS
//`define SOPHON_EXT_INST
//`define SOPHON_EXT_DATA

`define SOPHON_RVDEBUG
`define SOPHON_EEI
//`define SOPHON_RVE

`define SOPHON_ZICSR
`define SOPHON_CLINT
//`define SOPHON_CLIC
                                
// SubFeature
`ifdef SOPHON_EEI
    `define SOPHON_EEI_SREG
    `define SOPHON_EEI_GPIO
    `define EEI_RS_MAX 10
    `define EEI_RD_MAX 10
`endif

// SubSubFeature
`ifdef SOPHON_EEI_GPIO
    `define FGPIO_NUM 32
`endif
                                                            
