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
// Create Date   : 2022-11-01 11:10:35
// Last Modified : 2024-04-26 10:29:40
// Description   : Top module of the SOPHON core        
//                 - Core
//                 - L1 Inst RAM
//                 - L1 Data RAM
//                 - Custom execution unit
//                 - External interfaces
// ----------------------------------------------------------------------

module SOPHON_TOP (
     input logic                              clk_i
    ,input logic                              clk_neg_i
    ,input logic                              rst_ni
    ,input logic                              rst_soft_ni
    ,input logic [31:0]                       bootaddr_i
    ,input logic [31:0]                       hart_id_i
    // interupt 
    ,input logic                              irq_mei_i 
    ,input logic                              irq_mti_i 
    ,input logic                              irq_msi_i 
`ifdef SOPHON_RVDEBUG
    // debug halt request
    ,input  logic                             dm_req_i
`endif
    // dummy output for synthesis compatibility
    ,output logic                             dummy_o
`ifdef SOPHON_EXT_INST
    ,output logic                             inst_ext_req_o
    ,output logic [31:0]                      inst_ext_addr_o
    ,input  logic                             inst_ext_ack_i
    ,input  logic [31:0]                      inst_ext_rdata_i
    ,input  logic                             inst_ext_error_i
`endif
`ifdef SOPHON_EXT_DATA
    ,output logic                             data_req_o
    ,output logic                             data_we_o
    ,output logic [31:0]                      data_addr_o
    ,output logic [31:0]                      data_wdata_o
    ,output logic [3:0]                       data_amo_o
    ,output logic [3:0]                       data_strb_o
    ,output logic [1:0]                       data_size_o
    ,input  logic                             data_valid_i
    ,input  logic                             data_error_i
    ,input  logic [31:0]                      data_rdata_i
`endif
`ifdef SOPHON_EXT_ACCESS
    // external access interface
    ,input  logic                             ext_req_i
    ,input  logic                             ext_we_i
    ,input  logic [3:0]                       ext_strb_i
    ,input  logic [31:0]                      ext_addr_i
    ,input  logic [31:0]                      ext_wdata_i
    ,output logic                             ext_ack_o
    ,output logic                             ext_error_o
    ,output logic [31:0]                      ext_rdata_o
`endif
`ifdef SOPHON_CLIC
    ,input  logic                             clic_irq_req_i
    ,input  logic                             clic_irq_shv_i
    ,input  logic [4:0]                       clic_irq_id_i
    ,input  logic [7:0]                       clic_irq_level_i
    ,output logic                             clic_irq_ack_o
    ,output logic [7:0]                       clic_irq_intthresh_o
    ,output logic                             clic_mnxti_clr_o
    ,output logic [4:0]                       clic_mnxti_id_o
`endif
`ifdef SOPHON_EEI_GPIO
    ,output logic [SOPHON_PKG::FGPIO_NUM-1:0] gpio_dir_o
    ,input  logic [SOPHON_PKG::FGPIO_NUM-1:0] gpio_in_val_i
    ,output logic [SOPHON_PKG::FGPIO_NUM-1:0] gpio_out_val_o
`endif
`ifdef PROBE
    ,output logic [209:0]                     probe_o
`endif

);


    logic                   rstn_sync;
    logic                   rstn_neg_sync;

    SOPHON_PKG::lsu_req_t   lsu_core_req;
    SOPHON_PKG::lsu_ack_t   lsu_core_ack;
    SOPHON_PKG::lsu_req_t   core_dram_req;
    SOPHON_PKG::lsu_ack_t   core_dram_ack;

    SOPHON_PKG::inst_req_t  inst_core_req;
    SOPHON_PKG::inst_ack_t  inst_core_ack;
    SOPHON_PKG::inst_req_t  core_iram_req;
    SOPHON_PKG::inst_ack_t  core_iram_ack;

`ifdef SOPHON_EEI
    logic                   eei_req;
    logic                   eei_ext;
    logic [2:0]             eei_funct3;
    logic [6:0]             eei_funct7;
    logic [4:0]             eei_batch_start;
    logic [4:0]             eei_batch_len;
    logic [31:0]            eei_rs_val[SOPHON_PKG::EEI_RS_MAX-1:0];
    logic                   eei_ack;
    logic [1:0]             eei_rd_op;
    logic [4:0]             eei_rd_len;
    logic                   eei_error;
    logic [31:0]            eei_rd_val[SOPHON_PKG::EEI_RD_MAX-1:0];
`endif



    // ----------------------------------------------------------------------
    //  I/O
    // ----------------------------------------------------------------------
    assign rstn_sync     = rst_ni;
    assign rstn_neg_sync = rst_ni;

    assign dummy_o = 1'b1;

    `ifdef PROBE
        logic [139:0] probe_sophon_core;
        assign probe_o[139:0]    = probe_sophon_core;

        assign probe_o[171:140]  = iram_addr_offset ;
        assign probe_o[203:172]  = iram_wdata       ;
        assign probe_o[204]      = iram_req         ;
        assign probe_o[205]      = iram_we          ;
        assign probe_o[206]      = iram_be          ;
    `endif


    // ----------------------------------------------------------------------
    //  SOPHON core
    // ----------------------------------------------------------------------
    SOPHON U_SOPHON (
          .clk_i              ( clk_i                ) 
         ,.clk_neg_i          ( clk_neg_i            ) 
         ,.rst_ni             ( rst_soft_ni          ) 
         ,.bootaddr_i         ( bootaddr_i           ) 
         ,.hart_id_i          ( hart_id_i            ) 
         ,.inst_req_o         ( inst_core_req.req    ) 
         ,.inst_addr_o        ( inst_core_req.addr   ) 
         ,.inst_error_i       ( inst_core_ack.error  ) 
         ,.inst_ack_i         ( inst_core_ack.ack    ) 
         ,.inst_data_i        ( inst_core_ack.rdata  ) 
         ,.irq_mei_i          ( irq_mei_i            ) 
         ,.irq_mti_i          ( irq_mti_i            ) 
         ,.irq_msi_i          ( irq_msi_i            ) 
    `ifdef SOPHON_RVDEBUG
         ,.dm_req_i           ( dm_req_i             ) 
    `endif
         ,.lsu_req_o          ( lsu_core_req.req     ) 
         ,.lsu_we_o           ( lsu_core_req.we      ) 
         ,.lsu_addr_o         ( lsu_core_req.addr    ) 
         ,.lsu_wdata_o        ( lsu_core_req.wdata   ) 
         ,.lsu_strb_o         ( lsu_core_req.strb    ) 
         ,.lsu_amo_o          ( lsu_core_req.amo     ) 
         ,.lsu_size_o         ( lsu_core_req.size    ) 
         ,.lsu_ack_i          ( lsu_core_ack.ack     ) 
         ,.lsu_error_i        ( lsu_core_ack.error   ) 
         ,.lsu_rdata_i        ( lsu_core_ack.rdata   ) 
    `ifdef SOPHON_EEI
        ,.eei_req_o           ( eei_req              ) 
        ,.eei_ext_o           ( eei_ext              ) 
        ,.eei_funct3_o        ( eei_funct3           ) 
        ,.eei_funct7_o        ( eei_funct7           ) 
        ,.eei_batch_start_o   ( eei_batch_start      ) 
        ,.eei_batch_len_o     ( eei_batch_len        ) 
        ,.eei_rs_val_o        ( eei_rs_val           ) 
        ,.eei_ack_i           ( eei_ack              ) 
        ,.eei_rd_op_i         ( eei_rd_op            ) 
        ,.eei_rd_len_i        ( eei_rd_len           ) 
        ,.eei_error_i         ( eei_error            ) 
        ,.eei_rd_val_i        ( eei_rd_val           ) 
    `endif
    `ifdef SOPHON_CLIC
       ,.clic_irq_req_i       ( clic_irq_req_i       ) 
       ,.clic_irq_shv_i       ( clic_irq_shv_i       ) 
       ,.clic_irq_id_i        ( clic_irq_id_i        ) 
       ,.clic_irq_level_i     ( clic_irq_level_i     ) 
       ,.clic_irq_ack_o       ( clic_irq_ack_o       ) 
       ,.clic_irq_intthresh_o ( clic_irq_intthresh_o )
       ,.clic_mnxti_clr_o     ( clic_mnxti_clr_o     )
       ,.clic_mnxti_id_o      ( clic_mnxti_id_o      )
    `endif
    `ifdef PROBE
       ,.probe_sophon_o       ( probe_sophon_core    )
    `endif
    );


    // ----------------------------------------------------------------------
    //  Configurable external interface
    // ----------------------------------------------------------------------

    // -----------------------------------
    //  External Access Interface 
    // -----------------------------------
    `ifdef SOPHON_EXT_ACCESS

        SOPHON_PKG::lsu_req_t   ext_access_req;
        SOPHON_PKG::lsu_ack_t   ext_access_ack;
        SOPHON_PKG::lsu_req_t   ext_iram_req;
        SOPHON_PKG::lsu_ack_t   ext_iram_ack;
        SOPHON_PKG::lsu_req_t   ext_dram_req;
        SOPHON_PKG::lsu_ack_t   ext_dram_ack;

        assign ext_access_req.req   = ext_req_i;
        assign ext_access_req.we    = ext_we_i;
        assign ext_access_req.addr  = ext_addr_i;
        assign ext_access_req.wdata = ext_wdata_i;
        assign ext_access_req.size  = 2'b11;
        assign ext_access_req.amo   = '0;
        assign ext_access_req.strb  = ext_strb_i;
        assign ext_ack_o            = ext_access_ack.ack;
        assign ext_error_o          = ext_access_ack.error;
        assign ext_rdata_o          = ext_access_ack.rdata;

        DATA_ITF_DEMUX 
        #(
            .CH1_BASE ( SOPHON_PKG::ITCM_BASE ) ,
            .CH1_END  ( SOPHON_PKG::ITCM_END  ) ,
            .CH2_BASE ( SOPHON_PKG::DTCM_BASE ) ,
            .CH2_END  ( SOPHON_PKG::DTCM_END  ) 
        )
        U_EXT_ACCESS_DEMUX
        (
            .lsu_req_i     ( ext_access_req ) ,
            .lsu_ack_o     ( ext_access_ack ) ,
            .lsu_req_1ch_o ( ext_iram_req   ) ,
            .lsu_ack_1ch_i ( ext_iram_ack   ) ,
            .lsu_req_2ch_o ( ext_dram_req   ) ,
            .lsu_ack_2ch_i ( ext_dram_ack   ) 
        );

    `endif

    // -----------------------------------
    //  External instruction interface
    // -----------------------------------
    `ifdef SOPHON_EXT_INST

        SOPHON_PKG::inst_req_t   inst_pos_req;
        SOPHON_PKG::inst_ack_t   inst_pos_ack;

        INST_ITF_DEMUX #(
            .CH1_NEG_BASE ( SOPHON_PKG::ITCM_BASE     ) ,
            .CH1_NEG_END  ( SOPHON_PKG::ITCM_END      ) ,
            .CH2_POS_BASE ( SOPHON_PKG::EXT_INST_BASE ) ,
            .CH2_POS_END  ( SOPHON_PKG::EXT_INST_END  ) 
        ) U_INST_ITF_DEMUX (
            .clk_i              ( clk_i               ) ,
            .rst_ni             ( rstn_sync           ) ,
            .clk_neg_i          ( clk_neg_i           ) ,
            .rst_neg_ni         ( rstn_neg_sync       ) ,

            .inst_core_req_i    ( inst_core_req.req   ) ,
            .inst_core_addr_i   ( inst_core_req.addr  ) ,
            .inst_core_error_o  ( inst_core_ack.error ) ,
            .inst_core_ack_o    ( inst_core_ack.ack   ) ,
            .inst_core_data_o   ( inst_core_ack.rdata ) ,

            .inst_neg_req_o     ( core_iram_req.req   ) ,
            .inst_neg_addr_o    ( core_iram_req.addr  ) ,
            .inst_neg_error_i   ( core_iram_ack.error ) ,
            .inst_neg_ack_i     ( core_iram_ack.ack   ) ,
            .inst_neg_data_i    ( core_iram_ack.rdata ) ,

            .inst_pos_req_o     ( inst_pos_req.req    ) ,
            .inst_pos_addr_o    ( inst_pos_req.addr   ) ,
            .inst_pos_error_i   ( inst_pos_ack.error  ) ,
            .inst_pos_ack_i     ( inst_pos_ack.ack    ) ,
            .inst_pos_data_i    ( inst_pos_ack.rdata  ) 
        );

        assign inst_ext_req_o     = inst_pos_req.req;
        assign inst_ext_addr_o    = inst_pos_req.addr;
        assign inst_pos_ack.ack   = inst_ext_ack_i;
        assign inst_pos_ack.rdata = inst_ext_rdata_i;
        assign inst_pos_ack.error = inst_ext_error_i;

    `else
        assign core_iram_req = inst_core_req;
        assign inst_core_ack = core_iram_ack;
    `endif

    // -----------------------------------
    //  External data interface
    // -----------------------------------
    `ifdef SOPHON_EXT_DATA

        SOPHON_PKG::lsu_req_t   lsu_ext_req;
        SOPHON_PKG::lsu_ack_t   lsu_ext_ack;

        DATA_ITF_DEMUX 
        #(
            .CH1_BASE ( SOPHON_PKG::DTCM_BASE     ) ,
            .CH1_END  ( SOPHON_PKG::DTCM_END      ) ,
            .CH2_BASE ( SOPHON_PKG::EXT_DATA_BASE ) ,
            .CH2_END  ( SOPHON_PKG::EXT_DATA_END  ) 
        )
        U_DATA_DEMUX
        (
            .lsu_req_i     ( lsu_core_req  ) ,
            .lsu_ack_o     ( lsu_core_ack  ) ,
            .lsu_req_1ch_o ( core_dram_req ) ,
            .lsu_ack_1ch_i ( core_dram_ack ) ,
            .lsu_req_2ch_o ( lsu_ext_req   ) ,
            .lsu_ack_2ch_i ( lsu_ext_ack   ) 
        );

        assign data_req_o   = lsu_ext_req.req;
        assign data_we_o    = lsu_ext_req.we;
        assign data_addr_o  = lsu_ext_req.addr;
        assign data_wdata_o = lsu_ext_req.wdata;
        assign data_amo_o   = lsu_ext_req.amo;
        assign data_size_o  = lsu_ext_req.size;
        assign data_strb_o  = lsu_ext_req.strb;

        assign lsu_ext_ack.ack   = data_valid_i;
        assign lsu_ext_ack.error = data_error_i;
        assign lsu_ext_ack.rdata = data_rdata_i; 
    `else
        assign core_dram_req = lsu_core_req;
        assign lsu_core_ack  = core_dram_ack;
    `endif


    // ----------------------------------------------------------------------
    //  CUST
    // ----------------------------------------------------------------------
    `ifdef SOPHON_EEI

        CUST U_CUST (
             .clk_i           ( clk_i           )
            ,.clk_neg_i       ( clk_neg_i       ) 
            ,.rst_ni          ( rst_soft_ni     )
            ,.eei_req         ( eei_req         )
            ,.eei_ext         ( eei_ext         )
            ,.eei_funct3      ( eei_funct3      )
            ,.eei_funct7      ( eei_funct7      )
            ,.eei_batch_start ( eei_batch_start )
            ,.eei_batch_len   ( eei_batch_len   )
            ,.eei_rd_len      ( eei_rd_len      )
            ,.eei_rs_val      ( eei_rs_val      )
            ,.eei_ack         ( eei_ack         )
            ,.eei_rd_op       ( eei_rd_op       )
            ,.eei_error       ( eei_error       )
            ,.eei_rd_val      ( eei_rd_val      )
        `ifdef SOPHON_EEI_GPIO
            ,.gpio_dir        ( gpio_dir_o      )
            ,.gpio_in_val     ( gpio_in_val_i   )
            ,.gpio_out_val    ( gpio_out_val_o  )
        `endif
        );

    `endif


    // ----------------------------------------------------------------------
    //  Instruction RAM
    // ----------------------------------------------------------------------
    logic               iram_req;
    logic [31:0]        iram_addr;
    logic [31:0]        iram_rdata;
    logic [31:0]        iram_wdata;
    logic [3:0]         iram_be;
    logic               iram_we;

    // -----------------------------------
    //  INST arbiter
    // -----------------------------------
    `ifdef SOPHON_EXT_ACCESS

        INST_ITF_ARBITER U_INST_ITF_ARBITER (
              .clk_i         ( clk_i         ) 
             ,.rst_ni        ( rstn_sync     ) 
             ,.clk_neg_i     ( clk_neg_i     ) 
             ,.rst_neg_ni    ( rstn_neg_sync ) 
             ,.core_iram_req ( core_iram_req ) 
             ,.core_iram_ack ( core_iram_ack ) 
             ,.ext_iram_req  ( ext_iram_req  ) 
             ,.ext_iram_ack  ( ext_iram_ack  ) 
             ,.iram_req      ( iram_req      ) 
             ,.iram_addr     ( iram_addr     ) 
             ,.iram_wdata    ( iram_wdata    ) 
             ,.iram_we       ( iram_we       ) 
             ,.iram_be       ( iram_be       ) 
             ,.iram_rdata    ( iram_rdata    ) 
        );

    `else
        assign iram_req            = core_iram_req.req;
        assign iram_addr           = core_iram_req.addr;
        assign iram_wdata          = 'b0;
        assign iram_we             = 'b0;
        assign iram_be             = 'b0;
        assign core_iram_ack.ack   = 1'b1;
        assign core_iram_ack.error = 1'b0;
        assign core_iram_ack.rdata = iram_rdata;
    `endif

    // -----------------------------------
    //  L1 Instruction RAM
    // -----------------------------------
    logic [31:0] iram_addr_offset;
    assign iram_addr_offset = iram_addr - SOPHON_PKG::ITCM_BASE;

    //16K*32bit=64K
    TCM_WRAP 
    #(
        .DATA_WIDTH ( 32                              ) ,
        .DEPTH      ( SOPHON_PKG::ITCM_SIZE / (32/8)  )   // in DATA_WIDTH
    )
    U_ITCM
    (
         .clk_i   ( clk_i                                               )
        ,.en_i    ( iram_req                                            )
        ,.addr_i  ( iram_addr_offset[$clog2(SOPHON_PKG::ITCM_SIZE)-1:0] ) // in byte
        ,.wdata_i ( iram_wdata                                          ) 
        ,.we_i    ( iram_we                                             )
        ,.be_i    ( iram_be                                             )
        ,.rdata_o ( iram_rdata                                          )
    );


    // ----------------------------------------------------------------------
    //  Data RAM
    // ----------------------------------------------------------------------
    logic               dram_req;
    logic [31:0]        dram_addr;
    logic [31:0]        dram_rdata;
    logic [31:0]        dram_wdata;
    logic [3:0]         dram_be;
    logic               dram_we;

    // -----------------------------------
    //  Data arbiter
    // -----------------------------------
    `ifdef SOPHON_EXT_ACCESS

        DATA_ITF_ARBITER U_DATA_ITF_ARBITER (
             .core_dram_req ( core_dram_req ) 
            ,.core_dram_ack ( core_dram_ack ) 
            ,.ext_dram_req  ( ext_dram_req  ) 
            ,.ext_dram_ack  ( ext_dram_ack  ) 
            ,.dram_req      ( dram_req      ) 
            ,.dram_addr     ( dram_addr     ) 
            ,.dram_wdata    ( dram_wdata    ) 
            ,.dram_we       ( dram_we       ) 
            ,.dram_be       ( dram_be       ) 
            ,.dram_rdata    ( dram_rdata    ) 
        );

    `else
        assign dram_req            = core_dram_req.req;
        assign dram_addr           = core_dram_req.addr;
        assign dram_wdata          = core_dram_req.wdata;
        assign dram_we             = core_dram_req.we;
        assign dram_be             = core_dram_req.strb;
        assign core_dram_ack.ack   = core_dram_req.req; 
        assign core_dram_ack.error = 1'b0; // TODO: if addr from core out of DTCM range 
        assign core_dram_ack.rdata = dram_rdata;
    `endif

    // -----------------------------------
    //  L1 Data RAM
    // -----------------------------------
    logic [31:0] dram_addr_offset;
    assign dram_addr_offset = dram_addr - SOPHON_PKG::DTCM_BASE;

    //16K*32bit=64K
    TCM_WRAP 
    #(
        .DATA_WIDTH ( 32                              ),
        .DEPTH      ( SOPHON_PKG::DTCM_SIZE / (32/8)  )  // in DATA_WIDTH
    )
    U_DTCM
    (
         .clk_i   ( clk_neg_i                                            ) // use negedge clock to make l1 dram access time = 1 cycle
        ,.en_i    ( dram_req                                             )
        ,.addr_i  ( dram_addr_offset[ $clog2(SOPHON_PKG::DTCM_SIZE)-1:0] ) // in byte
        ,.wdata_i ( dram_wdata                                           )
        ,.we_i    ( dram_we                                              )
        ,.be_i    ( dram_be                                              )
        ,.rdata_o ( dram_rdata                                           )
    );

endmodule

