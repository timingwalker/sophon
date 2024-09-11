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
// Last Modified : 2024-09-10 14:35:36
// Description   : Demux lsu interface    
//                 NOTE: the addr decode granularity is 4KB
// ----------------------------------------------------------------------
 
module DATA_ITF_DEMUX #(
    parameter int unsigned      CH1_BASE = 32'h10000,
    parameter int unsigned      CH1_END  = 32'h1ffff,
    parameter int unsigned      CH2_BASE = 32'h90000,
    parameter int unsigned      CH2_END  = 32'h9ffff
)(
     input logic                    clk_i
    ,input logic                    rst_ni
    ,input logic                    clk_neg_i
    ,input logic                    rst_neg_ni
    ,input  SOPHON_PKG::lsu_req_t   lsu_req_i
    ,output SOPHON_PKG::lsu_ack_t   lsu_ack_o
    ,output SOPHON_PKG::lsu_req_t   lsu_req_1ch_o
    ,input  SOPHON_PKG::lsu_ack_t   lsu_ack_1ch_i
    ,output SOPHON_PKG::lsu_req_t   lsu_req_2ch_o
    ,input  SOPHON_PKG::lsu_ack_t   lsu_ack_2ch_i
);


    // ----------------------------------------------------------------------
    //  Channel 1: to DTCM, combinatorial path
    // ----------------------------------------------------------------------
    always_comb begin
        lsu_req_1ch_o.req = 1'b0;
        if ( lsu_req_i.req ) begin
            if ( (lsu_req_i.addr[31:12]>=CH1_BASE[31:12]) && (lsu_req_i.addr[31:12]<=CH1_END[31:12]) ) 
                lsu_req_1ch_o.req = 1'b1;
        end
    end

    assign lsu_req_1ch_o.we    = lsu_req_2ch_o.req ? 'b0 : lsu_req_i.we;
    assign lsu_req_1ch_o.addr  = lsu_req_2ch_o.req ? 'b0 : lsu_req_i.addr;
    assign lsu_req_1ch_o.wdata = lsu_req_2ch_o.req ? 'b0 : lsu_req_i.wdata;
    assign lsu_req_1ch_o.amo   = lsu_req_2ch_o.req ? 'b0 : lsu_req_i.amo  ;
    assign lsu_req_1ch_o.strb  = lsu_req_2ch_o.req ? 'b0 : lsu_req_i.strb ;
    assign lsu_req_1ch_o.size  = lsu_req_2ch_o.req ? 'b0 : lsu_req_i.size ;


    // ----------------------------------------------------------------------
    //  Channel 2: to external memory, sequential path
    //  Sequential logic increases 1 cycle latency, but benefit from:
    //   - break timing path to improve timing
    //   - safer for integration with external logic
    // ----------------------------------------------------------------------
    always @(posedge clk_i or negedge rst_ni) begin
    	if(~rst_ni) begin
            lsu_req_2ch_o.req   <= 1'b0;
            lsu_req_2ch_o.wdata <= 'b0;
            lsu_req_2ch_o.strb  <= 'b0;
            lsu_req_2ch_o.we    <= 'b0;
            lsu_req_2ch_o.addr  <= 'b0;
            lsu_req_2ch_o.amo   <= 'b0;
            lsu_req_2ch_o.size  <= 'b1;
        end
        else if (lsu_ack_2ch_i.ack) begin
            lsu_req_2ch_o.req   <= 1'b0;
            lsu_req_2ch_o.wdata <= 'b0;
            lsu_req_2ch_o.strb  <= 'b0;
            lsu_req_2ch_o.we    <= 'b0;
            lsu_req_2ch_o.addr  <= 'b0;
            lsu_req_2ch_o.amo   <= 'b0;
            lsu_req_2ch_o.size  <= 'b1;
        end
        else if ( lsu_req_i.req && (lsu_req_i.addr[31:12]>=CH2_BASE[31:12]) && (lsu_req_i.addr[31:12]<=CH2_END[31:12]) ) begin
            lsu_req_2ch_o.req   <= 1'b1;
            lsu_req_2ch_o.wdata <= lsu_req_i.wdata;
            lsu_req_2ch_o.strb  <= lsu_req_i.strb;
            lsu_req_2ch_o.we    <= lsu_req_i.we;
            lsu_req_2ch_o.addr  <= lsu_req_i.addr;
            lsu_req_2ch_o.amo   <= lsu_req_i.amo;
            lsu_req_2ch_o.size  <= lsu_req_i.size;
        end
    end


    // ----------------------------------------------------------------------
    //  Response signals
    // ----------------------------------------------------------------------
    logic lsu_req_i_pending;
    always @(posedge clk_i or negedge rst_ni) begin
    	if(~rst_ni) 
            lsu_req_i_pending <= 1'b0;
        else if (lsu_req_i.req & lsu_ack_o.ack)
            lsu_req_i_pending <= 1'b0;
        else if (lsu_req_i.req & ~lsu_ack_o.ack)
            lsu_req_i_pending <= 1'b1;
    end

    always_comb begin
        lsu_ack_o.ack   = 1'b0;
        lsu_ack_o.error = 1'b0;    
        if (lsu_req_1ch_o.req) begin
            lsu_ack_o.ack   = lsu_ack_1ch_i.ack;
            lsu_ack_o.error = 1'b0;
        end
        else if (lsu_req_2ch_o.req) begin
            lsu_ack_o.ack   = lsu_ack_2ch_i.ack;
            lsu_ack_o.error = 1'b0;
        end
        // out of range, return error=1
        else if (lsu_req_i_pending) begin
            lsu_ack_o.ack   = 1'b1;
            lsu_ack_o.error = 1'b1;    
        end
    end

    // make sure lsu access external memory has the same timing behavior as accessing TCM
    logic lsu_req_2ch_ack_toneg;
    always @(posedge clk_neg_i or negedge rst_neg_ni) begin
    	if(~rst_neg_ni) begin
            lsu_req_2ch_ack_toneg <= 1'b0;
        end
        else begin
            lsu_req_2ch_ack_toneg <= lsu_ack_2ch_i.ack;
        end
    end

    //assign lsu_ack_o.rdata = lsu_req_2ch_o.req ? lsu_ack_2ch_i.rdata : lsu_ack_1ch_i.rdata;
    assign lsu_ack_o.rdata = lsu_req_2ch_ack_toneg ? lsu_ack_2ch_i.rdata : lsu_ack_1ch_i.rdata;

endmodule

