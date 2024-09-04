// ----------------------------------------------------------------------
// Copyright 2024 TimingWalker
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ----------------------------------------------------------------------
// Create Date   : 2024-01-09 10:21:26
// Last Modified : 2024-08-05 11:36:49
// Description   : 
// ----------------------------------------------------------------------

module SOPHON_FPGA_TOP(

	input SYSCLK_P,
	input SYSCLK_N,
	input RESETN,

    input  UART_RX,
    output UART_TX,

    inout [`FGPIO_NUM-1:0] GPIO,

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
    wire [209:0] probe;
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
        // assign axi_mst_port_rsp.aw_ready = 1'b1;
        // assign axi_mst_port_rsp.ar_ready = 1'b1;
        // assign axi_mst_port_rsp.w_ready  = 1'b1;
        // assign axi_mst_port_rsp.b_valid  = 1'b0;
        // assign axi_mst_port_rsp.r_valid  = 1'b0;
    `endif

    `ifdef SOPHON_EEI_GPIO
        logic [`FGPIO_NUM-1:0] gpio_dir;
        logic [`FGPIO_NUM-1:0] gpio_in_val;
        logic [`FGPIO_NUM-1:0] gpio_out_val;

        genvar t;
        generate
            for (t=0; t<`FGPIO_NUM; t=t+1) begin:gen_gpio
                assign GPIO[t] = gpio_dir[t] ? gpio_out_val[t] : 1'bz;
                assign gpio_in_val[t] = GPIO[t];
            end
        endgenerate
    `else
        genvar t;
        generate
            for (t=0; t<`FGPIO_NUM; t=t+1) begin:gen_gpio_empty
                assign GPIO[t] = 1'b0;
            end
        endgenerate
    `endif

    CORE_COMPLEX U_CORE_COMPLEX(
         .clk_i              ( clock            ) 
         ,.rst_ni            ( rstn             ) 
         ,.hart_id_i         ( '0               ) 
         ,.irq_mei_i         ( '0               ) 
         ,.tck_i             ( JTAG_TCK         ) 
         ,.tms_i             ( JTAG_TMS         ) 
         ,.trst_n_i          ( rstn             ) 
         ,.tdi_i             ( JTAG_TDI         ) 
         ,.tdo_o             ( tdo              ) 
         ,.tdo_oe_o          ( tdo_oe           ) 
         ,.uart_rx_i         ( UART_RX          ) 
         ,.uart_tx_o         ( UART_TX          ) 
    `ifdef SOPHON_EEI_GPIO
         ,.gpio_dir_o        ( gpio_dir         ) 
         ,.gpio_in_val_i     ( gpio_in_val      ) 
         ,.gpio_out_val_o    ( gpio_out_val     ) 
    `endif
    `ifdef SOPHON_EXT_ACCESS
        ,.axi_slv_port_req_i ( axi_slv_port_req )
        ,.axi_slv_port_rsp_o ( axi_slv_port_rsp )
    `endif
    `ifdef SOPHON_EXT_INST_DATA
        ,.axi_mst_port_req_o ( axi_mst_port_req )
        ,.axi_mst_port_rsp_i ( axi_mst_port_rsp )
    `endif
     `ifdef PROBE
        ,.probe_o            ( probe            )
     `endif
    );

    // ----------------------------------------------------------------------
    //  Prepare External Memory if it is enabled
    // ----------------------------------------------------------------------
    `ifdef SOPHON_EXT_INST_DATA

        CC_ITF_PKG::axi_mst_side_d32_req_t    axi_mst_32b_req;
        CC_ITF_PKG::axi_mst_side_d32_resps_t axi_mst_32b_rsp;

        axi_dw_converter #(
            .AxiMaxReads         ( 4                                     ) ,
            .AxiSlvPortDataWidth ( CC_ITF_PKG::XBAR_DATA_WIDTH           ) ,
            .AxiMstPortDataWidth ( 32                                    ) ,
            .AxiAddrWidth        ( CC_ITF_PKG::XBAR_ADDR_WIDTH           ) ,
            .AxiIdWidth          ( CC_ITF_PKG::XBAR_MST_PORT_ID_WIDTH    ) ,
            .aw_chan_t           ( CC_ITF_PKG::xbar_mst_port_aw_t        ) ,
            .slv_w_chan_t        ( CC_ITF_PKG::xbar_w_chan_t             ) ,
            .b_chan_t            ( CC_ITF_PKG::xbar_mst_port_b_t         ) ,
            .ar_chan_t           ( CC_ITF_PKG::xbar_mst_port_ar_t        ) ,
            .slv_r_chan_t        ( CC_ITF_PKG::xbar_mst_port_r_t         ) ,
            .mst_w_chan_t        ( CC_ITF_PKG::axi_w_32b_t               ) ,
            .mst_r_chan_t        ( CC_ITF_PKG::axi_r_32b_t               ) ,
            .axi_mst_req_t       ( CC_ITF_PKG::axi_mst_side_d32_req_t    ) ,
            .axi_mst_resp_t      ( CC_ITF_PKG::axi_mst_side_d32_resps_t  ) ,
            .axi_slv_req_t       ( CC_ITF_PKG::xbar_mst_port_d64_req_t   ) ,
            .axi_slv_resp_t      ( CC_ITF_PKG::xbar_mst_port_d64_resps_t ) 
        ) i_axi_dw_converter (
            .clk_i         ( clock           ) ,
            .rst_ni        ( rstn            ) ,
            // slave port
            .slv_req_i     ( axi_mst_port_req ) ,
            .slv_resp_o    ( axi_mst_port_rsp ) ,
            // master port
            .mst_req_o     ( axi_mst_32b_req ) ,
            .mst_resp_i    ( axi_mst_32b_rsp ) 
        );

        CC_ITF_PKG::reqrsp_d32_req_t      reqresp_d32_req;
        CC_ITF_PKG::reqrsp_d32_resps_t    reqresp_d32_rsp;

        axi_to_reqrsp #(
            .axi_req_t    ( CC_ITF_PKG::axi_mst_side_d32_req_t   ) ,
            .axi_rsp_t    ( CC_ITF_PKG::axi_mst_side_d32_resps_t ) ,
            .AddrWidth    ( CC_ITF_PKG::REQRSP_ADDR_WIDTH        ) ,
            .DataWidth    ( CC_ITF_PKG::REQRSP_DATA_WIDTH        ) ,
            .IdWidth      ( CC_ITF_PKG::XBAR_MST_PORT_ID_WIDTH   ) ,
            .BufDepth     ( 1                                    ) ,
            .reqrsp_req_t ( CC_ITF_PKG::reqrsp_d32_req_t         ) ,
            .reqrsp_rsp_t ( CC_ITF_PKG::reqrsp_d32_resps_t       ) 
        ) u_axi_to_reqrsp  (
            .clk_i        ( clock           ) ,
            .rst_ni       ( rstn            ) ,
            .busy_o       (                 ) ,
            .axi_req_i    ( axi_mst_32b_req ) ,
            .axi_rsp_o    ( axi_mst_32b_rsp ) ,
            .reqrsp_req_o ( reqresp_d32_req ) ,
            .reqrsp_rsp_i ( reqresp_d32_rsp ) 
        );

        logic             axi_mem_req   ;
        logic             axi_mem_gnt   ;
        logic             axi_mem_cs    ;
        logic             axi_mem_we    ;
        logic [3:0]       axi_mem_be    ;
        logic [31:0]      axi_addr      ;
        logic [31:0]      axi_mem_wdata ;
        logic [31:0]      axi_mem_rdata ;

        REQRSP_TO_MEM #(
            .req_t      ( CC_ITF_PKG::reqrsp_d32_req_t   ) ,
            .resp_t     ( CC_ITF_PKG::reqrsp_d32_resps_t ) ,
            .DATA_WIDTH ( 32                             ) ,
            .ADDR_WIDTH ( 32                             ) 
        ) u_reqrsp_to_mem 
        (
            .clk_i     ( clock           ) ,
            .rst_ni    ( rstn            ) ,
            .req_i     ( reqresp_d32_req ) ,
            .resp_o    ( reqresp_d32_rsp ) ,
            .mem_req   ( axi_mem_req     ) ,
            .mem_gnt   ( 1'b1            ) , // AXI ports has highest priority
            .mem_cs    ( axi_mem_cs      ) ,
            .mem_we    ( axi_mem_we      ) ,
            .mem_be    ( axi_mem_be      ) ,
            .mem_addr  ( axi_addr        ) ,
            .mem_wdata ( axi_mem_wdata   ) ,
            .mem_rdata ( axi_mem_rdata   ) 
        );

        logic [31:0] axi_mem_addr_offset;
        assign axi_mem_addr_offset = axi_addr - 32'h1000;

        //32K*32bit=128K
        localparam int unsigned EXT_MEM_SIZE = 32'h0002_0000;
        TCM_WRAP 
        #(
            .DATA_WIDTH ( 32                    ) ,
            .DEPTH      ( EXT_MEM_SIZE / (32/8) )   // in DATA_WIDTH
        )
        U_EXT_MEM
        (
             .clk_i   ( clock                                         )
            ,.en_i    ( axi_mem_req                                   )
            ,.addr_i  ( axi_mem_addr_offset[$clog2(EXT_MEM_SIZE)-1:0] ) // in byte
            ,.wdata_i ( axi_mem_wdata                                 ) 
            ,.we_i    ( axi_mem_we                                    )
            ,.be_i    ( axi_mem_be                                    )
            ,.rdata_o ( axi_mem_rdata                                 )
        );

    `endif


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
        wire [31:0] pc               = probe[31:0]  ;
        wire [31:0] inst_data_1d     = probe[63:32] ;
        wire [31:0] dpc              = probe[95:64] ;
        wire [31:0] npc              = probe[127:96];

        wire        if_vld           = probe[128];
        wire        inst_data_1d_vld = probe[129];
        wire        retire_vld       = probe[130];
        wire        ex_vld           = probe[131];
        wire        debug_mode       = probe[132];
        wire        is_dret          = probe[133];
        wire        rvi_csr          = probe[134];
        wire        csr_wr           = probe[135];

        // from sophon top
        wire [31:0] iram_addr_offset  = probe[171:140];
        wire [31:0] iram_wdata        = probe[203:172];
        wire        iram_req          = probe[204]    ;
        wire        iram_we           = probe[205]    ;
        wire        iram_be           = probe[206]    ;

        ila_0 u_ila_sophon (
        	.clk     ( sample_clock     ) ,
        	.probe0  ( pc               ) ,
        	.probe1  ( inst_data_1d     ) ,
        	.probe2  ( dpc              ) ,
        	.probe3  ( npc              ) ,
        	.probe4  ( if_vld           ) ,
        	.probe5  ( inst_data_1d_vld ) ,
        	.probe6  ( retire_vld       ) ,
        	.probe7  ( ex_vld           ) ,
        	.probe8  ( debug_mode       ) ,
        	.probe9  ( is_dret          ) ,
        	.probe10 ( rvi_csr          ) ,
        	//.probe9  ( gpio_dir[1]      ) ,
        	//.probe10 ( gpio_out_val[1]  ) ,
        	.probe11 ( csr_wr           ) 
        );

        // ila_0 u_ila_top (
        // 	.clk     ( sample_clock     ) ,
        // 	.probe0  ( iram_addr_offset ) ,
        // 	.probe1  ( iram_wdata       ) ,
        // 	.probe2  ( 32'd0            ) ,
        // 	.probe3  ( 32'd0            ) ,
        // 	.probe4  ( iram_req         ) ,
        // 	.probe5  ( iram_we          ) ,
        // 	.probe6  ( iram_be          ) ,
        // 	.probe7  ( 1'b0             ) ,
        // 	.probe8  ( 1'b0             ) ,
        // 	.probe9  ( 1'b0             ) ,
        // 	.probe10 ( 1'b0             ) ,
        // 	.probe11 ( 1'b0             ) 
        // );

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

