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
// Last Modified : 2024-03-26 22:26:27
// Description   : snapshot regfile     
// ----------------------------------------------------------------------

module SNAPREG(
     input  logic                               clk_i
    ,input  logic                               rst_ni
    ,input  logic                               sreg_req     
    ,input  logic [6:0]                         sreg_funct7  
    ,input  logic [4:0]                         sreg_batch_start 
    ,input  logic [4:0]                         sreg_batch_len 
    ,input  logic [31:0]                        sreg_rs_val[SOPHON_PKG::EEI_RS_MAX-1:0]    
    ,output logic                               sreg_ack   
    ,output logic                               sreg_error   
    ,output logic [31:0]                        sreg_rd_val[SOPHON_PKG::EEI_RD_MAX-1:0] 
);


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

    integer j;
    always_comb begin
        wr_sreg_bit = 32'd0;
        for (j=0; j<32; j=j+1)
            wr_sreg_bit[j] = ( (sreg_batch_start<=6'(j)) && ((sreg_batch_len+sreg_batch_start)>6'(j)) ) ? 1'b1 : 1'b0;
    end

    genvar i;
    generate
        for (i=1; i<32; i=i+1) begin:gen_snapreg
            always_ff @(posedge clk_i, negedge rst_ni) begin
                if(~rst_ni) begin
                    snapreg[i] <= 32'd0;
                end
                else if ( sreg_wr && (wr_sreg_bit[i]==1) ) begin
                    snapreg[i] <= sreg_rs_val[ i-sreg_batch_start ];
                end
            end
        end
    endgenerate
    assign snapreg[0] = 32'd0;


    localparam EXT_RF_LEN  = 32 + SOPHON_PKG::EEI_RD_MAX -1;
    logic  [31:0] ext_snapreg[EXT_RF_LEN-1:0];
    for (genvar i=0; i<EXT_RF_LEN; i++) begin : gen_ext_snapreg
        if ( i<32 ) 
            assign ext_snapreg[i] = snapreg[i];
        else 
            assign ext_snapreg[i] = snapreg[i-32];
    end

    genvar k;
    generate
        for (k=0; k<SOPHON_PKG::EEI_RD_MAX; k=k+1) begin:gen_sreg_rd_val
            assign sreg_rd_val[k] = ext_snapreg[k+sreg_batch_start];
        end
    endgenerate


endmodule

