// ----------------------------------------------------------------------
// Copyright 2023 TimingWalker
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
// Last Modified : 2023-12-27 14:44:43
// Description   : 
// ----------------------------------------------------------------------

module CORE_COMPLEX(
     input logic                                    clk_i
    ,input logic                                    rst_ni
    ,input logic [31:0]                             hart_id_i
    ,input logic                                    irq_mei_i 
    ,input logic                                    irq_mti_i 
    ,input logic                                    irq_msi_i 
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
    ,output logic [SOPHON_PKG::FGPIO_NUM-1:0]       gpio_dir_o
    ,input  logic [SOPHON_PKG::FGPIO_NUM-1:0]       gpio_in_val_i
    ,output logic [SOPHON_PKG::FGPIO_NUM-1:0]       gpio_out_val_o
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


);




    // ----------------------------------------------------------------------
    //  AXI INTERCONNECT
    // ----------------------------------------------------------------------


    CC_ITF_PKG::xbar_slv_port_d64_req_t   [2:0] xbar_slv_port_req;
    CC_ITF_PKG::xbar_slv_port_d64_resps_t [2:0] xbar_slv_port_rsp;
    CC_ITF_PKG::xbar_mst_port_d64_req_t   [2:0] xbar_mst_port_req;
    CC_ITF_PKG::xbar_mst_port_d64_resps_t [2:0] xbar_mst_port_rsp;
    CC_ITF_PKG::apb_d32_req_t             [2:0] apb_req;
    CC_ITF_PKG::apb_d32_resps_t           [2:0] apb_resp;


    AXI_INTERCONNECT U_AXI_INTERCONNECT (
        .clk_i               ( clk_i             )
       ,.rst_ni              ( rst_ni            )
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
    logic debug_req;

    debugger #(
        .CC_NUM(1)
    ) U_DEBUGGER(
         .clk_i            ( clk_i                )
        ,.rst_ni           ( rst_ni               )
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
        CC_ITF_PKG::xbar_mst_port_d64_req_t   sophon_axi_slv_d64_req;
        CC_ITF_PKG::xbar_mst_port_d64_resps_t sophon_axi_slv_d64_rsp;

        assign sophon_axi_slv_d64_req = xbar_mst_port_req[0];
        assign xbar_mst_port_rsp[0] = sophon_axi_slv_d64_rsp;
    `elsif 
        assign xbar_mst_port_rsp[0].aw_ready = 1'b1;
        assign xbar_mst_port_rsp[0].w_ready  = 1'b1;
        assign xbar_mst_port_rsp[0].ar_ready = 1'b1;
        assign xbar_mst_port_rsp[0].b_valid  = 1'b0;
        assign xbar_mst_port_rsp[0].r_valid  = 1'b0;
    `endif
    
    `ifdef SOPHON_EXT_INST_DATA
        CC_ITF_PKG::xbar_slv_port_d64_req_t   sophon_axi_mst_d64_req;
        CC_ITF_PKG::xbar_slv_port_d64_resps_t sophon_axi_mst_d64_rsp;

        assign xbar_slv_port_req[0] = sophon_axi_mst_d64_req;
        assign sophon_axi_mst_d64_rsp = xbar_slv_port_rsp[0];
    `elsif 
        assign xbar_slv_port_req[0].aw_valid = 1'b0;
        assign xbar_slv_port_req[0].w_valid  = 1'b0;
        assign xbar_slv_port_req[0].ar_valid = 1'b0;
        assign xbar_slv_port_req[0].b_ready  = 1'b1;
        assign xbar_slv_port_req[0].r_valid  = 1'b1;
    `endif


    logic         cc_rst;
    logic  [31:0] cc_boot;

    SOPHON_AXI_TOP #( 
        .HART_ID(0) 
    ) U_SOPHON_AXI_TOP (
         .clk_i                                   ( clk_i                  ) 
         ,.rst_ni                                 ( rst_ni                 ) 
         ,.rst_soft_ni                            ( cc_rst                 ) 
         ,.bootaddr_i                             ( cc_boot                ) 
         ,.hart_id_i                              ( hart_id_i              ) 
         ,.irq_mei_i                              ( irq_mei_i              ) 
         ,.irq_mti_i                              ( irq_mti_i              ) 
         ,.irq_msi_i                              ( irq_msi_i              ) 
         ,.dm_req_i                               ( debug_req              ) 
    `ifdef SOPHON_EXT_ACCESS
         ,.axi_slv_d64_req_i                      ( sophon_axi_slv_d64_req ) 
         ,.axi_slv_d64_rsp_o                      ( sophon_axi_slv_d64_rsp ) 
    `endif
    `ifdef SOPHON_EXT_INST_DATA
         ,.axi_mst_d64_req_o                      ( sophon_axi_mst_d64_req ) 
         ,.axi_mst_d64_rsp_i                      ( sophon_axi_mst_d64_rsp ) 
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
        .PRESETn      ( rst_ni                 ) ,
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
    //  ICCS UART
    // -----------------------------------
    apb_uart_sv 
    #(
        .APB_ADDR_WIDTH(12)
    ) U_UART
    (
        .CLK     ( clk_i                            ) ,
        .RSTN    ( rst_ni                           ) ,
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
    //  CLIC interface
    // -----------------------------------
    `ifdef SOPHON_CLIC
        assign clic_apb_req_o = apb_req[2];
        assign apb_resp[2]  = clic_apb_rsp_i;
    `else
        assign apb_resp[2].pready = 1'b1;
    `endif


endmodule

