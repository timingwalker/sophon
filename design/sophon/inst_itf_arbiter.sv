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
// Create Date   : 2023-11-08 15:56:49
// Last Modified : 2023-12-26 16:40:23
// Description   : Arbiter of IRAM interface
// ----------------------------------------------------------------------

module INST_ITF_ARBITER(
     input logic                  clk_i
    ,input logic                  rst_ni
    ,input logic                  clk_neg_i
    ,input logic                  rst_neg_ni
    // channel 1, form core, negedge
    ,input  SOPHON_PKG::inst_req_t  core_iram_req
    ,output SOPHON_PKG::inst_ack_t  core_iram_ack
    // channel 2, form external interface, posedge
    ,input  SOPHON_PKG::lsu_req_t   ext_iram_req
    ,output SOPHON_PKG::lsu_ack_t   ext_iram_ack
    // output, to sram
    ,output logic                 iram_req
    ,output logic [31:0]          iram_addr
    ,output logic [31:0]          iram_wdata
    ,output logic                 iram_we
    ,output logic [3:0]           iram_be
    ,input  logic [31:0]          iram_rdata
);


    logic             ext_iram_stall;
    logic             ext_iram_req_neg;
    logic             ext_iram_req_neg_1d;
    logic             ext_iram_req_1d;
    logic             ext_iram_cs;
    logic             ext_iram_cs_1d;

    // external access mask two-cycles to eliminate overlap
    assign ext_iram_stall = ext_iram_req_neg | ext_iram_req_neg_1d;
    always @(posedge clk_neg_i or negedge rst_neg_ni) begin
    	if(~rst_neg_ni) begin
    		ext_iram_req_neg    <= 1'b0;
    		ext_iram_req_neg_1d <= 1'b0;
        end
        else begin
    		ext_iram_req_neg    <= ext_iram_req.req;
    		ext_iram_req_neg_1d <= ext_iram_req_neg;
        end
    end

    // // effective external access occurs at the second cycle
    // always @(posedge clk_neg_i or negedge rst_neg_ni) begin
    // 	if(~rst_neg_ni) begin
    // 		ext_iram_req_1d   <= 1'b0;
    //     end
    //     else begin
    // 		ext_iram_req_1d   <= ext_iram_req.req;
    //     end
    // end

    // always @(posedge clk_i or negedge rst_ni) begin
    // 	if(~rst_ni) 
    //         ext_iram_cs <= 1'b0;
    //     else if (ext_iram_cs)
    //         ext_iram_cs <= 1'b0;
    //     else if (ext_iram_req.req)
    //         ext_iram_cs <= 1'b1;
    // end
    // external interface has higher priority
    assign iram_req   = ext_iram_cs | (core_iram_req.req & ~ext_iram_stall)   ; 
    assign iram_addr  = ext_iram_cs ? ext_iram_req.addr  : core_iram_req.addr ; 
    assign iram_wdata = ext_iram_cs ? ext_iram_req.wdata : '0                 ; 
    assign iram_we    = ext_iram_cs ? ext_iram_req.we    : '0                 ; 
    assign iram_be    = ext_iram_cs ? '1                 : '1                 ; // TODO: be of ext itf?
    
    logic [1:0] cnt_ext_iram_req;
    always @(posedge clk_i or negedge rst_ni) begin
    	if(~rst_ni) 
            cnt_ext_iram_req <= 2'd0;
        else if ( ~ext_iram_req.req )
            cnt_ext_iram_req <= 2'd0;
        else if ( ext_iram_req.req )
            cnt_ext_iram_req <= cnt_ext_iram_req + 2'd1;
    end

    assign ext_iram_cs = (cnt_ext_iram_req==2'd1);
    assign ext_iram_cs_1d = (cnt_ext_iram_req==2'd2);

    // always @(posedge clk_i or negedge rst_ni) begin
    // 	if(~rst_ni) 
    //         ext_iram_cs_1d <= 1'b0;
    //     else if (ext_iram_cs_1d)
    //         ext_iram_cs_1d <= 1'b0;
    //     else if (ext_iram_cs)
    //         ext_iram_cs_1d <= 1'b1;
    // end
    //assign ext_iram_ack.ack   = ext_iram_req.we ? ext_iram_cs : ext_iram_cs_1d;
    assign ext_iram_ack.ack   = ext_iram_cs_1d;
    assign ext_iram_ack.error = 1'b0;
    assign ext_iram_ack.rdata = iram_rdata;

    assign core_iram_ack.ack   = core_iram_req.req & ~ext_iram_stall;
    assign core_iram_ack.error = 1'b0;
    assign core_iram_ack.rdata = iram_rdata;


endmodule

