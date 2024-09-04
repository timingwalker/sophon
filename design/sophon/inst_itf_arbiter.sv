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
// Create Date   : 2023-11-08 15:56:49
// Last Modified : 2024-07-25 15:51:56
// Description   : Arbiter of IRAM interface
// ----------------------------------------------------------------------

module INST_ITF_ARBITER(
     input logic                    clk_i
    ,input logic                    rst_ni
    ,input logic                    clk_neg_i
    ,input logic                    rst_neg_ni
    // channel 1, form core, negedge
    ,input  SOPHON_PKG::inst_req_t  core_itcm_req
    ,output SOPHON_PKG::inst_ack_t  core_itcm_ack
    // channel 2, form external interface, posedge
    ,input  SOPHON_PKG::lsu_req_t   ext_itcm_req
    ,output SOPHON_PKG::lsu_ack_t   ext_itcm_ack
    // output, to sram
    ,output logic                   itcm_req
    ,output logic [31:0]            itcm_addr
    ,output logic [31:0]            itcm_wdata
    ,output logic                   itcm_we
    ,output logic [3:0]             itcm_be
    ,input  logic [31:0]            itcm_rdata
);


    logic             ext_itcm_stall;
    logic             ext_itcm_req_neg;
    logic             ext_itcm_req_neg_1d;
    logic             ext_itcm_cs;
    logic             ext_itcm_cs_1d;
    logic [1:0]       cnt_ext_itcm_req;


    // ------------------------------------------------
    //  Request
    // ------------------------------------------------
    always @(posedge clk_i or negedge rst_ni) begin
    	if(~rst_ni) 
            cnt_ext_itcm_req <= 2'd0;
        else if ( ~ext_itcm_req.req )
            cnt_ext_itcm_req <= 2'd0;
        else if ( ext_itcm_req.req )
            cnt_ext_itcm_req <= cnt_ext_itcm_req + 2'd1;
    end

    assign ext_itcm_cs    = (cnt_ext_itcm_req==2'd1);
    assign ext_itcm_cs_1d = (cnt_ext_itcm_req==2'd2);


    // external access mask two-cycles to eliminate overlap
    assign ext_itcm_stall = ext_itcm_req_neg | ext_itcm_req_neg_1d;
    always @(posedge clk_neg_i or negedge rst_neg_ni) begin
    	if(~rst_neg_ni) begin
    		ext_itcm_req_neg    <= 1'b0;
    		ext_itcm_req_neg_1d <= 1'b0;
        end
        else begin
    		ext_itcm_req_neg    <= ext_itcm_req.req;
    		ext_itcm_req_neg_1d <= ext_itcm_req_neg;
        end
    end

    assign itcm_req   = ext_itcm_cs | (core_itcm_req.req & ~ext_itcm_stall)   ; 
    assign itcm_addr  = ext_itcm_cs ? ext_itcm_req.addr  : core_itcm_req.addr ; 
    assign itcm_wdata = ext_itcm_cs ? ext_itcm_req.wdata : '0                 ; 
    assign itcm_we    = ext_itcm_cs ? ext_itcm_req.we    : '0                 ; 
    assign itcm_be    = ext_itcm_cs ? ext_itcm_req.strb  : '1                 ;
    

    // ------------------------------------------------
    //  Response
    // ------------------------------------------------
    assign ext_itcm_ack.ack   = ext_itcm_cs_1d;
    assign ext_itcm_ack.error = 1'b0;
    assign ext_itcm_ack.rdata = itcm_rdata;

    assign core_itcm_ack.ack   = core_itcm_req.req & ~ext_itcm_stall;
    assign core_itcm_ack.error = 1'b0;
    assign core_itcm_ack.rdata = itcm_rdata;


endmodule

