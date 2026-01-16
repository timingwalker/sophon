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
// Last Modified : 2026-01-14 11:34:42
// Description   : Core Complex
//                  - Sophon
//                  - AXI INTERCONNECT
//                  - CRG
//                  - Debug Module
//                  - System register
//                  - UART
// ----------------------------------------------------------------------

module CORE_COMPLEX(
     input logic                                     clk_i
    ,input logic                                     rst_ni
    ,input logic [31:0]                              hart_id_i
`ifdef SOPHON_CLINT
    ,input logic                                     irq_mei_i 
`endif
`ifdef SOPHON_CLIC
    ,input  logic                                    clic_irq_req_i      
    ,input  logic                                    clic_irq_shv_i      
    ,input  logic [4:0]                              clic_irq_id_i       
    ,input  logic [7:0]                              clic_irq_level_i    
    ,output logic                                    clic_irq_ack_o      
    ,output logic [7:0]                              clic_irq_intthresh_o
    ,output logic                                    clic_mnxti_clr_o    
    ,output logic [4:0]                              clic_mnxti_id_o     
    ,output CC_ITF_PKG::apb_d32_req_t                clic_apb_req_o
    ,input  CC_ITF_PKG::apb_d32_resps_t              clic_apb_resp_i
`endif
`ifdef SOPHON_EEI_GPIO
    ,output logic [`FGPIO_NUM-1:0]                   gpio_dir_o
    ,input  logic [`FGPIO_NUM-1:0]                   gpio_in_val_i
    ,output logic [`FGPIO_NUM-1:0]                   gpio_out_val_o
`endif
`ifdef SOPHON_RVDEBUG
    ,input                                           tck_i
    ,input                                           tms_i
    ,input                                           trst_n_i
    ,input                                           tdi_i
    ,output                                          tdo_o
    ,output                                          tdo_oe_o
`endif
    ,input                                           uart_rx_i
    ,output                                          uart_tx_o
`ifdef CORE_COMPLEX_AXI_SLV
    ,input  CC_ITF_PKG::xbar_port_d32_slv_id_req_t   axi_slv_port_req_i
    ,output CC_ITF_PKG::xbar_port_d32_slv_id_resps_t axi_slv_port_resp_o
`endif
`ifdef CORE_COMPLEX_AXI_MST
    ,output CC_ITF_PKG::xbar_port_d32_mst_id_req_t   axi_mst_port_req_o
    ,input  CC_ITF_PKG::xbar_port_d32_mst_id_resps_t axi_mst_port_resp_i
`endif
`ifdef PROBE
    ,output logic [209:0]                            probe_o
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
    CC_ITF_PKG::xbar_port_d32_slv_id_req_t   [2:0] xbar_slv_port_req;
    CC_ITF_PKG::xbar_port_d32_slv_id_resps_t [2:0] xbar_slv_port_resp;
    CC_ITF_PKG::xbar_port_d32_mst_id_req_t   [2:0] xbar_mst_port_req;
    CC_ITF_PKG::xbar_port_d32_mst_id_resps_t [2:0] xbar_mst_port_resp;
    CC_ITF_PKG::apb_d32_req_t                [4:0] apb_req;
    CC_ITF_PKG::apb_d32_resps_t              [4:0] apb_resp;

    AXI_INTERCONNECT U_AXI_INTERCONNECT (
        .clk_i                  ( clk_i              ) 
        ,.rst_ni                ( rstn_sync          ) 
        ,.testmode_i            ( 1'b0               ) 
        ,.xbar_slv_port_req_i   ( xbar_slv_port_req  ) 
        ,.xbar_slv_port_resps_o ( xbar_slv_port_resp ) 
        ,.xbar_mst_port_req_o   ( xbar_mst_port_req  ) 
        ,.xbar_mst_port_resps_i ( xbar_mst_port_resp ) 
        ,.apb_req_o             ( apb_req            ) 
        ,.apb_resps_i           ( apb_resp           ) 
    );


    // ----------------------------------------------------------------------
    //  External interface
    // ----------------------------------------------------------------------
    `ifdef CORE_COMPLEX_AXI_SLV
        assign axi_slv_port_resp_o  = xbar_slv_port_resp[2];
        assign xbar_slv_port_req[2] = axi_slv_port_req_i;
    `else
        assign xbar_slv_port_req[2].aw_valid = 1'b0;
        assign xbar_slv_port_req[2].w_valid  = 1'b0;
        assign xbar_slv_port_req[2].ar_valid = 1'b0;
        assign xbar_slv_port_req[2].b_ready  = 1'b1;
        assign xbar_slv_port_req[2].r_ready  = 1'b1;
    `endif
    `ifdef CORE_COMPLEX_AXI_MST
        assign axi_mst_port_req_o    = xbar_mst_port_req[2];
        assign xbar_mst_port_resp[2] = axi_mst_port_resp_i;
    `else
        assign xbar_mst_port_resp[2].aw_ready = 1'b1;
        assign xbar_mst_port_resp[2].w_ready  = 1'b1;
        assign xbar_mst_port_resp[2].ar_ready = 1'b1;
        assign xbar_mst_port_resp[2].b_valid  = 1'b0;
        assign xbar_mst_port_resp[2].r_valid  = 1'b0;
    `endif


    // ----------------------------------------------------------------------
    //   Debug Module
    // ----------------------------------------------------------------------
    `ifdef SOPHON_RVDEBUG
        debugger #(
            .CC_NUM(1)
        ) U_DEBUGGER(
             .clk_i             ( clk_i                 ) 
             ,.rst_ni           ( rstn_sync             ) 
             ,.debug_req        ( debug_req             ) 
             ,.axi_sba_mst_req  ( xbar_slv_port_req[1]  ) 
             ,.axi_sba_mst_resp ( xbar_slv_port_resp[1] ) 
             ,.axi_dbg_slv_req  ( xbar_mst_port_req[1]  ) 
             ,.axi_dbg_slv_resp ( xbar_mst_port_resp[1] ) 
             ,.tck              ( tck_i                 ) 
             ,.tms              ( tms_i                 ) 
             ,.trst_n           ( trst_n_i              ) 
             ,.tdi              ( tdi_i                 ) 
             ,.tdo              ( tdo_o                 ) 
             ,.tdo_oe           ( tdo_oe_o              ) 
        );
    `else
        assign xbar_slv_port_req[1].aw_valid = 1'b0;
        assign xbar_slv_port_req[1].w_valid  = 1'b0;
        assign xbar_slv_port_req[1].ar_valid = 1'b0;
        assign xbar_slv_port_req[1].b_ready  = 1'b1;
        assign xbar_slv_port_req[1].r_ready  = 1'b1;

        assign xbar_mst_port_resp[1].aw_ready = 1'b1;
        assign xbar_mst_port_resp[1].w_ready  = 1'b1;
        assign xbar_mst_port_resp[1].ar_ready = 1'b1;
        assign xbar_mst_port_resp[1].b_valid  = 1'b0;
        assign xbar_mst_port_resp[1].r_valid  = 1'b0;
    `endif


    // ----------------------------------------------------------------------
    //   Sophon Core
    // ----------------------------------------------------------------------
    `ifdef SOPHON_EXT_ACCESS
        // connect xbar <-> sophon
        CC_ITF_PKG::xbar_port_d32_mst_id_req_t   sophon_axi_slv_d32_req;
        CC_ITF_PKG::xbar_port_d32_mst_id_resps_t sophon_axi_slv_d32_resp;
        assign sophon_axi_slv_d32_req = xbar_mst_port_req[0];
        assign xbar_mst_port_resp[0] = sophon_axi_slv_d32_resp;
    `else
        // tie xbar input
        assign xbar_mst_port_resp[0].aw_ready = 1'b1;
        assign xbar_mst_port_resp[0].w_ready  = 1'b1;
        assign xbar_mst_port_resp[0].ar_ready = 1'b1;
        assign xbar_mst_port_resp[0].b_valid  = 1'b0;
        assign xbar_mst_port_resp[0].r_valid  = 1'b0;
    `endif
    
    `ifdef SOPHON_EXT_INST_DATA
        // connect xbar <-> sophon
        CC_ITF_PKG::xbar_port_d32_slv_id_req_t    sophon_axi_mst_d32_req;
        CC_ITF_PKG::xbar_port_d32_slv_id_resps_t  sophon_axi_mst_d32_resp;
        assign xbar_slv_port_req[0] = sophon_axi_mst_d32_req;
        assign sophon_axi_mst_d32_resp = xbar_slv_port_resp[0];
    `else
        // tie xbar input
        assign xbar_slv_port_req[0].aw_valid = 1'b0;
        assign xbar_slv_port_req[0].w_valid  = 1'b0;
        assign xbar_slv_port_req[0].ar_valid = 1'b0;
        assign xbar_slv_port_req[0].b_ready  = 1'b1;
        assign xbar_slv_port_req[0].r_ready  = 1'b1;
    `endif


    logic irq_mei;
    SOPHON_AXI_TOP #( 
        .HART_ID(0) 
    ) U_SOPHON_AXI_TOP (
          .clk_i                                  ( clk_i                  ) 
         ,.clk_neg_i                              ( clk_neg                )
         ,.rst_ni                                 ( rstn_sync              ) 
         ,.rst_soft_ni                            ( rstn_comb_sync         ) 
         ,.bootaddr_i                             ( cc_boot                ) 
         ,.hart_id_i                              ( hart_id_i              ) 
    `ifdef SOPHON_CLINT
         ,.irq_mei_i                              ( irq_mei                ) 
         ,.irq_mti_i                              ( irq_mti                ) 
         ,.irq_msi_i                              ( irq_msi                ) 
    `endif
    `ifdef SOPHON_RVDEBUG
         ,.dm_req_i                               ( debug_req              ) 
    `endif
    `ifdef SOPHON_EXT_ACCESS
         ,.axi_slv_d32_req_i                      ( sophon_axi_slv_d32_req ) 
         ,.axi_slv_d32_resps_o                    ( sophon_axi_slv_d32_resp) 
    `endif
    `ifdef SOPHON_EXT_INST_DATA
         ,.axi_mst_d32_req_o                      ( sophon_axi_mst_d32_req ) 
         ,.axi_mst_d32_resps_i                    ( sophon_axi_mst_d32_resp) 
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
        ,.probe_o                                 ( probe_o                )
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
    logic irq_uart;
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
        .event_o ( irq_uart                         ) 
    );

    // -----------------------------------
    //  Clint
    // -----------------------------------
    `ifdef SOPHON_CLINT
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
    `else
        assign apb_resp[2].pready = 1'b1;
    `endif

    // -----------------------------------
    //  CLIC interface
    // -----------------------------------
    `ifdef SOPHON_CLIC
        assign clic_apb_req_o = apb_req[3];
        assign apb_resp[3]  = clic_apb_resp_i;
    `else
        assign apb_resp[3].pready = 1'b1;
    `endif

    // -----------------------------------
    //  PLIC interface
    // -----------------------------------
    `ifdef SOPHON_PLIC

        SOPHON_PKG::reg_intf_resp_d32     plic_resp;
        SOPHON_PKG::reg_intf_req_a32_d32  plic_req;

        always_comb begin
            plic_req.valid = apb_req[4].psel & apb_req[4].penable;
            //plic_req.addr  = {16'hc00, apb_req[4].paddr[15:0]};
            plic_req.addr  = apb_req[4].paddr - 32'h07040000 + 32'h0c000000;
            plic_req.write = apb_req[4].pwrite;
            plic_req.wdata = apb_req[4].pwdata;
            plic_req.wstrb = '1;
            apb_resp[4].pready  = plic_resp.ready;
            apb_resp[4].pslverr = plic_resp.error;
            apb_resp[4].prdata  = plic_resp.rdata;
        end

        plic_top #(
            // TODO: 
            .N_SOURCE    ( 1  ),
            .N_TARGET    ( 1  ),
            .MAX_PRIO    ( 7  )
        ) i_plic (
            .clk_i,
            .rst_ni,
            .req_i         ( plic_req    ) ,
            .resp_o        ( plic_resp   ) ,
            .le_i          ( '0          ) , // 0:level 1:edge
            .irq_sources_i ( irq_uart    ) ,
            .eip_targets_o ( irq_mei     ) 
        );

    `else
        assign apb_resp[4].pready = 1'b1;
        `ifdef SOPHON_CLINT
            assign irq_mei = irq_mei_i;
        `endif
    `endif

    //  // -----------------------------------
    //  //  Timer
    //  // -----------------------------------
    //  `ifdef SOPHON_TIMER
    //      apb_timer #(
    //      .APB_ADDR_WIDTH ( 32  ),
    //      .TIMER_CNT      ( 1   )
    //      ) i_timer (
    //      .HCLK    ( clk_i                  ) ,
    //      .HRESETn ( rst_ni                 ) ,
    //      .PSEL    ( apb_req[5].psel        ) ,
    //      .PENABLE ( apb_req[5].penable     ) ,
    //      .PWRITE  ( apb_req[5].pwrite      ) ,
    //      .PADDR   ( apb_req[5].paddr[11:2] ) ,
    //      .PWDATA  ( apb_req[5].pwdata      ) ,
    //      .PRDATA  ( apb_resp[5].prdata     ) ,
    //      .PREADY  ( apb_resp[5].pready     ) ,
    //      .PSLVERR ( apb_resp[5].pslverr    ) ,
    //      .irq_o   ( irq_sources[2:1]       ) 
    //      );
    //  `else
    //      assign apb_resp[5].pready = 1'b1;
    //  `endif

endmodule

