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
// Last Modified : 2026-08-07 11:12:50
// Description   : fast gpio control instruction extention  
// ----------------------------------------------------------------------

module FGPIO (
`ifdef SOPHON_EEI_GPIO
     input  logic                             clk_i
    ,input  logic                             clk_neg_i
    ,input  logic                             rst_ni
    ,input  logic                             fgpio_req
    ,input  logic [6:0]                       fgpio_funct7  
    ,input  logic [31:0]                      fgpio_rs_val[SOPHON_PKG::REGFILE_LEN-1:0]    
    ,output logic                             fgpio_ack     
    ,output logic                             fgpio_error   
    ,output logic [31:0]                      fgpio_rd_val
    ,output logic [`FGPIO_NUM-1:0]            gpio_dir     
    ,input  logic [`FGPIO_NUM-1:0]            gpio_in_val  
    ,output logic [`FGPIO_NUM-1:0]            gpio_out_val 
`endif
);


`ifdef SOPHON_EEI_GPIO

    // regular EEI instructions
    `define IO_IN_RAW            ( fgpio_funct7==7'b0000000 ) 
    `define IO_IN_BIT            ( fgpio_funct7==7'b0000001 ) 
    // TBD R-imm?
    `define IO_OUT_RAW           ( fgpio_funct7==7'b1000000 ) 
    `define IO_OUT_BIT           ( fgpio_funct7==7'b1000001 ) 
    `define IO_CFG_REG           ( fgpio_funct7==7'b1111111 ) 

    // configurable registers
    `define REG_SLL             5'd21

    logic [`FGPIO_NUM-1:0]  gpio_dir_1d;
    logic [`FGPIO_NUM-1:0]  gpio_out_val_1d;
    logic [31:0]            fgpio_rs1_val;
    logic [31:0]            fgpio_rs2_val;
    logic [31:0]            fgpio_rd1_val;

    logic                   is_io_cfg;
    logic                   cfg_sll,cfg_srl;
    logic [4:0]             cfg_addr;

    logic [`FGPIO_NUM-1:0]  pre_gpio_dir;
    logic [`FGPIO_NUM-1:0]  pre_gpio_out_val;


    // ----------------------------------------------------------------------
    //  fGPIO control
    // ----------------------------------------------------------------------
    assign fgpio_rs1_val = fgpio_rs_val[0];
    assign fgpio_rs2_val = fgpio_rs_val[1];
    assign fgpio_ack     = fgpio_req;
    
    // GPIO should reg out
    // TODO: merge with _1d
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni) begin
            gpio_dir     <= {`FGPIO_NUM{1'b0}};
            gpio_out_val <= {`FGPIO_NUM{1'b0}};
        end
        else if ( fgpio_req ) begin
            gpio_dir     <= pre_gpio_dir;
            gpio_out_val <= pre_gpio_out_val;
        end
    end

    always_comb begin
        pre_gpio_dir     = gpio_dir_1d ;
        pre_gpio_out_val = gpio_out_val_1d ;
        fgpio_rd1_val    = 32'd0;
        fgpio_error      = fgpio_req;
        // ----------------------------------------------------------------------
        //  Regular EEI instructions
        // ----------------------------------------------------------------------
        if ( fgpio_req && `IO_IN_RAW ) begin
            pre_gpio_dir     = gpio_dir_1d & (~fgpio_rs2_val[`FGPIO_NUM-1:0]);
            fgpio_rd1_val    = gpio_in_val & fgpio_rs2_val[`FGPIO_NUM-1:0];
            fgpio_error      = 1'b0;
        end
        else if ( fgpio_req && `IO_OUT_RAW ) begin
            pre_gpio_dir     = gpio_dir_1d | fgpio_rs2_val[`FGPIO_NUM-1:0];
            pre_gpio_out_val = (gpio_out_val_1d & ~fgpio_rs2_val[`FGPIO_NUM-1:0]) | (fgpio_rs1_val[`FGPIO_NUM-1:0] & fgpio_rs2_val[`FGPIO_NUM-1:0]);
            fgpio_error      = 1'b0;
        end
    `ifdef IO_IN_BIT
        else if ( fgpio_req && `IO_IN_BIT && cfg_sll ) begin
            pre_gpio_dir     = gpio_dir_1d & (~(1<<fgpio_rs2_val));
            fgpio_rd1_val    = {fgpio_rs1_val[30:0], gpio_in_val[ fgpio_rs2_val[$clog2(`FGPIO_NUM)-1:0] ]};
            fgpio_error      = 1'b0;
        end
        else if ( fgpio_req && `IO_IN_BIT && cfg_srl ) begin
            pre_gpio_dir     = gpio_dir_1d & (~(1<<fgpio_rs2_val));
            fgpio_rd1_val    = {gpio_in_val[ fgpio_rs2_val[$clog2(`FGPIO_NUM)-1:0] ],  fgpio_rs1_val[31:1] };
            fgpio_error      = 1'b0;
        end
    `endif
    `ifdef IO_OUT_BIT
        else if ( fgpio_req && `IO_OUT_BIT && cfg_sll ) begin
            pre_gpio_dir     = gpio_dir_1d | (1<<fgpio_rs2_val[`FGPIO_NUM-1:0]);
            pre_gpio_out_val = (gpio_out_val_1d & ~(1<<fgpio_rs2_val[`FGPIO_NUM-1:0])) | (fgpio_rs1_val[31] <<fgpio_rs2_val[`FGPIO_NUM-1:0]);
            fgpio_rd1_val    = {fgpio_rs1_val[30:0],fgpio_rs1_val[31]};
            fgpio_error      = 1'b0;
        end
        else if ( fgpio_req && `IO_OUT_BIT && cfg_srl ) begin
            pre_gpio_dir     = gpio_dir_1d | (1<<fgpio_rs2_val[`FGPIO_NUM-1:0]);
            pre_gpio_out_val = (gpio_out_val_1d & ~(1<<fgpio_rs2_val[`FGPIO_NUM-1:0])) | (fgpio_rs1_val[0] <<fgpio_rs2_val[`FGPIO_NUM-1:0]);
            fgpio_rd1_val    = {fgpio_rs1_val[0],fgpio_rs1_val[31:1]};
            fgpio_error      = 1'b0;
        end
    `endif
    end

    assign fgpio_rd_val = fgpio_rd1_val;


    // ----------------------------------------------------------------------
    //  Configuration register
    // ----------------------------------------------------------------------
    assign is_io_cfg = fgpio_req & `IO_CFG_REG;
    assign cfg_addr  = fgpio_rs1_val[4:0];

    // cfg_sll is used to set the shift direction of GPIO
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni)
            cfg_sll <= '1;
        else if ( is_io_cfg && (cfg_addr==`REG_SLL) )
            cfg_sll <= fgpio_rs2_val[0];
    end
    assign cfg_srl = ~cfg_sll;


    // ----------------------------------------------------------------------
    //  Keep GPIO stable after one fgpio instruction
    // ----------------------------------------------------------------------
    always_ff @(posedge clk_neg_i, negedge rst_ni) begin
        if(~rst_ni) begin
            gpio_dir_1d        <= {`FGPIO_NUM{1'b0}};
            gpio_out_val_1d    <= {`FGPIO_NUM{1'b0}};
        end
        else if ( fgpio_req ) begin
            gpio_dir_1d        <= gpio_dir;
            gpio_out_val_1d    <= gpio_out_val;
        end
    end

`endif

endmodule

