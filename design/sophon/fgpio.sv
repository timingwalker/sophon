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
// Last Modified : 2025-03-13 15:48:43
// Description   : fast gpio control instruction extention  
// ----------------------------------------------------------------------

module FGPIO (
`ifdef SOPHON_EEI_GPIO
     input  logic                               clk_i
    ,input  logic                               clk_neg_i
    ,input  logic                               rst_ni
    ,input  logic                               eei_ext
    ,input  logic                               fgpio_req
    ,input  logic [6:0]                         fgpio_funct7  
    ,input  logic [4:0]                         fgpio_batch_len 
    ,input  logic [31:0]                        fgpio_rs_val[`EEI_RS_MAX-1:0]    
    ,output logic                               fgpio_ack     
    ,output logic                               fgpio_error   
    ,output logic [31:0]                        fgpio_rd_val[`EEI_RD_MAX-1:0]    
    ,output logic [`FGPIO_NUM-1:0]              gpio_dir     
    ,input  logic [`FGPIO_NUM-1:0]              gpio_in_val  
    ,output logic [`FGPIO_NUM-1:0]              gpio_out_val 
`endif
);

`ifdef SOPHON_EEI_GPIO

    `define INST_IO_IN_BIT

    // regular EEI instructions
    `define IO_IN_RAW            ( fgpio_funct7==7'b0000000 ) 
    `define IO_IN_BIT            ( fgpio_funct7==7'b0000001 ) 
    `define IO_OUT_RAW           ( fgpio_funct7==7'b1000000 ) 
    `define IO_OUT_BIT           ( fgpio_funct7==7'b1000001 ) 
    `define IO_CFG_REG           ( fgpio_funct7==7'b1111111 ) 
    // enhanced EEI instructions
    `define IO_OUT_BATCH         ( fgpio_funct7==7'b1100000 ) 
    `define IO_IN_BATCH          ( fgpio_funct7==7'b1100001 ) 

    // configurable registers
    `define REG_CNT             5'd0
    `define REG_CMP             5'd20
    `define REG_SLL             5'd21
    `define REG_CLK             5'd22

    localparam int unsigned RSV_BIT = 32 - `FGPIO_NUM;
    `define ITF_NUM 8
    `define CNT_WIDTH 5

    logic [`FGPIO_NUM-1:0]  gpio_dir_1d;
    logic [`FGPIO_NUM-1:0]  gpio_out_val_1d;
    logic [31:0]            fgpio_rs1_val;
    logic [31:0]            fgpio_rs2_val;
    logic [31:0]            fgpio_rd1_val;

    logic [`FGPIO_NUM-1:0]  clk_mask;
    logic [`FGPIO_NUM-1:0]  clk_mask_tmp;

    logic [`CNT_WIDTH-1:0]  cnt[`ITF_NUM-1:0];
    logic [`CNT_WIDTH-1:0]  cnt_cmp[`ITF_NUM-1:0];
    logic [1:0]             cnt_map[`ITF_NUM-1:0];
    logic                   cnt_inc[`ITF_NUM-1:0];
    logic                   cmp_out[`ITF_NUM-1:0];
    logic [31:0]            cnt_result;

    logic                   is_io_cfg;
    logic                   cfg_sll,cfg_srl;
    logic [31:0]            cfg_clk;
    logic [4:0]             cfg_addr;
    logic [4:0]             addr_cnt[`ITF_NUM-1:0];

    logic [31:0]            gpio_batch_out_val;
    logic [`FGPIO_NUM-1:0]  pre_gpio_dir;
    logic [`FGPIO_NUM-1:0]  pre_gpio_out_val;


    assign fgpio_rs1_val = fgpio_rs_val[0];
    assign fgpio_rs2_val = fgpio_rs_val[1];
    assign fgpio_ack     = fgpio_req;
    
    assign gpio_dir      = clk_mask | pre_gpio_dir;
    assign gpio_out_val  = clk_mask ^ pre_gpio_out_val;
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
    `ifdef INST_IO_IN_BIT
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
    `ifdef INST_IO_OUT_BIT
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
        else if ( fgpio_req && `IO_CFG_REG ) begin
            if ( cfg_addr==`REG_CMP ) fgpio_rd1_val = cnt_result;
            else                      fgpio_rd1_val = '0;
            fgpio_error      = 1'b0;
        end
        // ----------------------------------------------------------------------
        //  Enhanced EEI instructions
        // ----------------------------------------------------------------------
        else if ( fgpio_req && `IO_OUT_BATCH ) begin
            pre_gpio_dir     = gpio_dir_1d | fgpio_rs_val[1];
            pre_gpio_out_val = gpio_out_val_1d & ~fgpio_rs_val[1] | gpio_batch_out_val;
            fgpio_error      = 1'b0;
        end
        else if ( fgpio_req && `IO_IN_BATCH ) begin
            pre_gpio_dir     = gpio_dir_1d & (~fgpio_rs_val[1]);
            pre_gpio_out_val = gpio_out_val_1d ;
            fgpio_error      = 1'b0;
        end
    end


    // ----------------------------------------------------------------------
    //  GPIO batch instructions : process multiple GPIOs in one instructions
    // ----------------------------------------------------------------------
    logic gpio_batch_bit[`ITF_NUM-1:0];
    logic shift_bit[`ITF_NUM-1:0];

    // EEI channel 0  : x0
    // EEI channel 1  : mask, specifies which following channels are valid
    // EEI channel >1 : RX/TX buffer of each virtual interface
    //                  Each channel is spilt into two parts: 
    //                  -bit31:16 are used as RX buffer
    //                  -bit15:0  are used as TX buffer
    for (genvar m=0; m<`ITF_NUM; m++) begin : gen_gpio_batch_out_val
        assign gpio_batch_bit[m] = cfg_sll ? fgpio_rs_val[m+2][15] : fgpio_rs_val[m+2][0];
        assign gpio_batch_out_val[m*4+0] = 1'b0;
        assign gpio_batch_out_val[m*4+1] = fgpio_rs_val[1][m*4+1] ? gpio_batch_bit [m] : 1'b0;
        assign gpio_batch_out_val[m*4+2] = fgpio_rs_val[1][m*4+2] ? gpio_batch_bit [m] : 1'b0;
        assign gpio_batch_out_val[m*4+3] = fgpio_rs_val[1][m*4+3] ? gpio_batch_bit [m] : 1'b0;
    end

    for (genvar l=0; l<`ITF_NUM; l++) begin : gen_shift_bit
        always_comb begin
            shift_bit[l] = 1'b0;
            if (`IO_IN_BATCH) begin
                if      (fgpio_rs_val[1][l*4+1]) shift_bit[l] = gpio_in_val[l*4+1];
                else if (fgpio_rs_val[1][l*4+2]) shift_bit[l] = gpio_in_val[l*4+2];
                else if (fgpio_rs_val[1][l*4+3]) shift_bit[l] = gpio_in_val[l*4+3];
                else                             shift_bit[l] = 1'b0;
            end
        end
    end

    assign fgpio_rd_val[0] = eei_ext ? fgpio_rs_val[0] : fgpio_rd1_val;
    assign fgpio_rd_val[1] = eei_ext ? fgpio_rs_val[1] : '0;
    for (genvar l=0; l<`ITF_NUM; l++) begin : gen_rd_val
        always_comb begin
            fgpio_rd_val[l+2] = fgpio_rs_val[l+2];
            if ( fgpio_rs_val[1][l*4+1] | fgpio_rs_val[1][l*4+2] | fgpio_rs_val[1][l*4+3] ) begin
                if ( cfg_sll ) begin
                    if      ( `IO_OUT_BATCH ) fgpio_rd_val[l+2] = { fgpio_rs_val[l+2][31:16], fgpio_rs_val[l+2][14:0], shift_bit[l] };
                    else if ( `IO_IN_BATCH  ) fgpio_rd_val[l+2] = { fgpio_rs_val[l+2][30:16], shift_bit[l], fgpio_rs_val[l+2][15:0] };
                    else                      fgpio_rd_val[l+2] = fgpio_rs_val[l+2];
                end 
                else begin
                    if      ( `IO_OUT_BATCH ) fgpio_rd_val[l+2] = { fgpio_rs_val[l+2][31:16], shift_bit[l], fgpio_rs_val[l+2][15:1] };
                    else if ( `IO_IN_BATCH  ) fgpio_rd_val[l+2] = { shift_bit[l], fgpio_rs_val[l+2][31:17], fgpio_rs_val[l+2][15:0] };
                    else                      fgpio_rd_val[l+2] = fgpio_rs_val[l+2];
                end
            end
            else               fgpio_rd_val[l+2] = fgpio_rs_val[l+2];
        end
    end

    // ------------------------------------------------
    //  io_batch specifies which GPIO pins should 
    //  be processed in batch instruction
    // ------------------------------------------------
    // e.g. io_batch_mask_raw[0] = 10010110  io_batch_mask_onehot[0] = 00000010  io_batch_mask_binary = 1
    //      io_batch_mask_raw[1] = 10010100  io_batch_mask_onehot[1] = 00000100  io_batch_mask_binary = 2
    //      io_batch_mask_raw[2] = 10010000  io_batch_mask_onehot[2] = 00010000  io_batch_mask_binary = 4
    //      ......
    // ------------------------------------------------
    // io_batch_mask_raw[0] is also reused to generate clk_mask
    // ------------------------------------------------

    // always_comb begin
    //     if ( fgpio_req & eei_ext & `IO_IN_BATCH )
    //         io_batch_mask_raw[0] = cfg_in;
    //     else if ( fgpio_req & eei_ext & `IO_OUT_BATCH )
    //         io_batch_mask_raw[0] = cfg_out;
    //     else if ( fgpio_req & ~eei_ext & (`IO_OUT_RAW|`IO_IN_RAW) )
    //         io_batch_mask_raw[0] = fgpio_rs2_val;
    //     else if ( fgpio_req & ~eei_ext & (`IO_OUT_BIT|`IO_IN_BIT) )
    //         io_batch_mask_raw[0] = 1 << fgpio_rs2_val;
    //     else
    //         io_batch_mask_raw[0] = '0;
    // end
    // for (genvar k=1; k<=`EEI_RS_MAX-2; k++) begin : gen_io_mask_raw
    //     assign io_batch_mask_raw[k] = io_batch_mask_raw[k-1] & (~io_batch_mask_onehot[k-1]);
    // end

    // for (genvar j=0; j<=`EEI_RS_MAX-2; j++) begin : gen_io_mask_onehot
    //     for (genvar i=0; i<32; i++) begin : gen_io_mask_onehot_bit
    //         if (i==0) 
    //             assign io_batch_mask_onehot[j][i] = io_batch_mask_raw[j][i];
    //         else
    //             assign io_batch_mask_onehot[j][i] = io_batch_mask_raw[j][i] & (~(|io_batch_mask_onehot[j][i-1:0]));
    //     end
    // end

    // for (genvar p=0; p<=`EEI_RS_MAX-2; p++) begin : gen_io_mask_binary
    //     onehot_to_bin #(.ONEHOT_WIDTH(32)) U_ONEHOT_TO_BIN (
    //         .onehot ( io_batch_mask_onehot[p] ),
    //         .bin    ( io_batch_mask_binary[p] )
    //     );
    // end

    // For batch instructions, the first EEI channel is used as a mask to specify
    // which GPIOs are controlled by this instruction, so the effective EEI channels
    // to tranmit GPIO value is EEI_RS_MAX-2
    // the GPIO output value is stored in io_batch_out_val[`EEI_RS_MAX-2]
    //  for (genvar m=0; m<=`EEI_RS_MAX-2; m++) begin : gen_batch_out_val
    //      if (m==0) 
    //          always_comb begin
    //              if ( `IO_OUT_BATCH && cfg_sll ) 
    //                  io_batch_out_val[m] = io_batch_mask_onehot[m] & fgpio_rs_val[0] & {32{fgpio_rs_val[m+1][31]}};
    //              else if ( `IO_OUT_BATCH && cfg_srl ) 
    //                  io_batch_out_val[m] = io_batch_mask_onehot[m] & fgpio_rs_val[0] & {32{fgpio_rs_val[m+1][0]}};
    //              else
    //                  io_batch_out_val[m] = 32'd0;
    //          end
    //      else
    //          always_comb begin
    //              if ( `IO_OUT_BATCH && cfg_sll ) 
    //                  io_batch_out_val[m] = io_batch_out_val[m-1] | io_batch_mask_onehot[m] & fgpio_rs_val[0] & {32{fgpio_rs_val[m+1][31]}};
    //              else if ( `IO_OUT_BATCH && cfg_srl ) 
    //                  io_batch_out_val[m] = io_batch_out_val[m-1] | io_batch_mask_onehot[m] & fgpio_rs_val[0] & {32{fgpio_rs_val[m+1][0]}};
    //              else
    //                  io_batch_out_val[m] = 32'd0;
    //          end
    //  end
    //assign io_batch_out_val[`EEI_RS_MAX-2]=gpio_batch_out_val;

    // // enhanced EEI: generate rd channels
    // assign fgpio_rd_val[0] = eei_ext ? fgpio_rs_val[0] : fgpio_rd1_val;
    // for (genvar l=1; l<`EEI_RD_MAX; l++) begin : gen_rd_val
    //     always_comb begin
    //         fgpio_rd_val[l] = 32'd0;
    //         if ( fgpio_req & eei_ext & fgpio_rs_val[0][eei_out_map[l-1]] ) begin
    //             // output channel
    //             if      ( `IO_OUT_BATCH && cfg_sll ) fgpio_rd_val[l] = {fgpio_rs_val[l][30:0],fgpio_rs_val[l][31]};
    //             else if ( `IO_OUT_BATCH && cfg_srl ) fgpio_rd_val[l] = {fgpio_rs_val[l][0],fgpio_rs_val[l][31:1]};
    //             // input channel
    //             else if ( `IO_IN_BATCH && cfg_sll  ) fgpio_rd_val[l] = {fgpio_rs_val[l][30:0],gpio_in_val[eei_in_map[l-1]]};
    //             else if ( `IO_IN_BATCH && cfg_srl  ) fgpio_rd_val[l] = {gpio_in_val[eei_in_map[l-1]],fgpio_rs_val[l][31:1]};
    //         end
    //         // not enable
    //         else begin
    //             fgpio_rd_val[l] = fgpio_rs_val[l][31:0];
    //         end
    //     end
    // end

    // ----------------------------------------------------------------------
    //  counter
    // ----------------------------------------------------------------------

    logic [3:0] cnt_en[`ITF_NUM-1:0];

    for (genvar q=0; q<`ITF_NUM; q++) begin : gen_cnt_map

        assign addr_cnt[q] = `REG_CNT + q;

        always_ff @(posedge clk_i, negedge rst_ni) begin
            if(~rst_ni) 
                {cnt[q],cnt_cmp[q], cnt_map[q]} <= '0;
            else if ( is_io_cfg && (cfg_addr==addr_cnt[q]) )
                {cnt[q],cnt_cmp[q], cnt_map[q]} <= fgpio_rs2_val[11:0];
            else if ( cmp_out[q] & cnt_inc[q] )
                cnt[q] <= cnt[q] + 5'd1;
        end

        assign cmp_out[q] = cnt[q]<cnt_cmp[q];

        assign cnt_en[q] = fgpio_rs_val[1][q*4+:4];
        always_comb begin
            cnt_inc[q] = 0;
            if ( fgpio_req & (`IO_IN_BATCH|`IO_OUT_BATCH) )
                cnt_inc[q] = cnt_en[q][cnt_map[q]];
            else if ( fgpio_req & (`IO_IN_BIT|`IO_OUT_BIT) )
                cnt_inc[q] = (cnt_map[q]==fgpio_rs2_val);
        end

        assign cnt_result[q*4+0] = (cnt_map[q]==2'b00) ? cmp_out[q] : 1'b0;
        assign cnt_result[q*4+1] = (cnt_map[q]==2'b01) ? cmp_out[q] : 1'b0;
        assign cnt_result[q*4+2] = (cnt_map[q]==2'b10) ? cmp_out[q] : 1'b0;
        assign cnt_result[q*4+3] = (cnt_map[q]==2'b11) ? cmp_out[q] : 1'b0;

    end
    

    // ----------------------------------------------------------------------
    //  clock mask
    // ----------------------------------------------------------------------
    // clk_mask specifies which GPIO should be flipped:
    //   1. it is mapped as a clock pin ( check cfg_clk table )
    //   2. the corresponding data pin is configured ( check io_batch_mask_raw[0] or rs2 )
    // ----------------------------------------------------------------------
    for (genvar o=0; o<`ITF_NUM; o++) begin : gen_clk_mask_tmp
        assign clk_mask_tmp[o*4+0] = (cfg_clk[o*4+1]&fgpio_rs_val[1][o*4+1]) | (cfg_clk[o*4+2]&fgpio_rs_val[1][o*4+2]) | (cfg_clk[o*4+3]&fgpio_rs_val[1][o*4+3]) ;
        assign clk_mask_tmp[o*4+1] = 1'b0;
        assign clk_mask_tmp[o*4+2] = 1'b0;
        assign clk_mask_tmp[o*4+3] = 1'b0;
    end
    assign clk_mask = ( fgpio_req & (`IO_OUT_BATCH|`IO_IN_BATCH) ) ? clk_mask_tmp : '0;

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

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni)
            cfg_clk <= '0;
        else if ( is_io_cfg && (cfg_addr==`REG_CLK) )
            cfg_clk <= fgpio_rs2_val;
    end

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

