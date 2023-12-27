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
// Create Date   : 2022-08-23 16:21:07
// Last Modified : 2023-12-27 14:43:21
// Description   : 
// ----------------------------------------------------------------------


`define REG_CC0_BOOT  12'h000
`define REG_CC0_RST   12'h004
`define REG_CC1_BOOT  12'h010
`define REG_CC1_RST   12'h014

module APB_SYSCFG_REG
#(
    parameter APB_ADDR_WIDTH = 12
)
(
// APB
    input  logic                      PCLK,
    input  logic                      PRESETn,
    input  logic [APB_ADDR_WIDTH-1:0] PADDR,
    input  logic               [31:0] PWDATA,
    input  logic                      PWRITE,
    input  logic                      PSEL,
    input  logic                      PENABLE,
    output logic               [31:0] PRDATA,
    output logic                      PREADY,
    output logic                      PSLVERR,
// REG
    output logic [31:0]               cfg_cc0_boot,
    output logic                      cfg_cc0_rst,
    output logic [31:0]               cfg_cc1_boot,
    output logic                      cfg_cc1_rst
);



    // ----------------------------------------------------------------------
    // write logic
    // ----------------------------------------------------------------------
    logic wr_en;
    assign wr_en = PSEL & PENABLE & PWRITE ;
    logic [31:0]               cc0_rst;
    logic [31:0]               cc1_rst;

    always_ff @(posedge PCLK, negedge PRESETn) begin
        if(~PRESETn) begin
            cfg_cc0_boot  <= 32'h0001_0000;
        end
        else if ( wr_en && (PADDR==`REG_CC0_BOOT) )begin
            cfg_cc0_boot  <= PWDATA;
        end
    end

    always_ff @(posedge PCLK, negedge PRESETn) begin
        if(~PRESETn) begin
            cfg_cc1_boot  <= 32'h0001_0000;
        end
        else if ( wr_en && (PADDR==`REG_CC1_BOOT) )begin
            cfg_cc1_boot  <= PWDATA;
        end
    end


    always_ff @(posedge PCLK, negedge PRESETn) begin
        if(~PRESETn) begin
            cc0_rst  <= 32'h0000_0000;
        end
        else if ( wr_en && (PADDR==`REG_CC0_RST) )begin
            cc0_rst  <= PWDATA;
        end
    end
    assign cfg_cc0_rst = cc0_rst[0];

    always_ff @(posedge PCLK, negedge PRESETn) begin
        if(~PRESETn) begin
            cc1_rst  <= 32'h0000_0000;
        end
        else if ( wr_en && (PADDR==`REG_CC1_RST) )begin
            cc1_rst  <= PWDATA;
        end
    end
    assign cfg_cc1_rst = cc1_rst[0];


    // ----------------------------------------------------------------------
    // read logic
    // ----------------------------------------------------------------------
    logic rd_en;
    assign rd_en = PSEL & PENABLE & (~PWRITE) ;

    always_comb begin
      if (rd_en) begin
        unique case (PADDR)
            `REG_CC0_BOOT:
                PRDATA = cfg_cc0_boot;
            `REG_CC0_RST:
                PRDATA = cfg_cc0_rst;
            `REG_CC1_BOOT:
                PRDATA = cfg_cc1_boot;
            `REG_CC1_BOOT:
                PRDATA = cfg_cc1_rst;
            default:
                PRDATA = 'b0;
        endcase
      end
      else
        PRDATA = 'b0;
    end

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

endmodule


