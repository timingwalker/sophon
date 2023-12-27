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
// Create Date   : 2022-08-31 09:03:49
// Last Modified : 2023-12-27 14:45:41
// Description   : reqresp to memory interface
// ----------------------------------------------------------------------

module REQRSP_TO_MEM #(
    parameter type            req_t      = logic,
    parameter type            resp_t     = logic,
    parameter int unsigned    DATA_WIDTH = 64,
    parameter int unsigned    ADDR_WIDTH = 32
) (
     input  logic                        clk_i
    ,input  logic                        rst_ni
// reqresp
    ,input  req_t                        req_i
    ,output resp_t                       resp_o
// mem interface
    ,output logic                        mem_req
    ,input  logic                        mem_gnt
    ,output logic                        mem_cs
    ,output logic                        mem_we
    ,output [DATA_WIDTH /8-1:0]          mem_be
    ,output [ADDR_WIDTH-1:0]             mem_addr
    ,output [DATA_WIDTH-1:0]             mem_wdata
    ,input  [DATA_WIDTH-1:0]             mem_rdata
);


    // ----------------------------------------------------------------------
    // Request
    // ----------------------------------------------------------------------
    logic pending;

    assign mem_req        = req_i.q_valid & (~pending);
    assign resp_o.q_ready = mem_gnt & (~pending);

    // memory interface
    assign mem_cs         = mem_req & mem_gnt;
    assign mem_we         = mem_req & req_i.q.write;
    assign mem_rd         = mem_req & (~req_i.q.write);
    // ignore reqi.q.amo
    assign mem_addr       = req_i.q.addr;
    assign mem_wdata      = req_i.q.data;
    assign mem_be         = req_i.q.strb;
    // TODO: size

    // pending
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if      ( ~rst_ni                         )  pending  <= 1'b0;
        else if ( req_i.q_valid & resp_o.q_ready  )  pending  <= 1'b1;
        else if ( req_i.p_ready & resp_o.p_valid  )  pending  <= 1'b0;
    end

    // ----------------------------------------------------------------------
    // Response
    // ----------------------------------------------------------------------
    logic [DATA_WIDTH-1:0]  mem_rdata_q;
    logic                   mem_rd_1d;
    logic                   p_valid_q;

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if    ( ~rst_ni )     mem_rd_1d <= 1'b0;
        else                  mem_rd_1d <= mem_rd;
    end

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if      ( ~rst_ni )   mem_rdata_q <= {DATA_WIDTH{1'b0}};
        else if ( mem_rd_1d  )   mem_rdata_q <= mem_rdata;
    end

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if      ( ~rst_ni         )  p_valid_q  <= 1'b0;
        //else if ( mem_rd | mem_we )  p_valid_q  <= 1'b1;
        else if ( mem_cs          )  p_valid_q  <= 1'b1;
        else if ( req_i.p_ready   )  p_valid_q  <= 1'b0;
    end

    assign resp_o.p_valid = p_valid_q;
    assign resp_o.p.error = 0;
    assign resp_o.p.data  = mem_rd_1d ? mem_rdata : mem_rdata_q;

endmodule

