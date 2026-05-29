// ----------------------------------------------------------------------
// Copyright 2026 TimingWalker
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
// Create Date   : 2026-05-28 17:02:05
// Last Modified : 2026-05-29 17:20:58
// Description   : 
// ----------------------------------------------------------------------

module REGFILE #(
    parameter int unsigned REGFILE_LEN  = 32
)(
     input  logic                     clk_i
    ,input  logic                     rst_ni
    ,input  logic                     wr_regfile_i
    ,input  logic  [4:0]              rd_idx_i
    ,input  logic  [31:0]             rd_val_i
`ifdef SOPHON_EEI
    ,input  logic                     wr_regfile_eei_i
    ,input  logic  [REGFILE_LEN-1:0]  eei_rd_idx_onehot_i
    ,input  logic  [31:0]             eei_rd_val_i[REGFILE_LEN-1:0]
`endif
    ,output logic  [31:0]             regfile_o[REGFILE_LEN-1:0]
);

    genvar i;
    generate
        for (i=1; i< REGFILE_LEN; i=i+1) begin:gen_regfile
            always_ff @(posedge clk_i, negedge rst_ni) begin
                if(~rst_ni) begin
                    regfile_o[i] <= 32'd0;
                end
                // Sophon write port
                else if ( wr_regfile_i && (rd_idx_i==i) ) begin
                    regfile_o[i] <= rd_val_i;
                end
            `ifdef SOPHON_EEI
                // EEI write port
                else if ( wr_regfile_eei_i & eei_rd_idx_onehot_i[i] ) begin
                    regfile_o[i] <= eei_rd_val_i[i];
                end
            `endif
            end
        end
    endgenerate
    assign regfile_o[0] = 32'd0;


endmodule

