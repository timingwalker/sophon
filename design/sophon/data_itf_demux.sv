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
// Create Date   : 2023-11-06 11:28:20
// Last Modified : 2024-04-11 09:08:36
// Description   : Demux lsu interface    
// ----------------------------------------------------------------------
 
module DATA_ITF_DEMUX #(
    parameter int unsigned      CH1_BASE = 32'h10000,
    parameter int unsigned      CH1_END  = 32'h1ffff,
    parameter int unsigned      CH2_BASE = 32'h90000,
    parameter int unsigned      CH2_END  = 32'h9ffff
)(
     input  SOPHON_PKG::lsu_req_t   lsu_req_i
    ,output SOPHON_PKG::lsu_ack_t   lsu_ack_o
    ,output SOPHON_PKG::lsu_req_t   lsu_req_1ch_o
    ,input  SOPHON_PKG::lsu_ack_t   lsu_ack_1ch_i
    ,output SOPHON_PKG::lsu_req_t   lsu_req_2ch_o
    ,input  SOPHON_PKG::lsu_ack_t   lsu_ack_2ch_i
);


    always_comb begin
        lsu_req_1ch_o.req = 1'b0;
        lsu_req_2ch_o.req = 1'b0;
        if ( lsu_req_i.req ) begin
            if ( (lsu_req_i.addr[31:0]>=CH1_BASE) && (lsu_req_i.addr[31:0]<=CH1_END) ) 
                lsu_req_1ch_o.req = 1'b1;
            else if ( (lsu_req_i.addr[31:0]>=CH2_BASE) && (lsu_req_i.addr[31:0]<=CH2_END) ) 
                lsu_req_2ch_o.req = 1'b1;
        end
    end


    always_comb begin
        lsu_ack_o.ack   = 1'b0;
        lsu_ack_o.error = 1'b0;    
        lsu_ack_o.rdata = 32'd0;
        if (lsu_req_1ch_o.req) begin
            lsu_ack_o.ack   = lsu_ack_1ch_i.ack;
            lsu_ack_o.error = 1'b0;
            lsu_ack_o.rdata = lsu_ack_1ch_i.rdata;
        end
        else if (lsu_req_2ch_o.req) begin
            lsu_ack_o.ack   = lsu_ack_2ch_i.ack;
            lsu_ack_o.error = 1'b0;
            lsu_ack_o.rdata = lsu_ack_2ch_i.rdata;
        end
        // if lsu addr out of range, return with error=1(load access exception)
        else if (lsu_req_i.req) begin
            lsu_ack_o.ack   = lsu_req_i.req;
            lsu_ack_o.error = 1'b1;    
            lsu_ack_o.rdata = 32'd0;
        end
    end


    assign lsu_req_1ch_o.we    = lsu_req_1ch_o.req ? lsu_req_i.we    : 'b0;
    assign lsu_req_1ch_o.addr  = lsu_req_1ch_o.req ? lsu_req_i.addr  : 'b0;
    assign lsu_req_1ch_o.wdata = lsu_req_1ch_o.req ? lsu_req_i.wdata : 'b0;
    assign lsu_req_1ch_o.amo   = lsu_req_1ch_o.req ? lsu_req_i.amo   : 'b0;
    assign lsu_req_1ch_o.strb  = lsu_req_1ch_o.req ? lsu_req_i.strb  : 'b0;
    assign lsu_req_1ch_o.size  = lsu_req_1ch_o.req ? lsu_req_i.size  : 'b1;

    assign lsu_req_2ch_o.we    = lsu_req_2ch_o.req ? lsu_req_i.we    : 'b0;
    assign lsu_req_2ch_o.addr  = lsu_req_2ch_o.req ? lsu_req_i.addr  : 'b0;
    assign lsu_req_2ch_o.wdata = lsu_req_2ch_o.req ? lsu_req_i.wdata : 'b0;
    assign lsu_req_2ch_o.amo   = lsu_req_2ch_o.req ? lsu_req_i.amo   : 'b0;
    assign lsu_req_2ch_o.strb  = lsu_req_2ch_o.req ? lsu_req_i.strb  : 'b0;
    assign lsu_req_2ch_o.size  = lsu_req_2ch_o.req ? lsu_req_i.size  : 'b1;


endmodule

