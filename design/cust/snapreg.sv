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
// Create Date   : 2023-01-12 10:22:46
// Last Modified : 2026-05-29 15:54:18
// Description   : snapshot regfile     
// ----------------------------------------------------------------------

module SNAPREG(
`ifdef SOPHON_EEI_SREG
     input  logic                               clk_i
    ,input  logic                               rst_ni
    ,input  logic                               sreg_req     
    ,input  logic [6:0]                         sreg_funct7  
    ,input  logic [4:0]                         sreg_batch_start 
    ,input  logic [4:0]                         sreg_batch_len 
    ,input  logic [31:0]                        sreg_rs_val[`EEI_RS_MAX-1:0]    
    ,output logic                               sreg_ack   
    ,output logic                               sreg_error   
    ,output logic [31:0]                        sreg_rd_val[`EEI_RD_MAX-1:0] 
    ,output logic [31:0]                        sreg_rd_idx_onehot
`endif
);


`ifdef SOPHON_EEI_SREG

    logic [31:0]        wr_sreg_bit;
    logic               sreg_wr;
    logic [31:0]        snapreg[31:0];

    assign sreg_ack = sreg_req;

    always_comb begin
        sreg_wr    = 1'b0;
        sreg_error = sreg_req;
        if ( sreg_req && sreg_funct7 == 7'b0000000 ) begin
            sreg_wr    = 1'b1;
            sreg_error = 1'b0;
        end
        else if ( sreg_req && sreg_funct7 == 7'b1000000 ) begin
            sreg_wr    = 1'b0;
            sreg_error = 1'b0;
        end
    end

    genvar i;
    generate
        for (i=1; i<32; i=i+1) begin:gen_snapreg
            always_ff @(posedge clk_i, negedge rst_ni) begin
                if(~rst_ni) begin
                    snapreg[i] <= 32'd0;
                end
                else if ( sreg_wr ) begin
                    snapreg[i] <= sreg_rs_val[i];
                end
            end
        end
    endgenerate
    assign snapreg[0] = 32'd0;

	assign sreg_rd_idx_onehot = '1;
    assign sreg_rd_val = snapreg;

`endif

endmodule

