
`ifndef CONFIG_SV
`define CONFIG_SV

// always define ASIC when we do a synthesis run
`ifdef SYNTHESIS
`define ASIC
`endif

`endif
