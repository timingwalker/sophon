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
// Create Date   : 2024-03-27 10:24:42
// Last Modified : 2024-03-27 11:17:58
// Description   : Btye Write Enable Single Port RAM
// ----------------------------------------------------------------------

module BW_SP_RAM
#(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter NUM_BYTE   = DATA_WIDTH/8
)(
     input  logic                    clk_i
    ,input  logic                    en_i
    ,input  logic [ADDR_WIDTH-1:0]   addr_i
    ,input  logic [DATA_WIDTH-1:0]   wdata_i
    ,output logic [DATA_WIDTH-1:0]   rdata_o
    ,input  logic                    we_i
    ,input  logic [NUM_BYTE-1:0]     be_i
);

    logic [DATA_WIDTH-1:0] ram_block [(2**ADDR_WIDTH)-1:0];

    integer i;

    always @(posedge clk_i) begin
        if ( en_i && we_i ) begin
            for ( i=0; i<NUM_BYTE; i=i+1 ) begin
                if ( be_i[i] ) begin
                    ram_block[addr_i][i*8+:8] <= wdata_i[i*8+:8];
                end
            end
        end
    end

    always_ff @(posedge clk_i) begin
        if ( en_i && ~we_i ) begin
            rdata_o <= ram_block[addr_i];
        end
    end

endmodule

