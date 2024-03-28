// ----------------------------------------------------------------------
//             Copyright 2024 PENG CHENG LABORATORY
// ----------------------------------------------------------------------
// 
// Author        : huangzhe
// Create Date   : 2024-01-09 10:21:26
// Last Modified : 2024-03-27 09:29:22
// Description   : 
// 
// ----------------------------------------------------------------------

module SOPHON_FPGA_TOP(

	input SYSCLK_P,
	input SYSCLK_N,
	input RESETN,

    input  UART_RX,
    output UART_TX,

    input  JTAG_TCK,
    input  JTAG_TMS,
    input  JTAG_TDI,
    inout  JTAG_TDO,
    output LED0,
    output LED1,
    output LED2,
    output LED3,
    output LED4,
    output LED5,
    output LED6

);


    wire clock;
    wire sample_clock ;
    wire rstn;
    wire pll_locked;
    wire tdo;
    wire tdo_oe;
`ifdef PROBE
    wire [149:0] probe;
`endif


    `ifdef SOPHON_EXT_ACCESS
        CC_ITF_PKG::xbar_slv_port_d64_req_t   axi_slv_port_req;
        CC_ITF_PKG::xbar_slv_port_d64_resps_t axi_slv_port_rsp;
        assign axi_slv_port_req.aw_valid = 1'b0;
        assign axi_slv_port_req.ar_valid = 1'b0;
        assign axi_slv_port_req.w_valid  = 1'b0;
        assign axi_slv_port_req.b_ready  = 1'b1;
        assign axi_slv_port_req.r_ready  = 1'b1;
    `endif
    `ifdef SOPHON_EXT_INST_DATA
        CC_ITF_PKG::xbar_mst_port_d64_req_t   axi_mst_port_req;
        CC_ITF_PKG::xbar_mst_port_d64_resps_t axi_mst_port_rsp;
        assign axi_mst_port_rsp.aw_ready = 1'b1;
        assign axi_mst_port_rsp.ar_ready = 1'b1;
        assign axi_mst_port_rsp.w_ready  = 1'b1;
        assign axi_mst_port_rsp.b_valid  = 1'b0;
        assign axi_mst_port_rsp.r_valid  = 1'b0;
    `endif


    CORE_COMPLEX U_CORE_COMPLEX(
         .clk_i              ( clock            ) 
         ,.rst_ni            ( rstn             ) 
         ,.hart_id_i         ( '0               ) 
         ,.irq_mei_i         ( '0               ) 
         ,.irq_mti_i         ( '0               ) 
         ,.irq_msi_i         ( '0               ) 
         ,.tck_i             ( JTAG_TCK         ) 
         ,.tms_i             ( JTAG_TMS         ) 
         ,.trst_n_i          ( rstn             ) 
         ,.tdi_i             ( JTAG_TDI         ) 
         ,.tdo_o             ( tdo              ) 
         ,.tdo_oe_o          ( tdo_oe           ) 
         ,.uart_rx_i         ( UART_RX          ) 
         ,.uart_tx_o         ( UART_TX          ) 
    `ifdef SOPHON_EXT_ACCESS
        ,.axi_slv_port_req_i ( axi_slv_port_req )
        ,.axi_slv_port_rsp_o ( axi_slv_port_rsp )
    `endif
    `ifdef SOPHON_EXT_INST_DATA
        ,.axi_mst_port_req_o ( axi_mst_port_req )
        ,.axi_mst_port_rsp_i ( axi_mst_port_rsp )
    `endif
     `ifdef PROBE
        ,.probe_o            (probe             )
     `endif
    );

    assign LED0 = RESETN ;
    assign LED1 = pll_locked;
    assign LED2 = rstn;
    assign LED3 = clock;
    assign LED4 = 1'b0;
    assign LED5 = 1'b0;
    assign LED6 = 1'b1;


    clk_wiz_0 i_clk_wiz(
    	.clk_in1_p ( SYSCLK_P     ) ,
    	.clk_in1_n ( SYSCLK_N     ) ,
    	.reset     ( ~RESETN      ) ,
    	.locked    ( pll_locked   ) ,
    	.clk_out1  ( clock        ) ,
    	.clk_out2  ( sample_clock ) 
    );

    RST_SYNC i_rstgen_main (
        .clk_i       ( clock      ) ,
        .rst_ni      ( pll_locked ) ,
        .rstn_sync_o ( rstn       )
    );

    `ifdef PROBE

        // from sophon core
        wire [31:0] pc               = probe[31:0 ];
        wire [31:0] inst_data_1d     = probe[63:32];
        wire        rst_dly_neg_1d   = probe[64];
        wire        if_vld           = probe[65];
        wire        retire_vld       = probe[66];
        wire        ex_vld           = probe[67];
        wire        debug_mode       = probe[68];
        wire        is_dret          = probe[69];
        wire        inst_data_1d_vld = probe[70];

        // from sophon top
        wire [31:0] iram_addr_offset  = probe[111:80] ;
        wire [31:0] iram_wdata        = probe[143:112];
        wire        iram_req          = probe[144]    ;
        wire        iram_we           = probe[145]    ;
        wire        iram_be           = probe[146]    ;

        ila_0 u_ila_sophon (
        	.clk    ( sample_clock     ) ,
        	.probe0 ( pc               ) ,
        	.probe1 ( inst_data_1d     ) ,
        	.probe2 ( inst_data_1d_vld ) ,
        	.probe3 ( if_vld           ) ,
        	.probe4 ( retire_vld       ) ,
        	.probe5 ( ex_vld           ) ,
        	.probe6 ( debug_mode       ) 
        );

        ila_0 u_ila_top (
        	.clk    ( sample_clock     ) ,
        	.probe0 ( iram_addr_offset ) ,
        	.probe1 ( iram_wdata       ) ,
        	.probe2 ( iram_req         ) ,
        	.probe3 ( iram_we          ) ,
        	.probe4 ( iram_be          ) ,
        	.probe5 ( is_dret          ) ,
        	.probe6 ( 1'b0             ) 
        );

    `endif

    IOBUF #( 
        .DRIVE        ( 12        ) ,
        .IBUF_LOW_PWR ( "TRUE"    ) ,
        .IOSTANDARD   ( "DEFAULT" ) ,
        .SLEW         ( "SLOW"    ) 
    ) IOBUF_TDO (
        .O  (          ) ,
        .IO ( JTAG_TDO ) ,
        .I  ( tdo      ) ,
        .T  ( ~tdo_oe  ) 
    );

endmodule

