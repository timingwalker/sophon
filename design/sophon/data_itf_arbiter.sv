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
// Last Modified : 2023-12-24 15:37:35
// Description   : Arbiter of DRAM interface
// ----------------------------------------------------------------------

module DATA_ITF_ARBITER(
    // channel 1, form core
     input  SOPHON_PKG::lsu_req_t  core_dram_req
    ,output SOPHON_PKG::lsu_ack_t  core_dram_ack
    // channel 2, form external interface
    ,input  SOPHON_PKG::lsu_req_t  ext_dram_req
    ,output SOPHON_PKG::lsu_ack_t  ext_dram_ack
    // output, to sram
    ,output logic                 dram_req
    ,output logic [31:0]          dram_addr
    ,output logic [31:0]          dram_wdata
    ,output logic                 dram_we
    ,output logic [3:0]           dram_be
    ,input  logic [31:0]          dram_rdata

);

    // external interface has higher priority
    assign dram_req   = ext_dram_req.req | core_dram_req.req ; 
    assign dram_addr  = ext_dram_req.req ? ext_dram_req.addr  : core_dram_req.addr ; 
    assign dram_wdata = ext_dram_req.req ? ext_dram_req.wdata : core_dram_req.wdata; 
    assign dram_we    = ext_dram_req.req ? ext_dram_req.we    : core_dram_req.we   ; 
    assign dram_be    = ext_dram_req.req ? ext_dram_req.strb  : core_dram_req.strb ; 
    
    assign ext_dram_ack.ack   = ext_dram_req.req;
    assign ext_dram_ack.error = 1'b0;
    assign ext_dram_ack.rdata = dram_rdata;

    assign core_dram_ack.ack   = core_dram_req.req & ~ext_dram_req.req;
    assign core_dram_ack.error = 1'b0;
    assign core_dram_ack.rdata = dram_rdata;



endmodule

