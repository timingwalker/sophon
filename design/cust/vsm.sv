// ----------------------------------------------------------------------
// Copyright 2026 TimingWalker
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
// Create Date   : 2026-06-09 15:40:00
// Last Modified : 2026-08-21 13:21:41
// Description   : virtual state machine through CLIC interface
// ----------------------------------------------------------------------

module VSM(
`ifdef SOPHON_EEI_VSM
     input  logic                             clk_i
    ,input  logic                             rst_ni
    ,input  logic                             vsm_req
    ,input  logic [6:0]                       vsm_funct7  
    ,input  logic [31:0]                      vsm_rs_val[SOPHON_PKG::REGFILE_LEN-1:0]    
    ,output logic                             vsm_ack     
    ,output logic                             vsm_error   
    ,output logic [31:0]                      vsm_rd_val
    ,output logic                             clic_irq_req_o
    ,output logic                             clic_irq_shv_o
    ,output logic [4:0]                       clic_irq_id_o
    ,output logic [7:0]                       clic_irq_level_o
    ,input  logic                             clic_irq_ack_i
    ,input  logic [7:0]                       clic_irq_intthresh_i
    ,input  logic                             clic_mnxti_clr_i
    ,input  logic [4:0]                       clic_mnxti_id_i
`endif
);


`ifdef SOPHON_EEI_VSM

    localparam HW_NUM = 6;

    logic [31:0]               mtime;
    logic [31:0]               mtimecmp[HW_NUM-1:0];
    logic [4:0]                state[HW_NUM-1:0];
    logic                      is_vsm_start;
    logic                      is_vsm_stop;
    logic                      is_vsm_set_cmp;
    logic                      is_vsm_set_sm;
    logic                      vsm_counting;

    // regular EEI instructions
    `define VSM_START           ( vsm_funct7==7'b0000000 ) 
    `define VSM_STOP            ( vsm_funct7==7'b0000001 ) 
    `define VSM_SET_CMP         ( vsm_funct7==7'b0000010 ) 
    `define VSM_SET_SM          ( vsm_funct7==7'b0000011 ) 

    assign is_vsm_start   = ( vsm_req & `VSM_START   ) ;
    assign is_vsm_stop    = ( vsm_req & `VSM_STOP    ) ;
    assign is_vsm_set_cmp = ( vsm_req & `VSM_SET_CMP ) ;
    assign is_vsm_set_sm  = ( vsm_req & `VSM_SET_SM  ) ;


    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni) begin
            vsm_counting <= 1'b0;
        end
        else if ( is_vsm_start )begin
            vsm_counting <= 1'b1;
        end
        else if ( is_vsm_stop )begin
            vsm_counting <= 1'b0;
        end
    end

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni) begin
            mtime  <= 32'd1;
        end
        else if ( is_vsm_start )begin
            mtime  <= 32'd1;
        end
        // TODO: 
        //else if ( mtime==mtimecmp )begin
        else if ( mtime==32'd217 )begin
            mtime  <= 32'd1;
        end
        else if ( vsm_counting )begin
            mtime  <= mtime + 1;
        end
    end

for (genvar i=0; i<HW_NUM; i++) begin

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni) begin
            mtimecmp[i]  <= '1;
        end
        else if ( is_vsm_set_cmp && (vsm_rs_val[1]==i) )begin
            mtimecmp[i]  <= vsm_rs_val[0]; // TODO: 
        end
    end

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni) begin
            state[i]  <= '1;
        end
        else if ( is_vsm_set_sm && (vsm_rs_val[1]==i) )begin
            state[i]  <= vsm_rs_val[0]; // TODO: 
        end
    end

end





    assign clic_irq_level_o = 5'd255;

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni) begin
            clic_irq_req_o <= '0;
            clic_irq_shv_o <= '0;
            clic_irq_id_o <= '0;
        end
        else if ( clic_irq_ack_i ) begin
            clic_irq_req_o <= '0;
            clic_irq_shv_o <= clic_irq_shv_o;
            clic_irq_id_o <= clic_irq_id_o;
        end
        else if ( mtime==mtimecmp[0] ) begin
            clic_irq_req_o <= '1;
            clic_irq_shv_o <= 1'b1;
            clic_irq_id_o <= state[0];
        end
        else if ( mtime==mtimecmp[1] ) begin
            clic_irq_req_o <= '1;
            clic_irq_shv_o <= 1'b1;
            clic_irq_id_o <= state[1];
        end
    end



`endif

endmodule

