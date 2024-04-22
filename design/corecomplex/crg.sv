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
// Create Date   : 2024-04-18 15:29:26
// Last Modified : 2024-04-18 16:42:45
// Description   : 
// ----------------------------------------------------------------------

module CRG(
   input  logic                        clk_i
  ,input  logic                        rst_ni
  ,input  logic                        rst_soft_i
  ,output logic                        clk_neg_o
  ,output logic                        rstn_sync_o
  ,output logic                        rstn_comb_sync_o
);

    logic rst_comb;

    STD_WRAP_CKINV U_CLK_INV 
    ( 
        .in_i         ( clk_i         ) ,
        .zn_o         ( clk_neg_o     ) 
    );

    RST_SYNC U_RST_SYNC
    (
        .clk_i        ( clk_i         ) ,
        .rst_ni       ( rst_ni        ) ,
        .rstn_sync_o  ( rstn_sync_o   )
     );


    STD_WRAP_CKAND U_CLK_AND
    ( 
        .in1_i        ( rst_ni        ) ,
        .in2_i        ( rst_soft_i    ) ,
        .z_o          ( rst_comb      ) 
    );

    RST_SYNC U_RST_COMB_SYNC
    (
        .clk_i        ( clk_i            ) ,
        .rst_ni       ( rst_comb         ) ,
        .rstn_sync_o  ( rstn_comb_sync_o ) 
     );


endmodule

