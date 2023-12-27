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
// Create Date : 2022-11-09 16:42:12
//  Description : TCM wrapper
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
    localparam int unsigned BANK_DEPTH       = 512;
    localparam int unsigned BANK_NUM         = DEPTH / BANK_DEPTH;
    localparam int unsigned BANK_ADDR_WIDTH  = $clog2(BANK_NUM); 
    localparam int unsigned SPILT_ADDR_WIDTH = ADDR_WIDTH-BANK_ADDR_WIDTH; 
    
    logic [BANK_ADDR_WIDTH-1:0]             bank_addr;
    logic [BANK_ADDR_WIDTH-1:0]             rsv_bank_addr;
    logic [BANK_NUM-1:0]                    bank_en;
    logic [DATA_WIDTH-1:0]                  bank_rdata[BANK_NUM-1:0];
    logic [SPILT_ADDR_WIDTH-1:0]            addr;
    logic [DATA_WIDTH-1:0]                  bit_wen;
    
    // addr_i = { bank_addr, addr }
    assign bank_addr = addr_i[ADDR_WIDTH-1 -: BANK_ADDR_WIDTH]; // select bank ram
    assign addr      = addr_i[ADDR_WIDTH-BANK_ADDR_WIDTH-1:0 ]; // bank ram addr

    integer j;
    always_comb begin
        for(j=0; j<DATA_WIDTH; j=j+1) begin
            bit_wen[j] = be_i[j/8];
        end
    end

    genvar i;
    generate
        for (i=0; i<BANK_NUM; i=i+1) begin:gen_spilt_ram // 512*32bit=2KB

            assign bank_en[i] = en_i & (bank_addr==BANK_ADDR_WIDTH'(i));
    
            `ifdef ASIC
                S55NLLGSPH_X64Y8D32_BW u_tcm_ram (
                    .Q    ( bank_rdata[i] ) ,
                    .CLK  ( clk_i         ) ,
                    .CEN  ( ~bank_en[i]   ) ,
                    .WEN  ( ~we_i         ) ,
                    .BWEN ( ~bit_wen      ) ,
                    .A    ( addr[2+:9]    ) , // in word
                    .D    ( wdata_i       ) 
                );

            `else
                sp_ram
                #(
                    .ADDR_WIDTH ( SPILT_ADDR_WIDTH                  ), // in byte
                    .DATA_WIDTH ( DATA_WIDTH                        ), // 
                    .NUM_WORDS  ( BANK_DEPTH * (DATA_WIDTH/8)       )  // in byte
                )
                sp_ram_i
                (
                    .clk     ( clk_i                                 ) ,
                    .en_i    ( bank_en[i]                            ) ,
                    .addr_i  ( addr                                  ) , 
                    .wdata_i ( wdata_i                               ) ,
                    .rdata_o ( bank_rdata[i]                         ) ,
                    .we_i    ( we_i                                  ) ,
                    .be_i    ( be_i                                  ) 
                );

            `endif
    
        end
    endgenerate


    always_ff @(posedge clk_i) begin
        if ( en_i && ~we_i )
            rsv_bank_addr <= bank_addr;
    end

    assign rdata_o = bank_rdata[rsv_bank_addr];


endmodule

