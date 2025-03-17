// ----------------------------------------------------------------------
//  Feature define
// ----------------------------------------------------------------------
`define SOPHON_EXT_INST
`define SOPHON_EXT_DATA
`define SOPHON_EXT_ACCESS

`define SOPHON_RVDEBUG
`define SOPHON_CLIC
`define SOPHON_EEI
//`define SOPHON_RVE

`define SOPHON_CLINT
`define SOPHON_ZICSR
                                
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
                                                            
