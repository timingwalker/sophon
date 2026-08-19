// ----------------------------------------------------------------------
//  Feature define
// ----------------------------------------------------------------------

`define CORE_COMPLEX_AXI_MST
`define CORE_COMPLEX_AXI_SLV

`define BOOT_ADDR BROM_BASE
`define SOPHON_ITCM_SIZE 32'h0001_0000
`define SOPHON_DTCM_SIZE 32'h0001_0000

//`define SOPHON_RVDEBUG
`define SOPHON_EEI
//`define SOPHON_RVE

`define SOPHON_ZICSR
`define SOPHON_CLINT
`define SOPHON_CLIC
                                
// SubFeature
`ifdef SOPHON_EEI
    `define SOPHON_EEI_SREG
    `define SOPHON_EEI_GPIO
    `define SOPHON_EEI_VSM
`endif

// SubSubFeature
`ifdef SOPHON_EEI_GPIO
    `define FGPIO_NUM 24
`endif
