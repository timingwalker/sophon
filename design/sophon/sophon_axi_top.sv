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
// Create Date   : 2023-12-18 16:07:23
// Last Modified : 2024-07-29 10:55:25
// Description   : Top module of SOPHON with AXI interfaces
// ----------------------------------------------------------------------

module SOPHON_AXI_TOP #(
    parameter int unsigned                          HART_ID = 0
) (
     input logic                                    clk_i
    ,input logic                                    clk_neg_i
    ,input logic                                    rst_ni 
    ,input logic                                    rst_soft_ni 
    ,input logic [31:0]                             bootaddr_i
    ,input logic [31:0]                             hart_id_i
    ,input logic                                    irq_mei_i 
    ,input logic                                    irq_mti_i 
    ,input logic                                    irq_msi_i 
`ifdef SOPHON_RVDEBUG
    ,input  logic                                   dm_req_i
`endif
`ifdef SOPHON_EXT_ACCESS
    ,input  CC_ITF_PKG::axi_mst_side_d32_req_t      axi_slv_d32_req_i
    ,output CC_ITF_PKG::axi_mst_side_d32_resps_t    axi_slv_d32_rsp_o
`endif
`ifdef SOPHON_EXT_INST_DATA
    ,output CC_ITF_PKG::xbar_slv_port_d64_req_t     axi_mst_d32_req_o
    ,input  CC_ITF_PKG::xbar_slv_port_d64_resps_t   axi_mst_d32_rsp_i
`endif
`ifdef SOPHON_CLIC
    ,input  logic                                   clic_irq_req_i
    ,input  logic                                   clic_irq_shv_i
    ,input  logic [4:0]                             clic_irq_id_i
    ,input  logic [7:0]                             clic_irq_level_i
    ,output logic                                   clic_irq_ack_o
    ,output logic [7:0]                             clic_irq_intthresh_o
    ,output logic                                   clic_mnxti_clr_o
    ,output logic [4:0]                             clic_mnxti_id_o
`endif
`ifdef SOPHON_EEI_GPIO
    ,output logic [`FGPIO_NUM-1:0]                  gpio_dir_o
    ,input  logic [`FGPIO_NUM-1:0]                  gpio_in_val_i
    ,output logic [`FGPIO_NUM-1:0]                  gpio_out_val_o
`endif
`ifdef PROBE
    ,output logic [149:0]                           probe_o
`endif
);


`ifdef SOPHON_EXT_INST
    SOPHON_PKG::inst_req_t      ext_inst_inst_req;
    SOPHON_PKG::inst_ack_t      ext_inst_inst_ack;
    CC_ITF_PKG::reqrsp_d32_req_t    ext_inst_req;
    CC_ITF_PKG::reqrsp_d32_resps_t  ext_inst_rsp;
`endif
`ifdef SOPHON_EXT_DATA
    SOPHON_PKG::lsu_req_t       ext_data_lsu_req;
    SOPHON_PKG::lsu_ack_t       ext_data_lsu_ack;
    CC_ITF_PKG::reqrsp_d32_req_t    ext_data_req;
    CC_ITF_PKG::reqrsp_d32_resps_t  ext_data_rsp;
`endif


    // ----------------------------------------------------------------------
    //  Core
    // ----------------------------------------------------------------------
    SOPHON_TOP U_SOPHON_TOP (
         .clk_i                   ( clk_i                   )
        ,.clk_neg_i               ( clk_neg_i               )
        ,.rst_ni                  ( rst_ni                  )
        ,.rst_soft_ni             ( rst_soft_ni             )
        ,.bootaddr_i              ( bootaddr_i              )
        ,.hart_id_i               ( HART_ID[31:0]           )
        ,.irq_mei_i               ( irq_mei_i               )
        ,.irq_mti_i               ( irq_mti_i               )
        ,.irq_msi_i               ( irq_msi_i               )
        `ifdef SOPHON_RVDEBUG
        ,.dm_req_i                ( dm_req_i                )
        `endif
        ,.dummy_o                 (                         )
        `ifdef SOPHON_EXT_INST
        ,.inst_ext_req_o          ( ext_inst_inst_req.req   )
        ,.inst_ext_addr_o         ( ext_inst_inst_req.addr  )
        ,.inst_ext_ack_i          ( ext_inst_inst_ack.ack   )
        ,.inst_ext_rdata_i        ( ext_inst_inst_ack.rdata )
        ,.inst_ext_error_i        ( ext_inst_inst_ack.error )
        `endif
        `ifdef SOPHON_EXT_DATA
        ,.data_req_o              ( ext_data_lsu_req.req    )
        ,.data_we_o               ( ext_data_lsu_req.we     )
        ,.data_addr_o             ( ext_data_lsu_req.addr   )
        ,.data_wdata_o            ( ext_data_lsu_req.wdata  )
        ,.data_amo_o              ( ext_data_lsu_req.amo    )
        ,.data_strb_o             ( ext_data_lsu_req.strb   )
        ,.data_size_o             ( ext_data_lsu_req.size   )
        ,.data_valid_i            ( ext_data_lsu_ack.ack    )
        ,.data_error_i            ( ext_data_lsu_ack.error  )
        ,.data_rdata_i            ( ext_data_lsu_ack.rdata  )
        `endif
        `ifdef SOPHON_EXT_ACCESS
        ,.ext_req_i               ( ext_access_req.req      )
        ,.ext_we_i                ( ext_access_req.we       )
        ,.ext_strb_i              ( ext_access_req.strb     )
        ,.ext_addr_i              ( ext_access_req.addr     )
        ,.ext_wdata_i             ( ext_access_req.wdata    )
        ,.ext_ack_o               ( ext_access_ack.ack      )
        ,.ext_error_o             ( ext_access_ack.error    )
        ,.ext_rdata_o             ( ext_access_ack.rdata    )
        `endif
        `ifdef SOPHON_CLIC
        ,.clic_irq_req_i          ( clic_irq_req_i          )
        ,.clic_irq_shv_i          ( clic_irq_shv_i          )
        ,.clic_irq_id_i           ( clic_irq_id_i           )
        ,.clic_irq_level_i        ( clic_irq_level_i        )
        ,.clic_irq_ack_o          ( clic_irq_ack_o          )
        ,.clic_irq_intthresh_o    ( clic_irq_intthresh_o    )
        ,.clic_mnxti_clr_o        ( clic_mnxti_clr_o        )
        ,.clic_mnxti_id_o         ( clic_mnxti_id_o         )
        `endif
        `ifdef SOPHON_EEI_GPIO
        ,.gpio_dir_o              ( gpio_dir_o              )
        ,.gpio_in_val_i           ( gpio_in_val_i           )
        ,.gpio_out_val_o          ( gpio_out_val_o          )
        `endif
        `ifdef PROBE
        ,.probe_o                 (probe_o                  )
        `endif
    
    );


    // ----------------------------------------------------------------------
    //  Merge EXT_INST and EXT_DATA to an AXI master 
    // ----------------------------------------------------------------------
    //      inst interface (32b)     <-> reqrsp interface (32b) 
    //      data interface (lsu/32b) <-> reqrsp interface (32b) 
    //      Merge: inst(reqrsp/32b) + data(reqrsp/32b) to AXI master (32b)
    // ----------------------------------------------------------------------

`ifdef SOPHON_EXT_INST
    // ----------------------------------------------------------------------
    //      inst interface (32b) <-> reqrsp interface (32b) 
    // ----------------------------------------------------------------------
    logic                       is_ext_inst_pending;
    logic                       q_valid;
    logic [31:0]                q_addr;

    always @(posedge clk_i or negedge rst_ni) begin
    	if(~rst_ni) 
            is_ext_inst_pending <= 1'b0;
        else if ( ext_inst_req.q_valid & ext_inst_rsp.q_ready )
            is_ext_inst_pending <= 1'b1;
        else if ( ext_inst_req.p_ready & ext_inst_rsp.p_valid )
            is_ext_inst_pending <= 1'b0;
    end

    // break inst_req to optimize timing
    always @(posedge clk_i or negedge rst_ni) begin
    	if(~rst_ni) begin
            q_valid      <= 1'b0;
            q_addr       <= 32'd0;
        end
        else if (  ( ext_inst_req.q_valid & ext_inst_rsp.q_ready ) | is_ext_inst_pending ) begin
            q_valid      <= 1'b0;
            q_addr       <= q_addr;
        end
        else if ( ext_inst_inst_req.req ) begin
            q_valid      <= 1'b1;
            q_addr       <= ext_inst_inst_req.addr;
        end
    end
    assign ext_inst_req.q.addr  = q_addr;
    assign ext_inst_req.q_valid = q_valid;

    assign ext_inst_req.q.write = 1'b0;
    assign ext_inst_req.q.amo   = reqrsp_pkg::AMONone;
    assign ext_inst_req.q.data  = '0;
    assign ext_inst_req.q.strb  = '1;
    assign ext_inst_req.q.size  = 3'b010;
    assign ext_inst_req.p_ready = 1'b1;

    assign ext_inst_inst_ack.ack   = ext_inst_req.p_ready & ext_inst_rsp.p_valid;
    assign ext_inst_inst_ack.rdata = ext_inst_rsp.p.data;
    assign ext_inst_inst_ack.error = 1'b0;
`endif


`ifdef SOPHON_EXT_DATA
    // ----------------------------------------------------------------------
    //      data interface (lsu/32b) <-> reqrsp interface (32b) 
    // ----------------------------------------------------------------------
    logic is_ext_data_pending;

    always @(posedge clk_i or negedge rst_ni) begin
    	if(~rst_ni) 
            is_ext_data_pending <= 1'b0;
        else if (ext_data_req.q_valid && ext_data_rsp.q_ready )
            is_ext_data_pending <= 1'b1;
        else if ( ext_data_req.p_ready & ext_data_rsp.p_valid )
            is_ext_data_pending <= 1'b0;
    end

    assign ext_data_req.q_valid = ext_data_lsu_req.req & ~is_ext_data_pending;
    assign ext_data_req.q.addr  = ext_data_lsu_req.addr;
    assign ext_data_req.q.size  = {1'b0, 2'b10};
    assign ext_data_req.q.strb  = ext_data_lsu_req.strb;
    assign ext_data_req.q.data  = ext_data_lsu_req.wdata;
    assign ext_data_req.q.amo   = reqrsp_pkg::AMONone;
    assign ext_data_req.q.write = ext_data_lsu_req.we;
    assign ext_data_req.p_ready = ext_data_lsu_req.req;

    assign ext_data_lsu_ack.ack   = ext_data_rsp.p_valid & ext_data_req.p_ready;
    assign ext_data_lsu_ack.rdata = ext_data_rsp.p.data;
    assign ext_data_lsu_ack.error = ext_data_rsp.p.error;
`endif


`ifdef SOPHON_EXT_INST_DATA
    // ----------------------------------------------------------------------
    //      Merge: inst(reqrsp/32b) + data(reqrsp/32b) to AXI master (32b)
    // ----------------------------------------------------------------------
    CC_ITF_PKG::reqrsp_d32_req_t          outer_axi_req;
    CC_ITF_PKG::reqrsp_d32_resps_t        outer_axi_resp;
    CC_ITF_PKG::reqrsp_d32_req_t          outer_axi_req_iso;
    CC_ITF_PKG::reqrsp_d32_resps_t        outer_axi_resp_iso;

    CC_ITF_PKG::reqrsp_d32_req_t   [1:0]  slv_req_mux;
    CC_ITF_PKG::reqrsp_d32_resps_t [1:0]  slv_resp_mux;

    `ifdef SOPHON_EXT_INST
        assign slv_req_mux[1] = ext_inst_req;
        assign ext_inst_rsp   = slv_resp_mux[1];
    `else
        assign slv_req_mux[1].q_valid=1'b0;
        assign slv_req_mux[1].p_ready=1'b1;
    `endif

    `ifdef SOPHON_EXT_DATA
        assign slv_req_mux[0] = ext_data_req;
        assign ext_data_rsp   = slv_resp_mux[0];
    `else
        assign slv_req_mux[0].q_valid=1'b0;
        assign slv_req_mux[0].p_ready=1'b1;
    `endif

    // mux internal reqrsp interface
    reqrsp_mux #(
        .NrPorts    ( 2                              ) ,
        .AddrWidth  ( 32                             ) ,
        .DataWidth  ( 32                             ) ,
        .req_t      ( CC_ITF_PKG::reqrsp_d32_req_t   ) ,
        .rsp_t      ( CC_ITF_PKG::reqrsp_d32_resps_t ) 
    ) u_reqrsp_mux (
        .clk_i     ( clk_i          ) ,
        .rst_ni    ( rst_ni         ) ,
        .slv_req_i ( slv_req_mux    ) ,
        .slv_rsp_o ( slv_resp_mux   ) ,
        .mst_req_o ( outer_axi_req  ) ,
        .mst_rsp_i ( outer_axi_resp ) ,
        .idx_o     (                ) 
    );

    // cut combinational logic path to optimize timing
    reqrsp_iso #(
        .AddrWidth ( 32                             ) ,
        .DataWidth ( 32                             ) ,
        .req_t     ( CC_ITF_PKG::reqrsp_d32_req_t   ) ,
        .rsp_t     ( CC_ITF_PKG::reqrsp_d32_resps_t ) ,
        .BypassReq ( 1'b0                           ) ,
        .BypassRsp ( 1'b0                           ) 
    ) i_reqrsp_iso (
        .src_clk_i  ( clk_i              ) ,
        .src_rst_ni ( rst_ni             ) ,
        .src_req_i  ( outer_axi_req      ) ,
        .src_rsp_o  ( outer_axi_resp     ) ,
        .dst_clk_i  ( clk_i              ) ,
        .dst_rst_ni ( rst_ni             ) ,
        .dst_req_o  ( outer_axi_req_iso  ) ,
        .dst_rsp_i  ( outer_axi_resp_iso ) 
    );

    reqrsp_to_axi #(
        .DataWidth    ( CC_ITF_PKG::XBAR_DATA_WIDTH          ) ,
        .UserWidth    ( CC_ITF_PKG::XBAR_USER_WIDTH          ) ,
        .reqrsp_req_t ( CC_ITF_PKG::reqrsp_d32_req_t         ) ,
        .reqrsp_rsp_t ( CC_ITF_PKG::reqrsp_d32_resps_t       ) ,
        .axi_req_t    ( CC_ITF_PKG::axi_slv_side_d32_req_t   ) ,
        .axi_rsp_t    ( CC_ITF_PKG::axi_slv_side_d32_resps_t ) 
    ) i_reqrsp_to_axi_core (
        .clk_i        ( clk_i              ) ,
        .rst_ni       ( rst_ni             ) ,
        .user_i       ( '0                 ) ,
        .reqrsp_req_i ( outer_axi_req_iso  ) ,
        .reqrsp_rsp_o ( outer_axi_resp_iso ) ,
        .axi_req_o    ( axi_mst_d32_req_o  ) ,
        .axi_rsp_i    ( axi_mst_d32_rsp_i  ) 
    );
`endif


    // ----------------------------------------------------------------------
    //  External access path
    // ----------------------------------------------------------------------

`ifdef SOPHON_EXT_ACCESS
    // -----------------------------------
    //          32b data width
    //  AXI -> reqrsp -> memory -> lsu
    // -----------------------------------
    CC_ITF_PKG::reqrsp_d32_req_t      reqresp_d32_req;
    CC_ITF_PKG::reqrsp_d32_resps_t    reqresp_d32_rsp;

    SOPHON_PKG::lsu_req_t       ext_access_req;
    SOPHON_PKG::lsu_ack_t       ext_access_ack;

    logic             axi_mem_req   ;
    logic             axi_mem_gnt   ;
    logic             axi_mem_cs    ;
    logic             axi_mem_we    ;
    logic [3:0]       axi_mem_be    ;
    logic [31:0]      axi_addr      ;
    logic [31:0]      axi_mem_wdata ;
    logic [31:0]      axi_mem_rdata ;

    axi_to_reqrsp #(
        .axi_req_t    ( CC_ITF_PKG::axi_mst_side_d32_req_t   ) ,
        .axi_rsp_t    ( CC_ITF_PKG::axi_mst_side_d32_resps_t ) ,
        .AddrWidth    ( CC_ITF_PKG::REQRSP_ADDR_WIDTH        ) ,
        .DataWidth    ( 32                                   ) ,
        .IdWidth      ( CC_ITF_PKG::XBAR_MST_PORT_ID_WIDTH   ) ,
        .BufDepth     ( 1                                    ) ,
        .reqrsp_req_t ( CC_ITF_PKG::reqrsp_d32_req_t         ) ,
        .reqrsp_rsp_t ( CC_ITF_PKG::reqrsp_d32_resps_t       ) 
    ) u_axi_to_reqrsp (
        .clk_i        ( clk_i             ) ,
        .rst_ni       ( rst_ni            ) ,
        .busy_o       (                   ) ,
        .axi_req_i    ( axi_slv_d32_req_i ) ,
        .axi_rsp_o    ( axi_slv_d32_rsp_o ) , 
        .reqrsp_req_o ( reqresp_d32_req   ) ,
        .reqrsp_rsp_i ( reqresp_d32_rsp   ) 
    );

    REQRSP_TO_MEM #(
        .req_t      ( CC_ITF_PKG::reqrsp_d32_req_t   ) ,
        .resp_t     ( CC_ITF_PKG::reqrsp_d32_resps_t ) ,
        .DATA_WIDTH ( 32                             ) ,
        .ADDR_WIDTH ( 32                             ) 
    ) u_reqrsp_to_mem 
    (
        .clk_i     ( clk_i           ) ,
        .rst_ni    ( rst_ni          ) ,
        .req_i     ( reqresp_d32_req ) ,
        .resp_o    ( reqresp_d32_rsp ) ,
        .mem_req   ( axi_mem_req     ) ,
        .mem_gnt   ( axi_mem_gnt     ) , // AXI ports has highest priority
        .mem_cs    ( axi_mem_cs      ) ,
        .mem_we    ( axi_mem_we      ) ,
        .mem_be    ( axi_mem_be      ) ,
        .mem_addr  ( axi_addr        ) ,
        .mem_wdata ( axi_mem_wdata   ) ,
        .mem_rdata ( axi_mem_rdata   ) 
    );

    assign ext_access_req.req   = axi_mem_req;
    assign ext_access_req.we    = axi_mem_we;
    assign ext_access_req.strb  = axi_mem_be;
    assign ext_access_req.addr  = axi_addr;
    assign ext_access_req.wdata = axi_mem_wdata;
    assign axi_mem_gnt          = ext_access_ack.ack;
    // mem interface: rdata return in the next cycle after cs
    always @(posedge clk_i or negedge rst_ni) begin
    	if(~rst_ni) 
            axi_mem_rdata <= 32'd0;
        else if (axi_mem_cs & ~axi_mem_we)
            axi_mem_rdata <= ext_access_ack.rdata;
    end
`endif

endmodule

