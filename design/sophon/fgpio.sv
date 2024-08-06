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
// Last Modified : 2024-07-29 11:23:19
// Description   : fast gpio control instruction extention  
// ----------------------------------------------------------------------

module FGPIO (
`ifdef SOPHON_EEI_GPIO
     input  logic                               clk_neg_i
    ,input  logic                               rst_ni
    ,input  logic                               fgpio_req     
    ,input  logic [6:0]                         fgpio_funct7  
    ,input  logic [31:0]                        fgpio_rs1_val 
    ,input  logic [31:0]                        fgpio_rs2_val 
    ,output logic                               fgpio_ack     
    ,output logic                               fgpio_error   
    ,output logic [31:0]                        fgpio_rd_val  
    ,output logic [`FGPIO_NUM-1:0]              gpio_dir     
    ,input  logic [`FGPIO_NUM-1:0]              gpio_in_val  
    ,output logic [`FGPIO_NUM-1:0]              gpio_out_val 
`endif
);


`ifdef SOPHON_EEI_GPIO

    localparam int unsigned RSV_BIT = 32 - `FGPIO_NUM;

    logic [`FGPIO_NUM-1:0]       gpio_dir_1d;
    logic [`FGPIO_NUM-1:0]       gpio_out_val_1d;


    assign fgpio_ack = fgpio_req;
    
    always_comb begin
        gpio_dir     = gpio_dir_1d;
        gpio_out_val = gpio_out_val_1d;
        fgpio_rd_val = 32'd0;
        fgpio_error  = fgpio_req;
        // IO.in.raw rs2,rd
        if ( fgpio_req && fgpio_funct7 == 7'b0000000 ) begin
            gpio_dir     = gpio_dir_1d & (~fgpio_rs2_val[`FGPIO_NUM-1:0]);
            fgpio_rd_val = gpio_in_val & fgpio_rs2_val[`FGPIO_NUM-1:0];
            fgpio_error  = 1'b0;
        end
        // IO.in.bit rs1,rs2,rd
        else if ( fgpio_req && fgpio_funct7 == 7'b0000001 ) begin
            gpio_dir     = gpio_dir_1d & (~(1<<fgpio_rs1_val));
            fgpio_rd_val = gpio_in_val[ fgpio_rs1_val[$clog2(`FGPIO_NUM)-1:0] ] << fgpio_rs2_val;
            fgpio_error  = 1'b0;
        end
        // IO.out.raw rs1,rs2,rd
        else if ( fgpio_req && fgpio_funct7 == 7'b1000000 ) begin
            gpio_dir     = gpio_dir_1d | fgpio_rs2_val[`FGPIO_NUM-1:0];
            gpio_out_val = (gpio_out_val_1d & ~fgpio_rs2_val[`FGPIO_NUM-1:0]) | (fgpio_rs1_val[`FGPIO_NUM-1:0] & fgpio_rs2_val[`FGPIO_NUM-1:0]);
            fgpio_error  = 1'b0;
        end
        // IO.out.and rs1,rs2,rd
        else if ( fgpio_req && fgpio_funct7 == 7'b1000001 ) begin
            gpio_dir     = { {RSV_BIT{1'b0}}, {`FGPIO_NUM{1'b1}} };
            gpio_out_val = fgpio_rs1_val[`FGPIO_NUM-1:0] & fgpio_rs2_val[`FGPIO_NUM-1:0];
            fgpio_error  = 1'b0;
        end
    end

    always_ff @(posedge clk_neg_i, negedge rst_ni) begin
        if(~rst_ni) begin
            gpio_dir_1d     <= {`FGPIO_NUM{1'b0}};
            gpio_out_val_1d <= {`FGPIO_NUM{1'b0}};
        end
        else if ( fgpio_req ) begin
            gpio_dir_1d     <= gpio_dir;
            gpio_out_val_1d <= gpio_out_val;
        end
    end

`endif

endmodule

