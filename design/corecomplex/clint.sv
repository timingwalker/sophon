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
// Create Date   : 2024-08-05 11:14:00
// Last Modified : 2024-08-05 15:48:14
// Description   : 
// ----------------------------------------------------------------------


`define REG_MTIME    12'h000
`define REG_MTIMECMP 12'h004
`define REG_MSIP     12'h008

module CLINT
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
// 
    output logic                      msi_o,
    output logic                      mti_o
);



    // ----------------------------------------------------------------------
    // write logic
    // ----------------------------------------------------------------------
    logic wr_en;
    assign wr_en = PSEL & PENABLE & PWRITE ;
    logic [31:0]               mtime;
    logic [31:0]               mtimecmp;
    logic [31:0]               msip;

    always_ff @(posedge PCLK, negedge PRESETn) begin
        if(~PRESETn) begin
            mtime  <= '0;
        end
        else if ( wr_en && (PADDR==`REG_MTIME) )begin
            mtime  <= PWDATA;
        end
        else begin
            mtime  <= mtime + 1;
        end
    end

    always_ff @(posedge PCLK, negedge PRESETn) begin
        if(~PRESETn) begin
            mtimecmp  <= '1;
        end
        else if ( wr_en && (PADDR==`REG_MTIMECMP) )begin
            mtimecmp  <= PWDATA;
        end
    end

    always_ff @(posedge PCLK, negedge PRESETn) begin
        if(~PRESETn) begin
            msip  <= '0;
        end
        else if ( wr_en && (PADDR==`REG_MSIP) )begin
            msip  <= PWDATA;
        end
    end

    assign mti_o = (mtime>=mtimecmp) ? 1'b1 : 1'b0;
    assign msi_o = msip[0];

    // ----------------------------------------------------------------------
    // read logic
    // ----------------------------------------------------------------------
    logic rd_en;
    assign rd_en = PSEL & PENABLE & (~PWRITE) ;

    always_comb begin
      if (rd_en) begin
        unique case (PADDR)
            `REG_MTIME:
                PRDATA = mtime;
            `REG_MTIMECMP:
                PRDATA = mtimecmp;
            `REG_MSIP:
                PRDATA = msip;
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


