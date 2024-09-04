// ----------------------------------------------------------------------
//  Feature define
// ----------------------------------------------------------------------
`define SOPHON_EXT_INST
`define SOPHON_EXT_DATA
`define SOPHON_EXT_ACCESS
`define SOPHON_CLIC
`define SOPHON_EEI
                                
// SubFeature
`ifdef SOPHON_EEI
    `define SOPHON_EEI_SREG
    `define SOPHON_EEI_GPIO
    `define EEI_RS_MAX 4
    `define EEI_RD_MAX 4
`endif

// SubSubFeature
`ifdef SOPHON_EEI_GPIO
    `define FGPIO_NUM 4
`endif
                                                            
