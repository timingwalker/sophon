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
// Last Modified : 2024-08-05 15:12:33
// Description   : 
// ----------------------------------------------------------------------

module AXI_INTERCONNECT (
     input logic                        clk_i
    ,input logic                        rst_ni
    ,input logic                        testmode_i
    // XBAR: AXI Slave Port
    ,input  CC_ITF_PKG::xbar_slv_port_d64_req_t   [2:0] xbar_slv_port_req_i
    ,output CC_ITF_PKG::xbar_slv_port_d64_resps_t [2:0] xbar_slv_port_rsp_o
    // XBAR: AXI Master Port
    ,output CC_ITF_PKG::xbar_mst_port_d64_req_t   [2:0] xbar_mst_port_req_o
    ,input  CC_ITF_PKG::xbar_mst_port_d64_resps_t [2:0] xbar_mst_port_rsp_i
    // APB Port
    ,output CC_ITF_PKG::apb_d32_req_t   [3:0] apb_req_o
    ,input  CC_ITF_PKG::apb_d32_resps_t [3:0] apb_rsp_i
);


    logic rst_n;
    assign rst_n = rst_ni;


    // ----------------------------------------------------------------------
    //   xbar
    // ----------------------------------------------------------------------

    // XBAR Configuration
    localparam axi_pkg::xbar_cfg_t XBAR_CFG = '{
        NoSlvPorts          : CC_ITF_PKG::XBAR_SLV_PORT_NUM, 
        NoMstPorts          : CC_ITF_PKG::XBAR_MST_PORT_NUM,
        MaxMstTrans         : 4,
        MaxSlvTrans         : 4,
        FallThrough         : 1'b0,
        LatencyMode         : axi_pkg::CUT_MST_PORTS,
        AxiIdWidthSlvPorts  : CC_ITF_PKG::XBAR_SLV_PORT_ID_WIDTH,
        AxiIdUsedSlvPorts   : CC_ITF_PKG::XBAR_SLV_PORT_ID_WIDTH,
        UniqueIds           : 0,
        AxiAddrWidth        : CC_ITF_PKG::XBAR_ADDR_WIDTH,
        AxiDataWidth        : CC_ITF_PKG::XBAR_DATA_WIDTH,
        NoAddrRules         : CC_ITF_PKG::XBAR_MST_PORT_NUM
    };

    // XBAR: AXI Slave Port
    CC_ITF_PKG::xbar_slv_port_d64_req_t   [XBAR_CFG.NoSlvPorts-1:0] axi_xbar_slv_port_req;
    CC_ITF_PKG::xbar_slv_port_d64_resps_t [XBAR_CFG.NoSlvPorts-1:0] axi_xbar_slv_port_rsp;

    // XBAR: AXI Master Port
    CC_ITF_PKG::xbar_mst_port_d64_req_t   [XBAR_CFG.NoMstPorts-1:0] axi_xbar_mst_port_req;
    CC_ITF_PKG::xbar_mst_port_d64_resps_t [XBAR_CFG.NoMstPorts-1:0] axi_xbar_mst_port_rsp;

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
        .Cfg             ( XBAR_CFG                             ) ,
        .ATOPs           ( 0                                    ) ,
        .Connectivity    ( '1                                   ) ,
        .slv_aw_chan_t   ( CC_ITF_PKG::xbar_slv_port_aw_t       ) ,
        .mst_aw_chan_t   ( CC_ITF_PKG::xbar_mst_port_aw_t       ) ,
        .w_chan_t        ( CC_ITF_PKG::xbar_w_chan_t            ) ,
        .slv_b_chan_t    ( CC_ITF_PKG::xbar_slv_port_b_t        ) ,
        .mst_b_chan_t    ( CC_ITF_PKG::xbar_mst_port_b_t        ) ,
        .slv_ar_chan_t   ( CC_ITF_PKG::xbar_slv_port_ar_t       ) ,
        .mst_ar_chan_t   ( CC_ITF_PKG::xbar_mst_port_ar_t       ) ,
        .slv_r_chan_t    ( CC_ITF_PKG::xbar_slv_port_r_t        ) ,
        .mst_r_chan_t    ( CC_ITF_PKG::xbar_mst_port_r_t        ) ,
        .slv_req_t       ( CC_ITF_PKG::xbar_slv_port_d64_req_t   ) ,
        .slv_resp_t      ( CC_ITF_PKG::xbar_slv_port_d64_resps_t ) ,
        .mst_req_t       ( CC_ITF_PKG::xbar_mst_port_d64_req_t   ) ,
        .mst_resp_t      ( CC_ITF_PKG::xbar_mst_port_d64_resps_t ) ,
        .rule_t          ( CC_ITF_PKG::xbar_rule_t              ) 
    ) u_xbar (
        .clk_i                 ( clk_i                 ) ,
        .rst_ni                ( rst_n                 ) ,
        .test_i                ( testmode_i            ) ,
        .slv_ports_req_i       ( axi_xbar_slv_port_req ) ,
        .slv_ports_resp_o      ( axi_xbar_slv_port_rsp ) ,
        .mst_ports_req_o       ( axi_xbar_mst_port_req ) ,
        .mst_ports_resp_i      ( axi_xbar_mst_port_rsp ) ,
        .addr_map_i            ( axi_addr_map          ) ,
        .en_default_mst_port_i ( '0                    ) ,
        .default_mst_port_i    ( '0                    ) 
    );




    // ----------------------------------------------------------------------
    //  Input/Output ports
    // ----------------------------------------------------------------------

    // XBAR: AXI Slave Port 0-2
    assign xbar_slv_port_rsp_o[0] = axi_xbar_slv_port_rsp[0];
    assign xbar_slv_port_rsp_o[1] = axi_xbar_slv_port_rsp[1];
    assign xbar_slv_port_rsp_o[2] = axi_xbar_slv_port_rsp[2];
    
    assign axi_xbar_slv_port_req[0] = xbar_slv_port_req_i[0];
    assign axi_xbar_slv_port_req[1] = xbar_slv_port_req_i[1];
    assign axi_xbar_slv_port_req[2] = xbar_slv_port_req_i[2];

    // XBAR: AXI Master Port 0-2
    assign xbar_mst_port_req_o[0] = axi_xbar_mst_port_req[0];
    assign xbar_mst_port_req_o[1] = axi_xbar_mst_port_req[1];
    assign xbar_mst_port_req_o[2] = axi_xbar_mst_port_req[2];
    
    assign axi_xbar_mst_port_rsp[0] = xbar_mst_port_rsp_i[0];
    assign axi_xbar_mst_port_rsp[1] = xbar_mst_port_rsp_i[1];
    assign axi_xbar_mst_port_rsp[2] = xbar_mst_port_rsp_i[2];

    // -----------------------------------
    // APB port
    // -----------------------------------
    localparam APB_SLV_NUM  = 4;
    CC_ITF_PKG::apb_d32_req_t   [APB_SLV_NUM-1:0] apb_req;
    CC_ITF_PKG::apb_d32_resps_t [APB_SLV_NUM-1:0] apb_resp;

    assign apb_req_o[0] = apb_req[0];
    assign apb_req_o[1] = apb_req[1];
    assign apb_req_o[2] = apb_req[2];
    assign apb_req_o[3] = apb_req[3];
    
    assign apb_resp[0] = apb_rsp_i[0];
    assign apb_resp[1] = apb_rsp_i[1];
    assign apb_resp[2] = apb_rsp_i[2];
    assign apb_resp[3] = apb_rsp_i[3];





    // ----------------------------------------------------------------------
    // XBAR Master Port 3 (AXI64b) -> AXI 32b ->  AXI lite 32b -> APB 32b
    // ----------------------------------------------------------------------

    // -----------------------------------
    // AXI 64b -> AXI 32b
    // -----------------------------------
    CC_ITF_PKG::axi_mst_side_d32_req_t   axi_mst_side_d32_req;
    CC_ITF_PKG::axi_mst_side_d32_resps_t axi_mst_side_d32_rsp;

    axi_dw_converter #(
        .AxiMaxReads         ( 4                                   ) ,
        .AxiSlvPortDataWidth ( CC_ITF_PKG::XBAR_DATA_WIDTH           ) ,
        .AxiMstPortDataWidth ( 32                                  ) ,
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
        .clk_i         ( clk_i                    ) ,
        .rst_ni        ( rst_n                    ) ,
        // slave port
        .slv_req_i     ( axi_xbar_mst_port_req[3] ) ,
        .slv_resp_o    ( axi_xbar_mst_port_rsp[3] ) ,
        // master port
        .mst_req_o     ( axi_mst_side_d32_req     ) ,
        .mst_resp_i    ( axi_mst_side_d32_rsp     ) 
    );

    // -----------------------------------
    // AXI 32b to AXI_lite
    // -----------------------------------
    CC_ITF_PKG::axi_lite_mst_side_d32_req_t      axi_lite_req;
    CC_ITF_PKG::axi_lite_mst_side_d32_resps_t    axi_lite_resps;

    axi_to_axi_lite #(
        .AxiAddrWidth    ( CC_ITF_PKG::XBAR_ADDR_WIDTH               ) ,
        .AxiDataWidth    ( 32                                      ) ,
        .AxiIdWidth      ( CC_ITF_PKG::XBAR_MST_PORT_ID_WIDTH        ) ,
        .AxiUserWidth    ( CC_ITF_PKG::XBAR_USER_WIDTH               ) ,
        .AxiMaxWriteTxns ( 4                                       ) ,
        .AxiMaxReadTxns  ( 4                                       ) ,
        .FallThrough     ( 0                                       ) ,  // FIFOs in Fall through mode in ID reflect
        .full_req_t      ( CC_ITF_PKG::axi_mst_side_d32_req_t        ) ,
        .full_resp_t     ( CC_ITF_PKG::axi_mst_side_d32_resps_t      ) ,
        .lite_req_t      ( CC_ITF_PKG::axi_lite_mst_side_d32_req_t   ) ,
        .lite_resp_t     ( CC_ITF_PKG::axi_lite_mst_side_d32_resps_t ) 
    ) u_axi_to_axi_lite (
        .clk_i                       ( clk_i                ) ,
        .rst_ni                      ( rst_n                ) ,
        .test_i                      ( testmode_i           ) ,
        // slave port full AXI4+ATOP
        .slv_req_i                   ( axi_mst_side_d32_req ) ,
        .slv_resp_o                  ( axi_mst_side_d32_rsp ) ,
        // master port AXI4-Lite
        .mst_req_o                   ( axi_lite_req         ) ,
        .mst_resp_i                  ( axi_lite_resps       ) 
    );


    // -----------------------------------
    // AXI lite to APB
    // -----------------------------------
    localparam APB_RULE_NUM = APB_SLV_NUM;
    
    localparam CC_ITF_PKG::xbar_rule_t [APB_RULE_NUM-1:0] apb_addr_map = '{
        // Sys CFG REG
        '{idx: 32'd0, start_addr: 32'h0600_0000, end_addr: 32'h0600_4000},
        // UART
        '{idx: 32'd1, start_addr: 32'h0600_4000, end_addr: 32'h0600_5000},
        // Clint
        '{idx: 32'd2, start_addr: 32'h0600_5000, end_addr: 32'h0600_6000},
        // CLIC
        '{idx: 32'd3, start_addr: 32'h0702_0000, end_addr: 32'h0703_0000}
    };

    axi_lite_to_apb #(
        .NoApbSlaves      ( APB_SLV_NUM                               ) ,
        .NoRules          ( APB_RULE_NUM                              ) ,
        .AddrWidth        ( CC_ITF_PKG::XBAR_ADDR_WIDTH               ) ,
        .DataWidth        ( 32                                        ) ,
        .PipelineRequest  ( 1'b0                                      ) ,
        .PipelineResponse ( 1'b0                                      ) ,
        .axi_lite_req_t   ( CC_ITF_PKG::axi_lite_mst_side_d32_req_t   ) ,
        .axi_lite_resp_t  ( CC_ITF_PKG::axi_lite_mst_side_d32_resps_t ) ,
        .apb_req_t        ( CC_ITF_PKG::apb_d32_req_t                 ) ,
        .apb_resp_t       ( CC_ITF_PKG::apb_d32_resps_t               ) ,
        .rule_t           ( CC_ITF_PKG::xbar_rule_t                   ) 
    ) u_axi_lite_to_apb(
        .clk_i           ( clk_i          ) ,
        .rst_ni          ( rst_n          ) ,
        .axi_lite_req_i  ( axi_lite_req   ) ,
        .axi_lite_resp_o ( axi_lite_resps ) ,
        .apb_req_o       ( apb_req        ) ,
        .apb_resp_i      ( apb_resp       ) ,
        .addr_map_i      ( apb_addr_map   ) 
    );




endmodule

