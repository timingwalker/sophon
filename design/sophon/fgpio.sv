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
// Create Date   : 2023-01-11 18:00:39
// Last Modified : 2023-12-27 15:03:32
// Description   : fast gpio control instruction extention  
// ----------------------------------------------------------------------

module FGPIO (
     input  logic                               clk_neg_i
    ,input  logic                               rst_ni
    ,input  logic                               fgpio_req     
    ,input  logic [6:0]                         fgpio_funct7  
    ,input  logic [31:0]                        fgpio_rs1_val 
    ,input  logic [31:0]                        fgpio_rs2_val 
    ,output logic                               fgpio_ack     
    ,output logic                               fgpio_error   
    ,output logic [31:0]                        fgpio_rd_val  
    ,output logic [SOPHON_PKG::FGPIO_NUM-1:0]   gpio_dir     
    ,input  logic [SOPHON_PKG::FGPIO_NUM-1:0]   gpio_in_val  
    ,output logic [SOPHON_PKG::FGPIO_NUM-1:0]   gpio_out_val 
);


    localparam int unsigned RSV_BIT = 32 - SOPHON_PKG::FGPIO_NUM;

    logic [SOPHON_PKG::FGPIO_NUM-1:0]       gpio_dir_1d;
    logic [SOPHON_PKG::FGPIO_NUM-1:0]       gpio_out_val_1d;


    assign fgpio_ack = fgpio_req;
    
    always_comb begin
        gpio_dir     = gpio_dir_1d;
        gpio_out_val = gpio_out_val_1d;
        fgpio_rd_val = 32'd0;
        fgpio_error  = fgpio_req;
        if ( fgpio_req && fgpio_funct7 == 7'b0000000 ) begin
            gpio_dir     = { {RSV_BIT{1'b0}}, {SOPHON_PKG::FGPIO_NUM{1'b0}} };
            fgpio_rd_val = { {RSV_BIT{1'b0}}, gpio_in_val};
            fgpio_error  = 1'b0;
        end
        else if ( fgpio_req && fgpio_funct7 == 7'b0000001 ) begin
            gpio_dir     = { {RSV_BIT{1'b0}}, {SOPHON_PKG::FGPIO_NUM{1'b0}} };
            fgpio_rd_val = { {30{1'b0}}, gpio_in_val[ fgpio_rs1_val[$clog2(SOPHON_PKG::FGPIO_NUM)-1:0] ]};
            fgpio_error  = 1'b0;
        end
        else if ( fgpio_req && fgpio_funct7 == 7'b1000000 ) begin
            gpio_dir     = { {RSV_BIT{1'b0}}, {SOPHON_PKG::FGPIO_NUM{1'b1}} };
            gpio_out_val = fgpio_rs1_val[SOPHON_PKG::FGPIO_NUM-1:0];
            fgpio_error  = 1'b0;
        end
        else if ( fgpio_req && fgpio_funct7 == 7'b1000001 ) begin
            gpio_dir     = { {RSV_BIT{1'b0}}, {SOPHON_PKG::FGPIO_NUM{1'b1}} };
            gpio_out_val = fgpio_rs1_val[SOPHON_PKG::FGPIO_NUM-1:0] & fgpio_rs2_val[SOPHON_PKG::FGPIO_NUM-1:0];
            fgpio_error  = 1'b0;
        end
    end

    always_ff @(posedge clk_neg_i, negedge rst_ni) begin
        if(~rst_ni) begin
            gpio_dir_1d     <= {SOPHON_PKG::FGPIO_NUM{1'b0}};
            gpio_out_val_1d <= {SOPHON_PKG::FGPIO_NUM{1'b0}};
        end
        else if ( fgpio_req ) begin
            gpio_dir_1d     <= gpio_dir;
            gpio_out_val_1d <= gpio_out_val;
        end
    end


endmodule

