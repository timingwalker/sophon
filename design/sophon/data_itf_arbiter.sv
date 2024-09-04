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
// Create Date   : 2023-11-14 17:39:40
// Last Modified : 2024-07-25 14:55:30
// Description   : Arbiter of DTCM interface
// ----------------------------------------------------------------------

module DATA_ITF_ARBITER(
    // channel 1, form core
     input  SOPHON_PKG::lsu_req_t  core_dtcm_req
    ,output SOPHON_PKG::lsu_ack_t  core_dtcm_ack
    // channel 2, form external interface
    ,input  SOPHON_PKG::lsu_req_t  ext_dtcm_req
    ,output SOPHON_PKG::lsu_ack_t  ext_dtcm_ack
    // output, to sram
    ,output logic                 dtcm_req
    ,output logic [31:0]          dtcm_addr
    ,output logic [31:0]          dtcm_wdata
    ,output logic                 dtcm_we
    ,output logic [3:0]           dtcm_be
    ,input  logic [31:0]          dtcm_rdata

);

    // external interface has higher priority
    assign dtcm_req   = ext_dtcm_req.req | core_dtcm_req.req ; 
    assign dtcm_addr  = ext_dtcm_req.req ? ext_dtcm_req.addr  : core_dtcm_req.addr ; 
    assign dtcm_wdata = ext_dtcm_req.req ? ext_dtcm_req.wdata : core_dtcm_req.wdata; 
    assign dtcm_we    = ext_dtcm_req.req ? ext_dtcm_req.we    : core_dtcm_req.we   ; 
    assign dtcm_be    = ext_dtcm_req.req ? ext_dtcm_req.strb  : core_dtcm_req.strb ; 
    
    assign ext_dtcm_ack.ack   = ext_dtcm_req.req;
    assign ext_dtcm_ack.error = 1'b0;
    assign ext_dtcm_ack.rdata = dtcm_rdata;

    assign core_dtcm_ack.ack   = core_dtcm_req.req & ~ext_dtcm_req.req;
    assign core_dtcm_ack.error = 1'b0;
    assign core_dtcm_ack.rdata = dtcm_rdata;


endmodule

