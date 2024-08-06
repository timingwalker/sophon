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
// Create Date   : 2023-03-21 11:31:29
// Last Modified : 2024-07-25 15:41:21
// Description   : Demux inst interface    
//                 NOTE: the addr decode granularity is 4KB
// ----------------------------------------------------------------------

module INST_ITF_DEMUX #(
    parameter int unsigned      CH1_NEG_BASE = 32'h10000,
    parameter int unsigned      CH1_NEG_END  = 32'h1ffff,
    parameter int unsigned      CH2_POS_BASE = 32'h0,
    parameter int unsigned      CH2_POS_END  = 32'h0fff
)(
     input  logic                        clk_i
    ,input  logic                        rst_ni
    ,input  logic                        clk_neg_i
    ,input  logic                        rst_neg_ni
    // From core, negedge
    ,input  logic                        inst_core_req_i       
    ,input  logic [31:0]                 inst_core_addr_i      
    ,output logic                        inst_core_error_o     
    ,output logic                        inst_core_ack_o      
    ,output logic [31:0]                 inst_core_data_o    
    // Demux 1, to L1 IRAM, negedge, access in 1 cycle
    ,output logic                        inst_neg_req_o       
    ,output logic [31:0]                 inst_neg_addr_o      
    ,input  logic                        inst_neg_error_i     
    ,input  logic                        inst_neg_ack_i      
    ,input  logic [31:0]                 inst_neg_data_i    
    // Demux 2, posedge, access in several cycles
    ,output logic                        inst_pos_req_o       
    ,output logic [31:0]                 inst_pos_addr_o      
    ,input  logic                        inst_pos_error_i     
    ,input  logic                        inst_pos_ack_i      
    ,input  logic [31:0]                 inst_pos_data_i    
);


    logic        inst_pos_ack_toneg;
    logic [31:0] inst_pos_data_1d;
    logic [31:0] inst_pos_error_1d;
    logic [31:0] inst_core_addr_topos;
    logic        inst_neg_ack_topos;


    // ----------------------------------------------------------------------
    //  Channel 1: to ITCM, combinatorial path, negedge
    // ----------------------------------------------------------------------
    always_comb begin
        if ( (inst_core_addr_i[31:12]>=CH1_NEG_BASE[31:12]) && (inst_core_addr_i[31:12]<=CH1_NEG_END[31:12]) )
            inst_neg_req_o = inst_core_req_i;
        else
            inst_neg_req_o = 1'b0;
    end

    assign inst_neg_addr_o = inst_core_addr_i;


    // ----------------------------------------------------------------------
    //  Channel 2: to external memory, sequential path, posedge
    // ----------------------------------------------------------------------
    always @(posedge clk_i or negedge rst_ni) begin
    	if(~rst_ni) 
            inst_pos_req_o <= 1'b0;
        else if ( inst_pos_ack_i )
            inst_pos_req_o <= 1'b0;
        else if ( inst_core_req_i & ((inst_core_addr_i[31:12]>=CH2_POS_BASE[31:12])&&(inst_core_addr_i[31:12]<=CH2_POS_END[31:12])) )
            inst_pos_req_o <= 1'b1;
        else
            inst_pos_req_o <= 1'b0;
    end

    always @(posedge clk_i or negedge rst_ni) begin
    	if(~rst_ni) 
            inst_core_addr_topos <= 32'd0;
        else
            inst_core_addr_topos <= inst_core_addr_i;
    end
    assign inst_pos_addr_o = inst_core_addr_topos;


    // ----------------------------------------------------------------------
    //  Response signals
    // ----------------------------------------------------------------------
    // Timing requirements of the Sophon core:
    //  -> inst_req araise at negedge
    //  <- inst_ack should aliagn to inst_req at negedge
    //  <- inst_data/error is valid at subsequent posedge following inst_ack
    // ----------------------------------------------------------------------
    // These requirements come from the initial design consideration that
    // Sophon send inst_req half a cycle ahead, and the memory return data 
    // at the subsequent posedge clock
    // ----------------------------------------------------------------------

    // -----------------------------------
    //  ack to core: negedge
    // -----------------------------------
    always_comb begin
        if ( inst_core_req_i & ((inst_core_addr_i[31:12]>=CH2_POS_BASE[31:12])&&(inst_core_addr_i[31:12]<=CH2_POS_END[31:12])) ) begin
            inst_core_ack_o = inst_pos_ack_toneg;
        end
        else if ( inst_core_req_i & ((inst_core_addr_i[31:12]>=CH1_NEG_BASE[31:12])&&(inst_core_addr_i[31:12]<=CH1_NEG_END[31:12])) ) begin
            inst_core_ack_o = inst_neg_ack_i;
        end
        else if ( inst_core_req_i ) begin
            inst_core_ack_o = 1'b1;
        end
        else begin
            inst_core_ack_o = 1'b0;
        end
    end

    //  Channel 2 ack signal, change form posedge to negedge
    always @(posedge clk_neg_i or negedge rst_neg_ni) begin
    	if(~rst_neg_ni) begin
            inst_pos_ack_toneg <= 1'b0;
        end
        else begin
            inst_pos_ack_toneg <= inst_pos_ack_i;
        end
    end

    // -----------------------------------
    //  data/error to core: posedge
    // -----------------------------------
    always @(posedge clk_i or negedge rst_neg_ni) begin
    	if(~rst_neg_ni) begin
            inst_neg_ack_topos <= 1'b0;
        end
        else begin
            inst_neg_ack_topos <= inst_neg_ack_i;
        end
    end

    always @(posedge clk_i or negedge rst_neg_ni) begin
    	if(~rst_neg_ni) begin
            inst_pos_data_1d  <= 32'd0;
            inst_pos_error_1d <= 1'b0;
        end
        else if (inst_pos_req_o & inst_pos_ack_i) begin
            inst_pos_data_1d  <= inst_pos_data_i;
            inst_pos_error_1d <= inst_pos_error_i;
        end
    end

    assign inst_core_data_o  = inst_neg_ack_topos ? inst_neg_data_i  : inst_pos_data_1d;
    assign inst_core_error_o = inst_neg_ack_topos ? inst_neg_error_i : inst_pos_error_1d;


`ifndef VERILATOR

    inst_pos_req_overlap: assert property ( @(posedge clk_i) disable iff (~rst_ni) 
                                       ((inst_pos_req_o==1'b1) |-> (inst_neg_req_o!=1'b1)) ) 
                            else $fatal(1,"neg_req overwrite pos_req");

    inst_neg_req_overlap: assert property ( @(posedge clk_i) disable iff (~rst_ni) 
                                       ((inst_neg_req_o==1'b1) |-> (inst_pos_req_o!=1'b1)) ) 
                            else $fatal(1,"pos_req overwrite neg_req");

`endif

endmodule

