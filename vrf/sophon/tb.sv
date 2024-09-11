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
// Create Date   : 2022-11-04 10:19:28
// Last Modified : 2024-09-11 17:06:57
// Description   : 
// ----------------------------------------------------------------------

`ifndef VERILATOR
    `timescale 1ns/10ps
`endif

module tb(
     input logic    clk_i
    ,input logic    rst_ni
);

    logic clk;
    logic rst_n;

    `ifdef VERILATOR
        assign clk = clk_i;
        assign clk_neg = ~clk;
        assign rst_n = rst_ni;
    `else
        clk_rst_gen #(
            .ClkPeriod    ( 10ns ),
            .RstClkCycles ( 5    )
        ) u_clk_gen 
        (
            .clk_o  (clk),
            .rst_no (rst_n)
        );
    `endif


    SOPHON_TOP u_dut
    (
          .clk_i                  ( clk          ) 
         ,.clk_neg_i              ( clk_neg      ) 
         ,.rst_ni                 ( rst_n        ) 
         ,.rst_soft_ni            ( rst_n        ) 
         ,.bootaddr_i             ( 32'h80000000 ) 
         ,.hart_id_i              ( 3'd0         ) 
         ,.irq_mei_i              ( 1'b0         ) 
         ,.irq_mti_i              ( 1'b0         ) 
         ,.irq_msi_i              ( 1'b0         ) 
         ,.dm_req_i               ( 1'b0         ) 
         `ifdef SOPHON_EXT_INST
         ,.inst_ext_req_o         (              ) 
         ,.inst_ext_addr_o        (              ) 
         ,.inst_ext_ack_i         ( 1'b0         ) 
         ,.inst_ext_rdata_i       ( '0           ) 
         ,.inst_ext_error_i       ( 1'b1         ) 
         `endif
         `ifdef SOPHON_EXT_DATA
         ,.data_req_o             (              ) 
         ,.data_we_o              (              ) 
         ,.data_addr_o            (              ) 
         ,.data_wdata_o           (              ) 
         ,.data_amo_o             (              ) 
         ,.data_strb_o            (              ) 
         ,.data_valid_i           ( 1'b0         ) 
         ,.data_error_i           ( 1'b1         ) 
         ,.data_rdata_i           ( 32'd0        ) 
         `endif
         `ifdef SOPHON_EXT_ACCESS
         ,.ext_req_i              ( '0           ) 
         ,.ext_we_i               ( '0           ) 
         ,.ext_addr_i             ( '0           ) 
         ,.ext_wdata_i            ( '0           ) 
         ,.ext_ack_o              (              ) 
         ,.ext_error_o            (              ) 
         ,.ext_rdata_o            (              ) 
         `endif
         `ifdef SOPHON_CLIC
         ,.clic_irq_req_i         ( '0           ) 
         ,.clic_irq_shv_i         ( '0           ) 
         ,.clic_irq_id_i          ( '0           ) 
         ,.clic_irq_level_i       ( '0           ) 
         ,.clic_irq_ack_o         (              ) 
         ,.clic_irq_intthresh_o   (              ) 
         ,.clic_mnxti_clr_o       (              ) 
         ,.clic_mnxti_id_o        (              ) 
         `endif
         `ifdef SOPHON_EEI_GPIO
         ,.gpio_dir_o             (              ) 
         ,.gpio_in_val_i          ( '0           ) 
         ,.gpio_out_val_o         (              ) 
    `endif
    );




    // ----------------------------------------------------------------------
    //  Proload memory
    // ----------------------------------------------------------------------

    `ifndef SMIC55LL
        `define ITCM(bankaddr) u_dut.U_ITCM.gen_spilt_ram[``bankaddr``].U_BW_SP_RAM.ram_block
        `define DTCM(bankaddr) u_dut.U_DTCM.gen_spilt_ram[``bankaddr``].U_BW_SP_RAM.ram_block
    `else
        //`define ITCM(addr) u_dut.u_itcm.gen_spilt_ram[0].u_tcm_ram.mem_array[``addr``]
        //`define DTCM(addr) u_dut.u_dtcm.gen_spilt_ram[0].u_tcm_ram.mem_array[``addr``]
    `endif

    localparam int unsigned ITCM_OFFSET = SOPHON_PKG::ITCM_OFFSET;
    localparam int unsigned DTCM_OFFSET = SOPHON_PKG::DTCM_OFFSET;
    localparam int unsigned BANK_NUM    = 16;

    localparam int unsigned TMP_RAM_SIZE = DTCM_OFFSET + 2048*BANK_NUM -1;
    reg [7:0] cc0_ram [0:TMP_RAM_SIZE];
    reg [8*40:0] testName;

    integer i, by;
    
    initial begin
        if ( $value$plusargs("CC0=%s",testName ) ) begin
            $display("TC=%s\n",  testName);
            $readmemh(testName, cc0_ram);   
        end
    end

    genvar k;
    generate
        // per bank
        for (k=0; k<BANK_NUM; k=k+1) begin
            initial begin
                // 1024*32bit=2KB
                for ( i = 0; i < 1024; i = i + 1 ) begin
                    for ( by = 0; by < 4; by = by + 1 ) begin
                        `ITCM(k)[i][by*8+:8] = cc0_ram[ ITCM_OFFSET + k*4096 + i*4+by];
                    end
                end
            end
        end
        // per bank
        for (k=0; k<BANK_NUM; k=k+1) begin
            initial begin
                // 1024*32bit=2KB
                for ( i = 0; i < 1024; i = i + 1 ) begin
                    for ( by = 0; by < 4; by = by + 1 ) begin
                        `DTCM(k)[i][by*8+:8] = cc0_ram[ DTCM_OFFSET + k*4096 + i*4+by];
                    end
                end
            end
        end
    endgenerate



    // ----------------------------------------------------------------------
    //  Finish Check
    // ----------------------------------------------------------------------

    logic  is_ecall;
    logic [31:0] gp;

    assign is_ecall = u_dut.U_SOPHON.is_ecall;
    assign gp       = u_dut.U_SOPHON.regfile[3];


    `ifdef VERILATOR

        localparam int unsigned TO_BIT = 18;

        logic [7:0]        finish_cnt;
        logic [TO_BIT-1:0] timeout_cnt;

        always_ff @(posedge clk, negedge rst_n) begin
            if(~rst_n) 
                timeout_cnt <= {TO_BIT{1'b0}};
            else if ( timeout_cnt<{TO_BIT{1'b1}})
                timeout_cnt <= timeout_cnt + 1;
        end

        always_ff @(posedge clk, negedge rst_n) begin
            if(~rst_n) 
                finish_cnt <= 8'h00;
            else if ( is_ecall==1'b1 )
                finish_cnt <= finish_cnt + 8'h1;
            else if ( finish_cnt!=8'h0 && finish_cnt<=8'hff )
                finish_cnt <= finish_cnt + 8'h1;
        end

        always_ff @(posedge clk) begin
            if ( &finish_cnt ) begin
                if ( gp == 32'd1 ) begin
                    $display($realtime, ": Core %0s success\n",  testName);
                    $display($realtime, ": Testcase PASS!!!\n");
                    $finish;
                end
                else begin
                    $display($realtime, ": Core %0s FAIL\n",  testName);
                    $finish;
                end
            end
            else if ( &timeout_cnt ) begin
                $display($realtime, ": Core %0s TIMEOUT!!!\n",  testName);
                $finish;
            end
        end

    `else


    `endif



    `ifndef VERILATOR
        initial begin
          $fsdbDumpfile("test.fsdb"); 
          $fsdbDumpvars;
          $fsdbDumpMDA(0, tb); 
        end
    `endif


endmodule

