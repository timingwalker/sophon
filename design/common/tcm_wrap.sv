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
// Create Date   : 2022-11-09 16:42:12
// Last Modified : 2024-11-26 15:21:47
// Description   : TCM wrapper
// ----------------------------------------------------------------------

module TCM_WRAP
#(
    parameter int unsigned DATA_WIDTH = 32,
    parameter int unsigned DEPTH      = 8192,              // in DATA_WIDTH
    parameter int unsigned ADDR_WIDTH = $clog2(DEPTH*32/8) // in byte
)(
     input  logic                        clk_i
    ,input  logic                        en_i
    ,input  logic [ADDR_WIDTH-1:0]       addr_i     // should align to DATA_WIDTH, in byte
    ,input  logic [DATA_WIDTH-1:0]       wdata_i
    ,input  logic                        we_i
    ,input  logic [DATA_WIDTH/8-1:0]     be_i
    ,output logic [DATA_WIDTH-1:0]       rdata_o
);

    // spilt to several bank
    localparam int unsigned BANK_DEPTH        = 1024;
    localparam int unsigned BANK_NUM          = DEPTH / BANK_DEPTH;
    //localparam int unsigned BANK_ADDR_WIDTH = $clog2(BANK_NUM); 
    localparam int unsigned BANK_ADDR_WIDTH   = (BANK_NUM==1) ? 1 : $clog2(BANK_NUM); 
    localparam int unsigned COMMON_ADDR_WIDTH = (BANK_NUM==1) ? ADDR_WIDTH : ADDR_WIDTH-BANK_ADDR_WIDTH; 
    
    logic [BANK_ADDR_WIDTH-1:0]             bank_addr;
    logic [BANK_ADDR_WIDTH-1:0]             bank_addr_q;
    logic [BANK_NUM-1:0]                    bank_en;
    logic [DATA_WIDTH-1:0]                  bank_rdata[BANK_NUM-1:0];
    logic [COMMON_ADDR_WIDTH-1:0]           addr_common;
    
    // addr_i = { bank_addr, addr_common }
    assign bank_addr   = (BANK_NUM==1) ? 1'b0 :addr_i[ADDR_WIDTH-1 -: BANK_ADDR_WIDTH]; // select bank ram
    assign addr_common = addr_i[COMMON_ADDR_WIDTH-1:0 ];          // addr inside bank


    `ifdef ASIC
        logic [DATA_WIDTH-1:0] bit_wen;
        integer j;
        always_comb begin
            for(j=0; j<DATA_WIDTH; j=j+1) begin
                bit_wen[j] = be_i[j/8];
            end
        end
    `endif


    genvar i;
    generate
        for (i=0; i<BANK_NUM; i=i+1) begin:gen_spilt_ram // 1024*32bit=4KB

            assign bank_en[i] = en_i & (bank_addr==BANK_ADDR_WIDTH'(i));
    
            `ifdef ASIC
                S55NLLGSPH_X64Y8D32_BW U_TCM_RAM (
                    .Q       ( bank_rdata[i]                      ) ,
                    .CLK     ( clk_i                              ) ,
                    .CEN     ( ~bank_en[i]                        ) ,
                    .WEN     ( ~we_i                              ) ,
                    .BWEN    ( ~bit_wen                           ) ,
                    .A       ( addr_common[COMMON_ADDR_WIDTH-1:2] ) , // in word
                    .D       ( wdata_i                            ) 
                );
            `else
                BW_SP_RAM
                #(
                    // ADDR_WIDTH:  counts in DATA_WIDTH
                    // addr_common: counts in byte
                    .ADDR_WIDTH ( $clog2(BANK_DEPTH) ), 
                    .DATA_WIDTH ( DATA_WIDTH         )
                )
                U_BW_SP_RAM
                (
                    .clk_i   ( clk_i                              ) ,
                    .en_i    ( bank_en[i]                         ) ,
                    .addr_i  ( addr_common[COMMON_ADDR_WIDTH-1:2] ) , // in DATA_WIDTH
                    .wdata_i ( wdata_i                            ) ,
                    .rdata_o ( bank_rdata[i]                      ) ,
                    .we_i    ( we_i                               ) ,
                    .be_i    ( be_i                               ) 
                );
            `endif
    
        end
    endgenerate


    // Spilt rdata mux to optimize timing
    //localparam int unsigned RDATA_MUX_NUM = BANK_NUM / 4;
    localparam int unsigned RDATA_MUX_NUM = (BANK_NUM<4) ? 1 : BANK_NUM / 4;
    logic [DATA_WIDTH-1:0]  rdata_mux[RDATA_MUX_NUM-1:0];
    genvar m,n;

    always_ff @(posedge clk_i) begin
        if ( en_i && ~we_i )
            bank_addr_q <= bank_addr;
    end

    generate
        if (BANK_NUM==1)
            assign rdata_o = bank_rdata[0];
        else if (BANK_NUM==2)
            assign rdata_o = bank_addr_q ? bank_rdata[1] : bank_rdata[0];
        else begin
            for (m=0; m<RDATA_MUX_NUM; m=m+1) begin:gen_rdata_l1
                always_comb begin
                    case (bank_addr_q[1:0])
                        2'b00  : rdata_mux[m] = bank_rdata[m*4+0];
                        2'b01  : rdata_mux[m] = bank_rdata[m*4+1];
                        2'b10  : rdata_mux[m] = bank_rdata[m*4+2];
                        2'b11  : rdata_mux[m] = bank_rdata[m*4+3];
                        default: rdata_mux[m] = '0;
                    endcase
                end
            end
            assign rdata_o = rdata_mux[bank_addr_q[BANK_ADDR_WIDTH-1:2]];
        end
    endgenerate

endmodule

