module GOWIN_RPLL_10M (
    input  logic clkin,
    input  logic reset,
    output logic clkout,
    output logic lock
);

    logic clkout_base;
    logic clkoutp;
    logic clkoutd3;
    logic gw_gnd;

    assign gw_gnd = 1'b0;

    rPLL u_rpll (
        .CLKOUT  ( clkout_base ),
        .LOCK    ( lock    ),
        .CLKOUTP ( clkoutp ),
        .CLKOUTD ( clkout ),
        .CLKOUTD3( clkoutd3),
        .RESET   ( reset   ),
        .RESET_P ( gw_gnd  ),
        .CLKIN   ( clkin   ),
        .CLKFB   ( gw_gnd  ),
        .FBDSEL  ( 6'b0    ),
        .IDSEL   ( 6'b0    ),
        .ODSEL   ( 6'b0    ),
        .PSDA    ( 4'b0    ),
        .DUTYDA  ( 4'b0    ),
        .FDLY    ( 4'b0    )
    );

    defparam u_rpll.FCLKIN = "27";
    defparam u_rpll.DYN_IDIV_SEL = "false";
    defparam u_rpll.IDIV_SEL = 2;
    defparam u_rpll.DYN_FBDIV_SEL = "false";
    defparam u_rpll.FBDIV_SEL = 19;
    defparam u_rpll.DYN_ODIV_SEL = "false";
    defparam u_rpll.ODIV_SEL = 4;
    defparam u_rpll.PSDA_SEL = "0000";
    defparam u_rpll.DYN_DA_EN = "false";
    defparam u_rpll.DUTYDA_SEL = "1000";
    defparam u_rpll.CLKOUT_FT_DIR = 1'b1;
    defparam u_rpll.CLKOUTP_FT_DIR = 1'b1;
    defparam u_rpll.CLKOUT_DLY_STEP = 0;
    defparam u_rpll.CLKOUTP_DLY_STEP = 0;
    defparam u_rpll.CLKFB_SEL = "internal";
    defparam u_rpll.CLKOUT_BYPASS = "false";
    defparam u_rpll.CLKOUTP_BYPASS = "false";
    defparam u_rpll.CLKOUTD_BYPASS = "false";
    defparam u_rpll.DYN_SDIV_SEL = 18;
    defparam u_rpll.CLKOUTD_SRC = "CLKOUT";
    defparam u_rpll.CLKOUTD3_SRC = "CLKOUT";
    defparam u_rpll.DEVICE = "GW1NR-9C";

endmodule
