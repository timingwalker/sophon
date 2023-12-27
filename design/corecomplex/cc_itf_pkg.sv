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
// Create Date   : 2022-08-10 11:37:09
// Last Modified : 2023-12-27 14:44:23
// Description   : CoreComplex interface define
// ----------------------------------------------------------------------

`include "axi/typedef.svh"
`include "axi/assign.svh"

package CC_ITF_PKG;

  // ----------------------------------------------------------------------
  //  XBAR parameter
  // ----------------------------------------------------------------------
  // xbar slave port number = AXI master number
  localparam int unsigned XBAR_SLV_PORT_NUM = 3; 
  // xbar master port number = AXI slave number
  localparam int unsigned XBAR_MST_PORT_NUM = 4; 
  // APB port number
  localparam APB_SLV_NUM  = 3;

  // -----------------------------------
  //  DON'T CHANGE these values
  // -----------------------------------
  // define xbar interface width 
  localparam int unsigned XBAR_ADDR_WIDTH   = 32;
  localparam int unsigned XBAR_DATA_WIDTH   = 64;
  localparam int unsigned XBAR_STRB_WIDTH   = XBAR_DATA_WIDTH / 8;
  localparam int unsigned XBAR_USER_WIDTH   = 2; // TODO: set to 0 ?
  localparam int unsigned XBAR_SLV_PORT_ID_WIDTH = 4;
  // transaction from xbar slave port will increase id width
  localparam int unsigned XBAR_MST_PORT_ID_WIDTH = $clog2(XBAR_SLV_PORT_NUM) + XBAR_SLV_PORT_ID_WIDTH;


  // ----------------------------------------------------------------------
  //  64b data width xbar AXI interface structure
  // ----------------------------------------------------------------------
  typedef logic [XBAR_SLV_PORT_ID_WIDTH-1:0] xbat_slv_port_id_t;
  typedef logic [XBAR_MST_PORT_ID_WIDTH-1:0] xbat_mst_port_id_t;
  typedef logic [XBAR_ADDR_WIDTH-1:0]   xbar_addr_t;
  typedef axi_pkg::xbar_rule_32_t       xbar_rule_t; 
  typedef logic [XBAR_DATA_WIDTH-1:0]   xbar_data_t;
  typedef logic [XBAR_STRB_WIDTH-1:0]   xbar_strb_t;
  typedef logic [XBAR_USER_WIDTH-1:0]   xbar_user_t;

  `AXI_TYPEDEF_W_CHAN_T(xbar_w_chan_t, xbar_data_t, xbar_strb_t, xbar_user_t)
  // XBAR slave port interface, using slave port id
  `AXI_TYPEDEF_AW_CHAN_T(xbar_slv_port_aw_t, xbar_addr_t, xbat_slv_port_id_t, xbar_user_t)
  `AXI_TYPEDEF_AR_CHAN_T(xbar_slv_port_ar_t, xbar_addr_t, xbat_slv_port_id_t, xbar_user_t)
  `AXI_TYPEDEF_B_CHAN_T(xbar_slv_port_b_t, xbat_slv_port_id_t, xbar_user_t)
  `AXI_TYPEDEF_R_CHAN_T(xbar_slv_port_r_t, xbar_data_t, xbat_slv_port_id_t, xbar_user_t)
  // XBAR master port interface, using extend master port id
  `AXI_TYPEDEF_AW_CHAN_T(xbar_mst_port_aw_t, xbar_addr_t, xbat_mst_port_id_t, xbar_user_t)
  `AXI_TYPEDEF_AR_CHAN_T(xbar_mst_port_ar_t, xbar_addr_t, xbat_mst_port_id_t, xbar_user_t)
  `AXI_TYPEDEF_B_CHAN_T(xbar_mst_port_b_t, xbat_mst_port_id_t, xbar_user_t)
  `AXI_TYPEDEF_R_CHAN_T(xbar_mst_port_r_t, xbar_data_t, xbat_mst_port_id_t, xbar_user_t)

  // Xbar Slave Port interface
  `AXI_TYPEDEF_REQ_T (xbar_slv_port_d64_req_t, xbar_slv_port_aw_t, xbar_w_chan_t, xbar_slv_port_ar_t)
  `AXI_TYPEDEF_RESP_T(xbar_slv_port_d64_resps_t, xbar_slv_port_b_t, xbar_slv_port_r_t)
  // Xbar Master Port interface, id width is extended
  `AXI_TYPEDEF_REQ_T (xbar_mst_port_d64_req_t, xbar_mst_port_aw_t, xbar_w_chan_t, xbar_mst_port_ar_t)
  `AXI_TYPEDEF_RESP_T(xbar_mst_port_d64_resps_t, xbar_mst_port_b_t, xbar_mst_port_r_t)


  // ----------------------------------------------------------------------
  //  XBAR Master side interface: 32b data width + master port id
  // ----------------------------------------------------------------------
  typedef logic [32-1:0]    axi_data_32b_t;
  typedef logic [32/8-1:0]  axi_strb_4b_t;

  `AXI_TYPEDEF_W_CHAN_T(axi_w_32b_t, axi_data_32b_t, axi_strb_4b_t, xbar_user_t)
  `AXI_TYPEDEF_R_CHAN_T(axi_r_32b_t, axi_data_32b_t, xbat_mst_port_id_t, xbar_user_t)

  `AXI_TYPEDEF_REQ_T(axi_mst_side_d32_req_t, xbar_mst_port_aw_t, axi_w_32b_t, xbar_mst_port_ar_t)
  `AXI_TYPEDEF_RESP_T(axi_mst_side_d32_resps_t, xbar_mst_port_b_t, axi_r_32b_t)


  // ----------------------------------------------------------------------
  //  XBAR Master side AXI LITE interface: 32b data width + master port id
  // ----------------------------------------------------------------------
  `AXI_LITE_TYPEDEF_AW_CHAN_T(lite_aw_chan_t, xbar_addr_t)
  `AXI_LITE_TYPEDEF_W_CHAN_T(lite_w_chan_t, axi_data_32b_t, axi_strb_4b_t)
  `AXI_LITE_TYPEDEF_B_CHAN_T(lite_b_chan_t)
  `AXI_LITE_TYPEDEF_AR_CHAN_T(lite_ar_chan_t, xbar_addr_t)
  `AXI_LITE_TYPEDEF_R_CHAN_T (lite_r_chan_t, axi_data_32b_t)

  `AXI_LITE_TYPEDEF_REQ_T(axi_lite_mst_side_d32_req_t, lite_aw_chan_t, lite_w_chan_t, lite_ar_chan_t)
  `AXI_LITE_TYPEDEF_RESP_T(axi_lite_mst_side_d32_resps_t, lite_b_chan_t, lite_r_chan_t)


  // ----------------------------------------------------------------------
  //  32b data width APB2.0/AMBA4 interface structure
  // ----------------------------------------------------------------------
  typedef struct packed {
    xbar_addr_t      paddr;
    axi_pkg::prot_t  pprot;  
    logic            psel;    
    logic            penable;
    logic            pwrite;
    axi_data_32b_t   pwdata;
    axi_strb_4b_t    pstrb;
  } apb_d32_req_t;

  typedef struct packed {
    logic  pready;
    axi_data_32b_t prdata;
    logic  pslverr;
  } apb_d32_resps_t;




  // ----------------------------------------------------------------------
  //  reqrsp interface structure
  // ----------------------------------------------------------------------

  localparam int unsigned REQRSP_ADDR_WIDTH = 32;
  localparam int unsigned REQRSP_DATA_WIDTH = 64;

  typedef logic [REQRSP_ADDR_WIDTH-1:0] addr_t;
  typedef logic [REQRSP_DATA_WIDTH-1:0] data_t;
  localparam int unsigned StrbWidth = REQRSP_DATA_WIDTH / 8;
  typedef logic [StrbWidth-1:0] strb_t;


  typedef struct packed {
    addr_t                  addr;
    logic                   write;
    reqrsp_pkg::amo_op_e    amo;
    data_t                  data;
    strb_t                  strb;
    reqrsp_pkg::size_t      size;
  } req_q_t;

  typedef struct packed {
    data_t                  data;
    logic                   error;
  } resps_p_t;

  typedef struct packed {
    req_q_t                 q;
    logic                   q_valid;
    logic                   p_ready;
  } reqrsp_req_t;

  typedef struct packed {
    logic                   q_ready;
    resps_p_t               p;
    logic                   p_valid;
  } reqrsp_resps_t;


  // ----------------------------------------------------------------------
  //  reqrsp interface structure: 32b data width
  // ----------------------------------------------------------------------

  typedef struct packed {
    addr_t                  addr;
    logic                   write;
    reqrsp_pkg::amo_op_e    amo;
    logic [31:0]                  data;
    strb_t                  strb;
    reqrsp_pkg::size_t      size;
  } req_q_d32_t;

  typedef struct packed {
    logic [31:0]                  data;
    logic                   error;
  } resps_p_d32_t;

  typedef struct packed {
    req_q_d32_t                 q;
    logic                   q_valid;
    logic                   p_ready;
  } reqrsp_d32_req_t;

  typedef struct packed {
    logic                   q_ready;
    resps_p_d32_t               p;
    logic                   p_valid;
  } reqrsp_d32_resps_t;


    //TODO check SINGLE_REQ in debugger
    typedef enum logic { SINGLE_REQ, CACHE_LINE_REQ } ad_req_t;

    // --------------------
    // Atomics
    // --------------------
    typedef enum logic [3:0] {
        AMO_NONE =4'b0000,
        AMO_LR   =4'b0001,
        AMO_SC   =4'b0010,
        AMO_SWAP =4'b0011,
        AMO_ADD  =4'b0100,
        AMO_AND  =4'b0101,
        AMO_OR   =4'b0110,
        AMO_XOR  =4'b0111,
        AMO_MAX  =4'b1000,
        AMO_MAXU =4'b1001,
        AMO_MIN  =4'b1010,
        AMO_MINU =4'b1011,
        AMO_CAS1 =4'b1100, // unused, not part of riscv spec, but provided in OpenPiton
        AMO_CAS2 =4'b1101  // unused, not part of riscv spec, but provided in OpenPiton
    } amo_t;

endpackage

