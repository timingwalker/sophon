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
// Create Date   : 2023-12-20 16:58:18
// Last Modified : 2024-08-05 15:18:01
// Description   : Core Complex
//                  - Sophon
//                  - AXI INTERCONNECT
//                  - CRG
//                  - Debug Module
//                  - System register
//                  - UART
// ----------------------------------------------------------------------

module CORE_COMPLEX(
     input logic                                    clk_i
    ,input logic                                    rst_ni
    ,input logic [31:0]                             hart_id_i
    ,input logic                                    irq_mei_i 
`ifdef SOPHON_CLIC
    ,input  logic                                   clic_irq_req_i      
    ,input  logic                                   clic_irq_shv_i      
    ,input  logic [4:0]                             clic_irq_id_i       
    ,input  logic [7:0]                             clic_irq_level_i    
    ,output logic                                   clic_irq_ack_o      
    ,output logic [7:0]                             clic_irq_intthresh_o
    ,output logic                                   clic_mnxti_clr_o    
    ,output logic [4:0]                             clic_mnxti_id_o     
    ,output CC_ITF_PKG::apb_d32_req_t               clic_apb_req_o
    ,input  CC_ITF_PKG::apb_d32_resps_t             clic_apb_rsp_i
`endif
`ifdef SOPHON_EEI_GPIO
    ,output logic [`FGPIO_NUM-1:0]                  gpio_dir_o
    ,input  logic [`FGPIO_NUM-1:0]                  gpio_in_val_i
    ,output logic [`FGPIO_NUM-1:0]                  gpio_out_val_o
`endif
    ,input                                          tck_i
    ,input                                          tms_i
    ,input                                          trst_n_i
    ,input                                          tdi_i
    ,output                                         tdo_o
    ,output                                         tdo_oe_o
    ,input                                          uart_rx_i
    ,output                                         uart_tx_o
`ifdef SOPHON_EXT_ACCESS
    ,input  CC_ITF_PKG::xbar_slv_port_d64_req_t     axi_slv_port_req_i
    ,output CC_ITF_PKG::xbar_slv_port_d64_resps_t   axi_slv_port_rsp_o
`endif
`ifdef SOPHON_EXT_INST_DATA
    ,output CC_ITF_PKG::xbar_mst_port_d64_req_t     axi_mst_port_req_o
    ,input  CC_ITF_PKG::xbar_mst_port_d64_resps_t   axi_mst_port_rsp_i
`endif
`ifdef PROBE
    ,output logic [209:0]                           probe_o
`endif


);


    logic         cc_rst;
    logic  [31:0] cc_boot;
    logic         debug_req;
    logic         clk_neg;
    logic         rstn_core_sync;
    logic         irq_mti;
    logic         irq_msi;

    // ----------------------------------------------------------------------
    //  Clock Reset Generator
    // ----------------------------------------------------------------------
    CRG U_CRG (
        .clk_i               ( clk_i             )
       ,.rst_ni              ( rst_ni            )
       ,.rst_soft_i          ( cc_rst            )
       ,.clk_neg_o           ( clk_neg           )
       ,.rstn_sync_o         ( rstn_sync         )
       ,.rstn_comb_sync_o    ( rstn_comb_sync    )
    );


    // ----------------------------------------------------------------------
    //  AXI INTERCONNECT
    // ----------------------------------------------------------------------
    CC_ITF_PKG::xbar_slv_port_d64_req_t   [2:0] xbar_slv_port_req;
    CC_ITF_PKG::xbar_slv_port_d64_resps_t [2:0] xbar_slv_port_rsp;
    CC_ITF_PKG::xbar_mst_port_d64_req_t   [2:0] xbar_mst_port_req;
    CC_ITF_PKG::xbar_mst_port_d64_resps_t [2:0] xbar_mst_port_rsp;
    CC_ITF_PKG::apb_d32_req_t             [3:0] apb_req;
    CC_ITF_PKG::apb_d32_resps_t           [3:0] apb_resp;

    AXI_INTERCONNECT U_AXI_INTERCONNECT (
        .clk_i               ( clk_i             )
       ,.rst_ni              ( rstn_sync         )
       ,.testmode_i          ( 1'b0              )
       ,.xbar_slv_port_req_i ( xbar_slv_port_req )
       ,.xbar_slv_port_rsp_o ( xbar_slv_port_rsp )
       ,.xbar_mst_port_req_o ( xbar_mst_port_req )
       ,.xbar_mst_port_rsp_i ( xbar_mst_port_rsp )
       ,.apb_req_o           ( apb_req           )
       ,.apb_rsp_i           ( apb_resp          )
    );


    // ----------------------------------------------------------------------
    //  External interface
    // ----------------------------------------------------------------------
    `ifdef SOPHON_EXT_ACCESS
        assign axi_slv_port_rsp_o   = xbar_slv_port_rsp[2];
        assign xbar_slv_port_req[2] = axi_slv_port_req_i;
    `endif
    `ifdef SOPHON_EXT_INST_DATA
        assign axi_mst_port_req_o   = xbar_mst_port_req[2];
        assign xbar_mst_port_rsp[2] = axi_mst_port_rsp_i;
    `endif


    // ----------------------------------------------------------------------
    //   Debug Module
    // ----------------------------------------------------------------------
    debugger #(
        .CC_NUM(1)
    ) U_DEBUGGER(
         .clk_i            ( clk_i                )
        ,.rst_ni           ( rstn_sync            )
        ,.debug_req        ( debug_req            )
        ,.axi_sba_mst_req  ( xbar_slv_port_req[1] )
        ,.axi_sba_mst_resp ( xbar_slv_port_rsp[1] )
        ,.axi_dbg_slv_req  ( xbar_mst_port_req[1] )
        ,.axi_dbg_slv_resp ( xbar_mst_port_rsp[1] )
        ,.tck              ( tck_i                )
        ,.tms              ( tms_i                )
        ,.trst_n           ( trst_n_i             )
        ,.tdi              ( tdi_i                )
        ,.tdo              ( tdo_o                )
        ,.tdo_oe           ( tdo_oe_o             )
    );


    // ----------------------------------------------------------------------
    //   Sophon Core
    // ----------------------------------------------------------------------
    `ifdef SOPHON_EXT_ACCESS
        CC_ITF_PKG::xbar_mst_port_d64_req_t   xbar_slv_d64_req;
        CC_ITF_PKG::xbar_mst_port_d64_resps_t xbar_slv_d64_rsp;
        CC_ITF_PKG::axi_mst_side_d32_req_t    sophon_axi_slv_d32_req;
        CC_ITF_PKG::axi_mst_side_d32_resps_t  sophon_axi_slv_d32_rsp;

        // -----------------------------------
        //  From XBAR: AXI 64
        // -----------------------------------
        assign xbar_slv_d64_req     = xbar_mst_port_req[0];
        assign xbar_mst_port_rsp[0] = xbar_slv_d64_rsp;

        // -----------------------------------
        //  AXI 64 -> AXI 32
        // -----------------------------------
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
        ) i_axi_dw_64b_32b_converter (
            .clk_i         ( clk_i                  ) ,
            .rst_ni        ( rst_ni                 ) ,
            .slv_req_i     ( xbar_slv_d64_req       ) ,
            .slv_resp_o    ( xbar_slv_d64_rsp       ) ,
            .mst_req_o     ( sophon_axi_slv_d32_req ) ,
            .mst_resp_i    ( sophon_axi_slv_d32_rsp ) 
        );
    `elsif 
        assign xbar_mst_port_rsp[0].aw_ready = 1'b1;
        assign xbar_mst_port_rsp[0].w_ready  = 1'b1;
        assign xbar_mst_port_rsp[0].ar_ready = 1'b1;
        assign xbar_mst_port_rsp[0].b_valid  = 1'b0;
        assign xbar_mst_port_rsp[0].r_valid  = 1'b0;
    `endif
    
    `ifdef SOPHON_EXT_INST_DATA
        CC_ITF_PKG::xbar_slv_port_d64_req_t   xbar_mst_d64_req;
        CC_ITF_PKG::xbar_slv_port_d64_resps_t xbar_mst_d64_rsp;
        CC_ITF_PKG::axi_slv_side_d32_req_t    sophon_axi_mst_d32_req;
        CC_ITF_PKG::axi_slv_side_d32_resps_t  sophon_axi_mst_d32_rsp;

        // -----------------------------------
        //  To XBAR: AXI 64
        // -----------------------------------
        assign xbar_slv_port_req[0] = xbar_mst_d64_req;
        assign xbar_mst_d64_rsp     = xbar_slv_port_rsp[0];

        // -----------------------------------
        //  AXI 32 -> AXI 64
        // -----------------------------------
        axi_dw_converter #(
            .AxiMaxReads         ( 4                                     ) ,
            .AxiSlvPortDataWidth ( 32                                    ) ,
            .AxiMstPortDataWidth ( 64                                    ) ,
            .AxiAddrWidth        ( CC_ITF_PKG::XBAR_ADDR_WIDTH           ) ,
            .AxiIdWidth          ( CC_ITF_PKG::XBAR_SLV_PORT_ID_WIDTH    ) ,
            .aw_chan_t           ( CC_ITF_PKG::xbar_slv_port_aw_t        ) ,
            .b_chan_t            ( CC_ITF_PKG::xbar_slv_port_b_t         ) ,
            .ar_chan_t           ( CC_ITF_PKG::xbar_slv_port_ar_t        ) ,
            .mst_w_chan_t        ( CC_ITF_PKG::xbar_w_chan_t             ) ,
            .mst_r_chan_t        ( CC_ITF_PKG::xbar_slv_port_r_t         ) ,
            .slv_w_chan_t        ( CC_ITF_PKG::axi_w_32b_t               ) ,
            .slv_r_chan_t        ( CC_ITF_PKG::axi_slv_side_r_32b_t      ) ,
            .axi_mst_req_t       ( CC_ITF_PKG::xbar_slv_port_d64_req_t   ) ,
            .axi_mst_resp_t      ( CC_ITF_PKG::xbar_slv_port_d64_resps_t ) ,
            .axi_slv_req_t       ( CC_ITF_PKG::axi_slv_side_d32_req_t    ) ,
            .axi_slv_resp_t      ( CC_ITF_PKG::axi_slv_side_d32_resps_t  ) 
        ) i_axi_dw_32b_64b_converter (
            .clk_i         ( clk_i                  ) ,
            .rst_ni        ( rst_ni                 ) ,
            .slv_req_i     ( sophon_axi_mst_d32_req ) ,
            .slv_resp_o    ( sophon_axi_mst_d32_rsp ) ,
            .mst_req_o     ( xbar_mst_d64_req       ) ,
            .mst_resp_i    ( xbar_mst_d64_rsp       ) 
        );
    `elsif 
        assign xbar_slv_port_req[0].aw_valid = 1'b0;
        assign xbar_slv_port_req[0].w_valid  = 1'b0;
        assign xbar_slv_port_req[0].ar_valid = 1'b0;
        assign xbar_slv_port_req[0].b_ready  = 1'b1;
        assign xbar_slv_port_req[0].r_valid  = 1'b1;
    `endif


    SOPHON_AXI_TOP #( 
        .HART_ID(0) 
    ) U_SOPHON_AXI_TOP (
          .clk_i                                  ( clk_i                  ) 
         ,.clk_neg_i                              ( clk_neg                )
         ,.rst_ni                                 ( rstn_sync              ) 
         ,.rst_soft_ni                            ( rstn_comb_sync         ) 
         ,.bootaddr_i                             ( cc_boot                ) 
         ,.hart_id_i                              ( hart_id_i              ) 
         ,.irq_mei_i                              ( irq_mei_i              ) 
         ,.irq_mti_i                              ( irq_mti                ) 
         ,.irq_msi_i                              ( irq_msi                ) 
    `ifdef SOPHON_RVDEBUG
         ,.dm_req_i                               ( debug_req              ) 
    `endif
    `ifdef SOPHON_EXT_ACCESS
         ,.axi_slv_d32_req_i                      ( sophon_axi_slv_d32_req ) 
         ,.axi_slv_d32_rsp_o                      ( sophon_axi_slv_d32_rsp ) 
    `endif
    `ifdef SOPHON_EXT_INST_DATA
         ,.axi_mst_d32_req_o                      ( sophon_axi_mst_d32_req ) 
         ,.axi_mst_d32_rsp_i                      ( sophon_axi_mst_d32_rsp ) 
    `endif
    `ifdef SOPHON_CLIC
         ,.clic_irq_req_i                         ( clic_irq_req_i         ) 
         ,.clic_irq_shv_i                         ( clic_irq_shv_i         ) 
         ,.clic_irq_id_i                          ( clic_irq_id_i          ) 
         ,.clic_irq_level_i                       ( clic_irq_level_i       ) 
         ,.clic_irq_ack_o                         ( clic_irq_ack_o         ) 
         ,.clic_irq_intthresh_o                   ( clic_irq_intthresh_o   ) 
         ,.clic_mnxti_clr_o                       ( clic_mnxti_clr_o       ) 
         ,.clic_mnxti_id_o                        ( clic_mnxti_id_o        ) 
    `endif
    `ifdef SOPHON_EEI_GPIO
         ,.gpio_dir_o                             ( gpio_dir_o             )
         ,.gpio_in_val_i                          ( gpio_in_val_i          )
         ,.gpio_out_val_o                         ( gpio_out_val_o         )
    `endif
     `ifdef PROBE
        ,.probe_o                                 (probe_o                 )
     `endif
    );


    // ----------------------------------------------------------------------
    //   APB interface
    // ----------------------------------------------------------------------

    // -----------------------------------
    //  syscfg reg
    // -----------------------------------
    APB_SYSCFG_REG
    #(
        .APB_ADDR_WIDTH (12) 
    ) U_APB_SYSCFG_REG
    (
        .PCLK         ( clk_i                  ) ,
        .PRESETn      ( rstn_sync              ) ,
        .PADDR        ( apb_req[0].paddr[11:0] ) ,
        .PWDATA       ( apb_req[0].pwdata      ) ,
        .PWRITE       ( apb_req[0].pwrite      ) ,
        .PSEL         ( apb_req[0].psel        ) ,
        .PENABLE      ( apb_req[0].penable     ) ,
        .PRDATA       ( apb_resp[0].prdata     ) ,
        .PREADY       ( apb_resp[0].pready     ) ,
        .PSLVERR      ( apb_resp[0].pslverr    ) ,
        // output
        .cfg_cc0_boot ( cc_boot                ) ,
        .cfg_cc0_rst  ( cc_rst                 ) ,
        .cfg_cc1_boot (                        ) ,
        .cfg_cc1_rst  (                        ) 
    );

    // -----------------------------------
    //  UART
    // -----------------------------------
    apb_uart_sv 
    #(
        .APB_ADDR_WIDTH(12)
    ) U_UART
    (
        .CLK     ( clk_i                            ) ,
        .RSTN    ( rstn_sync                        ) ,
        .PADDR   ( { 2'h0, apb_req[1].paddr[11:2] } ) ,
        .PWDATA  ( apb_req[1].pwdata                ) ,
        .PWRITE  ( apb_req[1].pwrite                ) ,
        .PSEL    ( apb_req[1].psel                  ) ,
        .PENABLE ( apb_req[1].penable               ) ,
        .PRDATA  ( apb_resp[1].prdata               ) ,
        .PREADY  ( apb_resp[1].pready               ) ,
        .PSLVERR ( apb_resp[1].pslverr              ) ,
        .rx_i    ( uart_rx_i                        ) ,
        .tx_o    ( uart_tx_o                        ) ,
        .event_o (                                  ) 
    );

    // -----------------------------------
    //  Clint
    // -----------------------------------
    CLINT 
    #(
        .APB_ADDR_WIDTH(12)
    ) U_CLINT
    (
        .PCLK    ( clk_i                            ) ,
        .PRESETn ( rstn_sync                        ) ,
        .PADDR   ( apb_req[2].paddr[11:0]           ) ,
        .PWDATA  ( apb_req[2].pwdata                ) ,
        .PWRITE  ( apb_req[2].pwrite                ) ,
        .PSEL    ( apb_req[2].psel                  ) ,
        .PENABLE ( apb_req[2].penable               ) ,
        .PRDATA  ( apb_resp[2].prdata               ) ,
        .PREADY  ( apb_resp[2].pready               ) ,
        .PSLVERR ( apb_resp[2].pslverr              ) ,
        .msi_o   ( irq_msi                          ) ,
        .mti_o   ( irq_mti                          ) 
    );

    // -----------------------------------
    //  CLIC interface
    // -----------------------------------
    `ifdef SOPHON_CLIC
        assign clic_apb_req_o = apb_req[3];
        assign apb_resp[3]  = clic_apb_rsp_i;
    `else
        assign apb_resp[3].pready = 1'b1;
    `endif


endmodule

