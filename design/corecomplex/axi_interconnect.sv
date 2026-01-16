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
// Last Modified : 2026-01-14 11:21:42
// Description   : 
// ----------------------------------------------------------------------

module AXI_INTERCONNECT (
     input logic                  clk_i
    ,input logic                  rst_ni
    ,input logic                  testmode_i
    // XBAR: AXI Slave Port
    ,input  CC_ITF_PKG::xbar_port_d32_slv_id_req_t   [CC_ITF_PKG::XBAR_SLV_PORT_NUM-1:0] xbar_slv_port_req_i
    ,output CC_ITF_PKG::xbar_port_d32_slv_id_resps_t [CC_ITF_PKG::XBAR_SLV_PORT_NUM-1:0] xbar_slv_port_resps_o
    // XBAR: AXI Master Port, one is occupied by the APB port
    ,output CC_ITF_PKG::xbar_port_d32_mst_id_req_t   [CC_ITF_PKG::XBAR_MST_PORT_NUM-2:0] xbar_mst_port_req_o
    ,input  CC_ITF_PKG::xbar_port_d32_mst_id_resps_t [CC_ITF_PKG::XBAR_MST_PORT_NUM-2:0] xbar_mst_port_resps_i
    // APB Port
    ,output CC_ITF_PKG::apb_d32_req_t                [CC_ITF_PKG::APB_SLV_NUM-1:0] apb_req_o
    ,input  CC_ITF_PKG::apb_d32_resps_t              [CC_ITF_PKG::APB_SLV_NUM-1:0] apb_resps_i
);


    // ----------------------------------------------------------------------
    //   xbar
    // ----------------------------------------------------------------------

    // XBAR Configuration
    localparam axi_pkg::xbar_cfg_t XBAR_CFG = '{
        NoSlvPorts          : CC_ITF_PKG::XBAR_SLV_PORT_NUM, 
        NoMstPorts          : CC_ITF_PKG::XBAR_MST_PORT_NUM,
        MaxMstTrans         : CC_ITF_PKG::XBAR_MAX_MST_TRANS,
        MaxSlvTrans         : CC_ITF_PKG::XBAR_MAX_SLV_TRANS,
        FallThrough         : 1'b0,
        LatencyMode         : axi_pkg::CUT_MST_PORTS,
        AxiIdWidthSlvPorts  : CC_ITF_PKG::XBAR_SLV_ID_WIDTH,
        AxiIdUsedSlvPorts   : CC_ITF_PKG::XBAR_SLV_ID_WIDTH,
        UniqueIds           : 0,
        AxiAddrWidth        : CC_ITF_PKG::XBAR_ADDR_WIDTH,
        AxiDataWidth        : CC_ITF_PKG::XBAR_DATA_WIDTH,
        NoAddrRules         : CC_ITF_PKG::XBAR_MST_PORT_NUM
    };

    // XBAR: AXI Slave Port
    CC_ITF_PKG::xbar_port_d32_slv_id_req_t   [XBAR_CFG.NoSlvPorts-1:0] xbar_slv_port_req;
    CC_ITF_PKG::xbar_port_d32_slv_id_resps_t [XBAR_CFG.NoSlvPorts-1:0] xbar_slv_port_resps;
    // XBAR: AXI Master Port
    CC_ITF_PKG::xbar_port_d32_mst_id_req_t   [XBAR_CFG.NoMstPorts-1:0] xbar_mst_port_req;
    CC_ITF_PKG::xbar_port_d32_mst_id_resps_t [XBAR_CFG.NoMstPorts-1:0] xbar_mst_port_resps;

    CC_ITF_PKG::xbar_rule_t [XBAR_CFG.NoAddrRules-1:0] axi_addr_map;
    assign axi_addr_map = '{
        '{  // Core: L1 inst/data RAM
            idx:        'd0, 
            start_addr: CC_CFG_PKG::CORE_BASE,
            end_addr:   CC_CFG_PKG::CORE_END
        },
        '{  // Debug Module
            idx:        'd1,    
            start_addr: CC_CFG_PKG::EXT_DM_BASE,
            end_addr:   CC_CFG_PKG::EXT_DM_END
        },
        '{  // external memory access
            idx:        'd2,  
            start_addr: CC_CFG_PKG::EXT_MEM_BASE,
            end_addr:   CC_CFG_PKG::EXT_MEM_END
        },
        '{  // APB port    
            idx:        'd3,    
            start_addr: CC_CFG_PKG::APB_BASE,
            end_addr:   CC_CFG_PKG::APB_END
        }
    };

    axi_xbar #(
        .Cfg           ( XBAR_CFG                                 ) ,
        .ATOPs         ( 0                                        ) ,
        .Connectivity  ( '1                                       ) ,
        .slv_aw_chan_t ( CC_ITF_PKG::xbar_aw_chan_slv_id_t        ) ,
        .mst_aw_chan_t ( CC_ITF_PKG::xbar_aw_chan_mst_id_t        ) ,
        .w_chan_t      ( CC_ITF_PKG::xbar_w_chan_t                ) ,
        .slv_b_chan_t  ( CC_ITF_PKG::xbar_b_chan_slv_id_t         ) ,
        .mst_b_chan_t  ( CC_ITF_PKG::xbar_b_chan_mst_id_t         ) ,
        .slv_ar_chan_t ( CC_ITF_PKG::xbar_ar_chan_slv_id_t        ) ,
        .mst_ar_chan_t ( CC_ITF_PKG::xbar_ar_chan_mst_id_t        ) ,
        .slv_r_chan_t  ( CC_ITF_PKG::xbar_r_chan_slv_id_t         ) ,
        .mst_r_chan_t  ( CC_ITF_PKG::xbar_r_chan_mst_id_t         ) ,
        .slv_req_t     ( CC_ITF_PKG::xbar_port_d32_slv_id_req_t   ) ,
        .slv_resp_t    ( CC_ITF_PKG::xbar_port_d32_slv_id_resps_t ) ,
        .mst_req_t     ( CC_ITF_PKG::xbar_port_d32_mst_id_req_t   ) ,
        .mst_resp_t    ( CC_ITF_PKG::xbar_port_d32_mst_id_resps_t ) ,
        .rule_t        ( CC_ITF_PKG::xbar_rule_t                  ) 
    ) u_xbar (
        .clk_i                 ( clk_i               ) ,
        .rst_ni                ( rst_ni              ) ,
        .test_i                ( testmode_i          ) ,
        .slv_ports_req_i       ( xbar_slv_port_req   ) ,
        .slv_ports_resp_o      ( xbar_slv_port_resps ) ,
        .mst_ports_req_o       ( xbar_mst_port_req   ) ,
        .mst_ports_resp_i      ( xbar_mst_port_resps ) ,
        .addr_map_i            ( axi_addr_map        ) ,
        .en_default_mst_port_i ( '0                  ) ,
        .default_mst_port_i    ( '0                  ) 
    );


    // ----------------------------------------------------------------------
    // XBAR Master Port 3 : AXI 32b ->  AXI lite 32b -> APB 32b
    // ----------------------------------------------------------------------

    // -----------------------------------
    // AXI 32b to AXI_lite
    // -----------------------------------
    CC_ITF_PKG::axi_lite_d32_req_t      axi_lite_req;
    CC_ITF_PKG::axi_lite_d32_resps_t    axi_lite_resps;

    axi_to_axi_lite #(
        .AxiAddrWidth    ( CC_ITF_PKG::XBAR_ADDR_WIDTH              ) ,
        .AxiDataWidth    ( CC_ITF_PKG::XBAR_DATA_WIDTH              ) ,
        .AxiIdWidth      ( CC_ITF_PKG::XBAR_MST_ID_WIDTH            ) ,
        .AxiUserWidth    ( CC_ITF_PKG::XBAR_USER_WIDTH              ) ,
        .AxiMaxWriteTxns ( CC_ITF_PKG::XBAR_MAX_MST_TRANS           ) ,
        .AxiMaxReadTxns  ( CC_ITF_PKG::XBAR_MAX_SLV_TRANS           ) ,
        .FallThrough     ( 0                                        ) ,  
        .full_req_t      ( CC_ITF_PKG::xbar_port_d32_mst_id_req_t   ) ,
        .full_resp_t     ( CC_ITF_PKG::xbar_port_d32_mst_id_resps_t ) ,
        .lite_req_t      ( CC_ITF_PKG::axi_lite_d32_req_t           ) ,
        .lite_resp_t     ( CC_ITF_PKG::axi_lite_d32_resps_t         ) 
    ) u_axi_to_axi_lite (
        .clk_i                       ( clk_i                  ) ,
        .rst_ni                      ( rst_ni                 ) ,
        .test_i                      ( testmode_i             ) ,
        // slave port full AXI4+ATOP
        .slv_req_i                   ( xbar_mst_port_req[3]   ) ,
        .slv_resp_o                  ( xbar_mst_port_resps[3] ) ,
        // master port AXI4-Lite
        .mst_req_o                   ( axi_lite_req           ) ,
        .mst_resp_i                  ( axi_lite_resps         ) 
    );

    // -----------------------------------
    // AXI lite to APB
    // -----------------------------------
    localparam APB_RULE_NUM = CC_ITF_PKG::APB_SLV_NUM;

    CC_ITF_PKG::apb_d32_req_t   [CC_ITF_PKG::APB_SLV_NUM-1:0] apb_req;
    CC_ITF_PKG::apb_d32_resps_t [CC_ITF_PKG::APB_SLV_NUM-1:0] apb_resps;
    
    localparam CC_ITF_PKG::xbar_rule_t [APB_RULE_NUM-1:0] apb_addr_map = '{
        // Sys CFG REG
        '{idx: 32'd0, start_addr: 32'h0600_0000, end_addr: 32'h0600_4000},
        // UART
        '{idx: 32'd1, start_addr: 32'h0600_4000, end_addr: 32'h0600_5000},
        // Clint
        '{idx: 32'd2, start_addr: 32'h0600_5000, end_addr: 32'h0600_6000},
        // CLIC
        '{idx: 32'd3, start_addr: 32'h0702_0000, end_addr: 32'h0703_0000},
        // PLIC
        '{idx: 32'd4, start_addr: 32'h0704_0000, end_addr: 32'h0800_0000}
    };

    axi_lite_to_apb #(
        .NoApbSlaves      ( CC_ITF_PKG::APB_SLV_NUM          ) ,
        .NoRules          ( APB_RULE_NUM                     ) ,
        .AddrWidth        ( CC_ITF_PKG::XBAR_ADDR_WIDTH      ) ,
        .DataWidth        ( CC_ITF_PKG::XBAR_DATA_WIDTH      ) ,
        .PipelineRequest  ( 1'b0                             ) ,
        .PipelineResponse ( 1'b0                             ) ,
        .axi_lite_req_t   ( CC_ITF_PKG::axi_lite_d32_req_t   ) ,
        .axi_lite_resp_t  ( CC_ITF_PKG::axi_lite_d32_resps_t ) ,
        .apb_req_t        ( CC_ITF_PKG::apb_d32_req_t        ) ,
        .apb_resp_t       ( CC_ITF_PKG::apb_d32_resps_t      ) ,
        .rule_t           ( CC_ITF_PKG::xbar_rule_t          ) 
    ) u_axi_lite_to_apb(
        .clk_i           ( clk_i          ) ,
        .rst_ni          ( rst_ni         ) ,
        .axi_lite_req_i  ( axi_lite_req   ) ,
        .axi_lite_resp_o ( axi_lite_resps ) ,
        .apb_req_o       ( apb_req        ) ,
        .apb_resp_i      ( apb_resps      ) ,
        .addr_map_i      ( apb_addr_map   ) 
    );


    // ----------------------------------------------------------------------
    //  Input/Output ports
    // ----------------------------------------------------------------------

    // XBAR: AXI Slave Port 0-2
    assign xbar_slv_port_resps_o[0] = xbar_slv_port_resps[0];
    assign xbar_slv_port_resps_o[1] = xbar_slv_port_resps[1];
    assign xbar_slv_port_resps_o[2] = xbar_slv_port_resps[2];
    
    assign xbar_slv_port_req[0] = xbar_slv_port_req_i[0];
    assign xbar_slv_port_req[1] = xbar_slv_port_req_i[1];
    assign xbar_slv_port_req[2] = xbar_slv_port_req_i[2];

    // XBAR: AXI Master Port 0-2
    assign xbar_mst_port_req_o[0] = xbar_mst_port_req[0];
    assign xbar_mst_port_req_o[1] = xbar_mst_port_req[1];
    assign xbar_mst_port_req_o[2] = xbar_mst_port_req[2];
    
    assign xbar_mst_port_resps[0] = xbar_mst_port_resps_i[0];
    assign xbar_mst_port_resps[1] = xbar_mst_port_resps_i[1];
    assign xbar_mst_port_resps[2] = xbar_mst_port_resps_i[2];

    // APB port
    assign apb_req_o[0] = apb_req[0];
    assign apb_req_o[1] = apb_req[1];
    assign apb_req_o[2] = apb_req[2];
    assign apb_req_o[3] = apb_req[3];
    assign apb_req_o[4] = apb_req[4];
    
    assign apb_resps[0] = apb_resps_i[0];
    assign apb_resps[1] = apb_resps_i[1];
    assign apb_resps[2] = apb_resps_i[2];
    assign apb_resps[3] = apb_resps_i[3];
    assign apb_resps[4] = apb_resps_i[4];


endmodule

