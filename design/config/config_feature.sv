// ----------------------------------------------------------------------
//  Feature define
// ----------------------------------------------------------------------
`define SOPHON_EXT_INST
`define SOPHON_EXT_DATA
`define SOPHON_EXT_ACCESS
`define SOPHON_CLIC
`define SOPHON_EEI
                                
// `define SOPHON_SOFT_RST

// SubFeature
`ifdef SOPHON_EEI
    `define SOPHON_EEI_SREG
    `define SOPHON_EEI_GPIO
`endif
                                                            
