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
// Create Date   : 2022-11-04 10:19:28
// Last Modified : 2024-08-09 11:02:35
// Description   : 
// ----------------------------------------------------------------------

`include "axi/typedef.svh"
`include "axi/assign.svh"

`ifndef VERILATOR
    `timescale 1ns/10ps
`endif

module tb();

    // ----------------------------------------------------------------------
    //  clock reset
    // ----------------------------------------------------------------------
    logic clk;
    logic rst_n;

    `ifdef VERILATOR
        assign clk   = clk_i;
        assign rst_n = rst_ni;
    `else
        clk_rst_gen #(
            .ClkPeriod    ( 25ns ),
            .RstClkCycles ( 5    )
        ) u_clk_gen 
        (
            .clk_o  (clk   ) ,
            .rst_no (rst_n ) 
        );
    `endif


    // ----------------------------------------------------------------------
    //  DUT
    // ----------------------------------------------------------------------
    logic tck; 
    logic tms; 
    logic trst_n; 
    logic tdi; 
    logic tdo; 
    logic tdo_oe; 
    logic dut_uart_tx;
    logic dut_uart_rx;
    logic irq_mei;
`ifdef SOPHON_EEI_GPIO
    logic [`FGPIO_NUM-1:0] gpio_dir;
    logic [`FGPIO_NUM-1:0] gpio_in_val;
    logic [`FGPIO_NUM-1:0] gpio_out_val;
`endif
`ifdef SOPHON_CLIC  
    logic       clic_irq_req;
    logic       clic_irq_shv;
    logic [4:0] clic_irq_id;
    logic [7:0] clic_irq_level;
    logic       clic_irq_ack;
    logic [7:0] clic_irq_intthresh;
    logic       clic_mnxti_clr;
    logic [4:0] clic_mnxti_id;
`endif

    CC_ITF_PKG::xbar_slv_port_d64_req_t   axi_slv_port_req;
    CC_ITF_PKG::xbar_slv_port_d64_resps_t axi_slv_port_rsp;

    CC_ITF_PKG::xbar_mst_port_d64_req_t   axi_mst_port_req;
    CC_ITF_PKG::xbar_mst_port_d64_resps_t axi_mst_port_rsp;


    CORE_COMPLEX u_dut
    (
          .clk_i                      ( clk                ) 
          ,.rst_ni                    ( rst_n              ) 
          ,.hart_id_i                 ( '0                 ) 
          ,.irq_mei_i                 ( irq_mei            ) 
          `ifdef SOPHON_CLIC  
          ,.clic_irq_req_i            ( clic_irq_req       ) 
          ,.clic_irq_shv_i            ( clic_irq_shv       ) 
          ,.clic_irq_id_i             ( clic_irq_id        ) 
          ,.clic_irq_level_i          ( clic_irq_level     ) 
          ,.clic_irq_ack_o            ( clic_irq_ack       ) 
          ,.clic_irq_intthresh_o      ( clic_irq_intthresh ) 
          ,.clic_mnxti_clr_o          ( clic_mnxti_clr     ) 
          ,.clic_mnxti_id_o           ( clic_mnxti_id      ) 
          ,.clic_apb_req_o            (                    ) 
          ,.clic_apb_rsp_i            ( '0                 ) 
          `endif
          `ifdef SOPHON_EEI_GPIO
          ,.gpio_dir_o                ( gpio_dir           ) 
          ,.gpio_in_val_i             ( gpio_in_val        ) 
          ,.gpio_out_val_o            ( gpio_out_val       ) 
          `endif
          ,.tck_i                     ( tck                ) 
          ,.tms_i                     ( tms                ) 
          ,.trst_n_i                  ( trst_n             ) 
          ,.tdi_i                     ( tdi                ) 
          ,.tdo_o                     ( tdo                ) 
          ,.tdo_oe_o                  ( tdo_oe             ) 
          ,.uart_rx_i                 ( dut_uart_rx        ) 
          ,.uart_tx_o                 ( dut_uart_tx        ) 
          `ifdef SOPHON_EXT_ACCESS
          ,.axi_slv_port_req_i        ( axi_slv_port_req   ) 
          ,.axi_slv_port_rsp_o        ( axi_slv_port_rsp   ) 
          `endif
          `ifdef SOPHON_EXT_INST_DATA
          ,.axi_mst_port_req_o        ( axi_mst_port_req   ) 
          ,.axi_mst_port_rsp_i        ( axi_mst_port_rsp   ) 
          `endif
    );


    // ----------------------------------------------------------------------
    //  Prepare External Memory if it is enabled
    // ----------------------------------------------------------------------

    `ifdef SOPHON_EXT_INST_DATA

        CC_ITF_PKG::axi_mst_side_d32_req_t    axi_mst_32b_req;
        CC_ITF_PKG::axi_mst_side_d32_resps_t axi_mst_32b_rsp;

        axi_dw_converter #(
            .AxiMaxReads         ( 4                                     ) ,
            .AxiSlvPortDataWidth ( CC_ITF_PKG::XBAR_DATA_WIDTH           ) ,
            .AxiMstPortDataWidth ( 32                                    ) ,
            .AxiAddrWidth        ( CC_ITF_PKG::XBAR_ADDR_WIDTH           ) ,
            .AxiIdWidth          ( CC_ITF_PKG::XBAR_MST_PORT_ID_WIDTH    ) ,
            .aw_chan_t           ( CC_ITF_PKG::xbar_mst_port_aw_t        ) ,
            .slv_w_chan_t        ( CC_ITF_PKG::xbar_w_chan_t             ) ,
            .b_chan_t            ( CC_ITF_PKG::xbar_mst_port_b_t         ) ,
            .ar_chan_t           ( CC_ITF_PKG::xbar_mst_port_ar_t        ) ,
            .slv_r_chan_t        ( CC_ITF_PKG::xbar_mst_port_r_t         ) ,
            .mst_w_chan_t        ( CC_ITF_PKG::axi_w_32b_t               ) ,
            .mst_r_chan_t        ( CC_ITF_PKG::axi_r_32b_t               ) ,
            .axi_mst_req_t       ( CC_ITF_PKG::axi_mst_side_d32_req_t    ) ,
            .axi_mst_resp_t      ( CC_ITF_PKG::axi_mst_side_d32_resps_t  ) ,
            .axi_slv_req_t       ( CC_ITF_PKG::xbar_mst_port_d64_req_t   ) ,
            .axi_slv_resp_t      ( CC_ITF_PKG::xbar_mst_port_d64_resps_t ) 
        ) i_axi_dw_converter (
            .clk_i         ( clk             ) ,
            .rst_ni        ( rst_n           ) ,
            // slave port
            .slv_req_i     ( axi_mst_port_req ) ,
            .slv_resp_o    ( axi_mst_port_rsp ) ,
            // master port
            .mst_req_o     ( axi_mst_32b_req ) ,
            .mst_resp_i    ( axi_mst_32b_rsp ) 
        );

        CC_ITF_PKG::reqrsp_d32_req_t      reqresp_d32_req;
        CC_ITF_PKG::reqrsp_d32_resps_t    reqresp_d32_rsp;

        axi_to_reqrsp #(
            .axi_req_t    ( CC_ITF_PKG::axi_mst_side_d32_req_t   ) ,
            .axi_rsp_t    ( CC_ITF_PKG::axi_mst_side_d32_resps_t ) ,
            .AddrWidth    ( CC_ITF_PKG::REQRSP_ADDR_WIDTH        ) ,
            .DataWidth    ( CC_ITF_PKG::REQRSP_DATA_WIDTH        ) ,
            .IdWidth      ( CC_ITF_PKG::XBAR_MST_PORT_ID_WIDTH   ) ,
            .BufDepth     ( 1                                    ) ,
            .reqrsp_req_t ( CC_ITF_PKG::reqrsp_d32_req_t         ) ,
            .reqrsp_rsp_t ( CC_ITF_PKG::reqrsp_d32_resps_t       ) 
        ) u_axi_to_reqrsp  (
            .clk_i        ( clk             ) ,
            .rst_ni       ( rst_n           ) ,
            .busy_o       (                 ) ,
            .axi_req_i    ( axi_mst_32b_req ) ,
            .axi_rsp_o    ( axi_mst_32b_rsp ) ,
            .reqrsp_req_o ( reqresp_d32_req ) ,
            .reqrsp_rsp_i ( reqresp_d32_rsp ) 
        );

        logic             axi_mem_req   ;
        logic             axi_mem_gnt   ;
        logic             axi_mem_cs    ;
        logic             axi_mem_we    ;
        logic [3:0]       axi_mem_be    ;
        logic [31:0]      axi_addr      ;
        logic [31:0]      axi_mem_wdata ;
        logic [31:0]      axi_mem_rdata ;

        REQRSP_TO_MEM #(
            .req_t      ( CC_ITF_PKG::reqrsp_d32_req_t   ) ,
            .resp_t     ( CC_ITF_PKG::reqrsp_d32_resps_t ) ,
            .DATA_WIDTH ( 32                             ) ,
            .ADDR_WIDTH ( 32                             ) 
        ) u_reqrsp_to_mem 
        (
            .clk_i     ( clk             ) ,
            .rst_ni    ( rst_n           ) ,
            .req_i     ( reqresp_d32_req ) ,
            .resp_o    ( reqresp_d32_rsp ) ,
            .mem_req   ( axi_mem_req     ) ,
            .mem_gnt   ( 1'b1            ) , // AXI ports has highest priority
            .mem_cs    ( axi_mem_cs      ) ,
            .mem_we    ( axi_mem_we      ) ,
            .mem_be    ( axi_mem_be      ) ,
            .mem_addr  ( axi_addr        ) ,
            .mem_wdata ( axi_mem_wdata   ) ,
            .mem_rdata ( axi_mem_rdata   ) 
        );

        logic [31:0] axi_mem_addr_offset;
        assign axi_mem_addr_offset = axi_addr - 32'h1000;

        //32K*32bit=128K
        localparam int unsigned EXT_MEM_SIZE = CC_CFG_PKG::EXT_MEM_END-CC_CFG_PKG::EXT_MEM_BASE+1;
        //localparam int unsigned EXT_MEM_SIZE = 32'h0002_0000;
        TCM_WRAP 
        #(
            .DATA_WIDTH ( 32                    ) ,
            .DEPTH      ( EXT_MEM_SIZE / (32/8) )   // in DATA_WIDTH
        )
        U_EXT_MEM
        (
             .clk_i   ( clk                                           )
            ,.en_i    ( axi_mem_req                                   )
            ,.addr_i  ( axi_mem_addr_offset[$clog2(EXT_MEM_SIZE)-1:0] ) // in byte
            ,.wdata_i ( axi_mem_wdata                                 ) 
            ,.we_i    ( axi_mem_we                                    )
            ,.be_i    ( axi_mem_be                                    )
            ,.rdata_o ( axi_mem_rdata                                 )
        );

    `endif


    // ----------------------------------------------------------------------
    //  Preload memory
    // ----------------------------------------------------------------------

    // -----------------------------------
    //  read program data 
    // -----------------------------------
    reg [7:0]    cc0_ram [0:32'h000a_0000];
    reg [8*80:0] tc_hex;
    reg [8*3:0]  mem_mode;
    integer i, by;
        
    initial begin
        if ( $value$plusargs("TC_HEX=%s",tc_hex ) ) begin
            $display("TC_HEX=%s\n",  tc_hex);
            $readmemh(tc_hex, cc0_ram);   
        end
        if ( $value$plusargs("MEM_MODE=%s",mem_mode ) ) begin
            $display("MEM_MODE=%s\n",  mem_mode);
        end
        else begin
            mem_mode="EXT";
            $display("MEM_MODE=%s\n",  mem_mode);
        end
    end
    `ifdef TB_INFO
        initial begin
            $display("0xITCM_OFFSET\n");
            for ( i = 0; i < 50; i = i + 1 ) 
            $display("cc0_ram=%x\n",  cc0_ram[ITCM_OFFSET+i]);
            $display("0xDTCM_OFFSET\n");
            for ( i = 0; i < 50; i = i + 1 ) 
            $display("cc0_ram=%x\n",  cc0_ram[DTCM_OFFSET+i]);
        end
    `endif

    // -----------------------------------
    //  Preload external memory
    // -----------------------------------

        `ifdef SOPHON_EXT_INST_DATA

            `ifndef ASIC
                `define EXT_MEM(bankaddr) U_EXT_MEM.gen_spilt_ram[``bankaddr``].U_BW_SP_RAM.ram_block
            `else
            `endif

            localparam int unsigned EXT_MEM_BASE = CC_CFG_PKG::EXT_MEM_BASE;
            localparam int unsigned E_BANK_DEPTH = 1024;
            localparam int unsigned E_BANK_NUM   = (EXT_MEM_SIZE/(32/8)) / E_BANK_DEPTH;
            //localparam int unsigned E_BANK_NUM = 32;

            genvar m;
            generate
                // per bank
                for (m=0; m<E_BANK_NUM; m=m+1) begin
                    initial begin
                        // 1024*32bit=4KB
                        if (mem_mode=="EXT") begin
                            for ( i = 0; i < 1024; i = i + 1 ) begin
                                for ( by = 0; by < 4; by = by + 1 ) begin
                                `ifdef DBG_ENABLE
                                    `EXT_MEM(m)[i][by*8+:8] = '0;
                                `else
                                    `EXT_MEM(m)[i][by*8+:8] = cc0_ram[ EXT_MEM_BASE + m*4096 + i*4+by];
                                `endif
                                end
                            end
                        end
                    end
                end
            endgenerate

        `endif


    // -----------------------------------
    //  Preload TCM memory
    // -----------------------------------
    `ifndef ASIC
        `define ITCM(bankaddr)    u_dut.U_SOPHON_AXI_TOP.U_SOPHON_TOP.U_ITCM.gen_spilt_ram[``bankaddr``].U_BW_SP_RAM.ram_block
        `define DTCM(bankaddr)    u_dut.U_SOPHON_AXI_TOP.U_SOPHON_TOP.U_DTCM.gen_spilt_ram[``bankaddr``].U_BW_SP_RAM.ram_block
    `else
    `endif

    localparam int unsigned ITCM_OFFSET    = SOPHON_PKG::ITCM_OFFSET;
    localparam int unsigned DTCM_OFFSET    = SOPHON_PKG::DTCM_OFFSET;
    // BANK_NUM = TCM_DEPTH / BANK_DEPTH
    localparam int unsigned TCM_BANK_DEPTH = 1024;
    localparam int unsigned ITCM_BANK_NUM  = (SOPHON_PKG::ITCM_SIZE/(32/8)) / TCM_BANK_DEPTH;
    localparam int unsigned DTCM_BANK_NUM  = (SOPHON_PKG::DTCM_SIZE/(32/8)) / TCM_BANK_DEPTH;
    //localparam int unsigned BANK_NUM     = 16;

    genvar k;
    generate
        // per bank
        for (k=0; k<ITCM_BANK_NUM; k=k+1) begin
            initial begin
                // 1024*32bit=4KB
                if (mem_mode=="TCM") begin
                    for ( i = 0; i < 1024; i = i + 1 ) begin
                        for ( by = 0; by < 4; by = by + 1 ) begin
                            `ITCM(k)[i][by*8+:8] = cc0_ram[ ITCM_OFFSET + k*4096 + i*4+by];
                        end
                    end
                end
            end
        end
        // per bank
        for (k=0; k<DTCM_BANK_NUM; k=k+1) begin
            initial begin
                // 1024*32bit=4KB
                if (mem_mode=="TCM") begin
                    for ( i = 0; i < 1024; i = i + 1 ) begin
                        for ( by = 0; by < 4; by = by + 1 ) begin
                            `DTCM(k)[i][by*8+:8] = cc0_ram[ DTCM_OFFSET + k*4096 + i*4+by];
                        end
                    end
                end
            end
        end
    endgenerate


    // ----------------------------------------------------------------------
    //  uart model
    // ----------------------------------------------------------------------
    logic uart_tx;  
    logic uart_rx;  
    parameter  BAUDRATE = 115200;

    assign uart_rx     = dut_uart_tx;
    assign dut_uart_rx = uart_tx;

    uart_bus
    #(
        .BAUD_RATE ( BAUDRATE ) ,
        .PARITY_EN ( 0        ) 
    )
    u_uart_bus
    (
        .rx    ( uart_rx ) ,
        .tx    ( uart_tx ) ,
        .rx_en ( 1'b1    ) 
    );


    // ----------------------------------------------------------------------
    //  JTAG Debug
    // ----------------------------------------------------------------------
    `ifdef DBG_ENABLE
        SimJTAG s_simJtag(
            .clock           ( clk    ) ,
            .reset           ( ~rst_n ) ,
            .enable          ( 1'b1   ) ,
            .init_done       ( 1'b1   ) ,
            .jtag_TCK        ( tck    ) ,
            .jtag_TMS        ( tms    ) ,
            .jtag_TDI        ( tdi    ) ,
            .jtag_TRSTn      ( trst_n ) ,
            .jtag_TDO_data   ( tdo    ) ,
            .jtag_TDO_driven ( tdo_oe ) ,
            .exit            (        ) 
        );
    `else
        assign tck    = 1'b0;
        assign tms    = 1'b0;
        assign tdi    = 1'b0;
        assign trst_n = 1'b1;
    `endif


    // ----------------------------------------------------------------------
    //  AXI master
    // ----------------------------------------------------------------------
    `ifdef SOPHON_EXT_ACCESS

        localparam int unsigned AxiIdWidthMasters =  CC_ITF_PKG::XBAR_SLV_PORT_ID_WIDTH;
        localparam int unsigned AxiIdUsed         =  CC_ITF_PKG::XBAR_SLV_PORT_ID_WIDTH; 
        localparam int unsigned AxiIdWidthSlaves  =  CC_ITF_PKG::XBAR_MST_PORT_ID_WIDTH;
        localparam int unsigned AxiAddrWidth      =  CC_ITF_PKG::XBAR_ADDR_WIDTH;  
        localparam int unsigned AxiDataWidth      =  CC_ITF_PKG::XBAR_DATA_WIDTH;
        localparam int unsigned AxiStrbWidth      =  CC_ITF_PKG::XBAR_STRB_WIDTH;
        localparam int unsigned AxiUserWidth      =  CC_ITF_PKG::XBAR_USER_WIDTH;
        
        localparam time ApplTime =  2ns;
        localparam time TestTime =  8ns;
        
        typedef axi_test::axi_rand_master #(
            // AXI interface parameters
            .AW ( AxiAddrWidth       ),
            .DW ( AxiDataWidth       ),
            .IW ( AxiIdWidthMasters  ),
            .UW ( AxiUserWidth       ),
            // Stimuli application and test time
            .TA ( ApplTime           ),
            .TT ( TestTime           ),
            // Maximum number of read and write transactions in flight
            .MAX_READ_TXNS  ( 4 ) ,
            .MAX_WRITE_TXNS ( 4 ) ,
            .AXI_EXCLS      ( 0 ) ,
            .AXI_ATOPS      ( 0 ) ,
            .UNIQUE_IDS     ( 0 ) 
        ) axi_rand_master_t;
        
        axi_rand_master_t axi_rand_master ;

        AXI_BUS #(
          .AXI_ADDR_WIDTH ( AxiAddrWidth      ),
          .AXI_DATA_WIDTH ( AxiDataWidth      ),
          .AXI_ID_WIDTH   ( AxiIdWidthMasters ),
          .AXI_USER_WIDTH ( AxiUserWidth      )
        ) master ();
        AXI_BUS_DV #(
          .AXI_ADDR_WIDTH ( AxiAddrWidth      ),
          .AXI_DATA_WIDTH ( AxiDataWidth      ),
          .AXI_ID_WIDTH   ( AxiIdWidthMasters ),
          .AXI_USER_WIDTH ( AxiUserWidth      )
        ) master_dv (clk);
        
        `AXI_ASSIGN           ( master, master_dv        ) 
        `AXI_ASSIGN_TO_REQ    ( axi_slv_port_req, master ) 
        `AXI_ASSIGN_FROM_RESP ( master, axi_slv_port_rsp ) 

    `endif


    // ----------------------------------------------------------------------
    //  TESE START
    // ----------------------------------------------------------------------

    initial begin

        reg [8*20:0]  tc;
        logic flag_release_cpu;

        $value$plusargs("TC=%s",tc);
        $display("TC=%s\n",  tc);

        `ifdef SOPHON_EXT_ACCESS
            axi_rand_master = new( master_dv );
            axi_rand_master.add_memory_region(32'h0000_0000, 32'hFFFF_FFFF, axi_pkg::DEVICE_NONBUFFERABLE);
            axi_rand_master.reset();
        `endif
        `ifdef SOPHON_CLIC  
            clic_irq_req = 1'b0;
        `endif
        irq_mei = 1'b0;


        flag_release_cpu = 1'b0;
        @(posedge rst_n);

        $display("===================================================");
        if (mem_mode=="EXT") begin
        `ifdef SOPHON_EXT_ACCESS
            $display($realtime, ": Memmory used: External Memory");
            $display($realtime, ": Configure: Set Soft Reset = 0......");
            axi_rand_master.run_write_word(32'h0600_0004, 64'h0000_0000_0000_0000, 8'd0, 3'b010);
            $display($realtime, ": Configure: Set bootaddr = 0x1000 (EXT MEM)......");
            axi_rand_master.run_write_word(32'h0600_0000, 64'h0000_0000_0000_1000, 8'd0, 3'b010);
            $display($realtime, ": Configure: Set Soft Reset = 1......");
            axi_rand_master.run_write_word(32'h0600_0004, 64'h0000_0001_0000_0000, 8'd0, 3'b010);
            flag_release_cpu = 1'b1;
        `else
            $display("External memory is not enabled. ");
            TODO: Use force to set bootaddr & soft reset
        `endif
        end
        else begin
            flag_release_cpu = 1'b1;
            $display($realtime, ": Memmory used: TCM Memory");
            $display($realtime, ": bootaddr = 0x80000000 ......");
        end
        wait (flag_release_cpu==1'b1)
            $display("release cpu");
        $display("===================================================");

        // -----------------------------------
        // Test case
        // -----------------------------------
        case (tc)
            "clint"               : clint()                                     ;
            "ext_access"          : `ifdef SOPHON_EXT_ACCESS ext_access()     `endif;
            "clic"                : `ifdef SOPHON_CLIC       clic()           `endif;
            "fgpio_uart"          : `ifdef SOPHON_EEI_GPIO   fgpio_uart()     `endif;
            "fgpio"               : `ifdef SOPHON_EEI_GPIO   fgpio()          `endif;
            default               : ;
        endcase

    end


    // ----------------------------------------------------------------------
    //  Finish Check
    // ----------------------------------------------------------------------
    int fail=0;
    logic  is_ecall;
    logic [31:0] gp;
    logic [31:0] tohost;

    assign is_ecall = u_dut.U_SOPHON_AXI_TOP.U_SOPHON_TOP.U_SOPHON.is_ecall;
    assign gp       = u_dut.U_SOPHON_AXI_TOP.U_SOPHON_TOP.U_SOPHON.regfile[3];
    initial begin
        if (mem_mode=="EXT") 
            `ifndef SOPHON_EXT_INST_DATA
                $fatal("FATAL: External memory is not enabled.");
            `else
                assign tohost = U_EXT_MEM.gen_spilt_ram[16].U_BW_SP_RAM.ram_block[0];
            `endif
        else
            assign tohost = u_dut.U_SOPHON_AXI_TOP.U_SOPHON_TOP.U_DTCM.gen_spilt_ram[0].U_BW_SP_RAM.ram_block[0];
    end
    

    `ifndef VERILATOR

        initial begin
            wait ( is_ecall );

            //if ( gp == 32'd1 ) begin
            if ( tohost == 32'd1 ) begin
                $display($realtime, ": Core %0s success\n",  tc_hex);
            end
            else begin
                $display($realtime, ": Core %0s FAIL\n",  tc_hex);
                fail = 1;
            end

            if (fail)
                $display($realtime, ": Testcase FAIL!!\n\n");
            else 
                $display($realtime, ": Testcase PASS!!\n\n");

            `ifndef DBG_ENABLE        
                repeat(100)@(posedge clk);
                $finish;
            `endif
        end

    `else

        localparam int unsigned TO_BIT = 18;

        logic [7:0]        finish_cnt;
        logic [TO_BIT-1:0] timeout_cnt;

        always_ff @(posedge clk  , negedge rst_n ) begin
            if(~rst_n ) 
                timeout_cnt <= {TO_BIT{1'b0}};
            else if ( timeout_cnt<{TO_BIT{1'b1}})
                timeout_cnt <= timeout_cnt + 1;
        end

        always_ff @(posedge clk  , negedge rst_n ) begin
            if(~rst_n ) 
                finish_cnt <= 8'h00;
            else if ( is_ecall==1'b1 )
                finish_cnt <= finish_cnt + 8'h1;
            else if ( finish_cnt!=8'h0 && finish_cnt<=8'hff )
                finish_cnt <= finish_cnt + 8'h1;
        end

        always_ff @(posedge clk  ) begin
            if ( &finish_cnt ) begin
                if ( gp == 32'd1 ) begin
                    $display($realtime, ": Core %0s success\n",  tc_hex);
                    $display($realtime, ": Testcase PASS!!!\n");
                    $finish;
                end
                else begin
                    $display($realtime, ": Core %0s FAIL\n",  tc_hex);
                    $finish;
                end
            end
            else if ( &timeout_cnt ) begin
                $display($realtime, ": Core %0s TIMEOUT!!!\n",  tc_hex);
                $finish;
            end
        end

    `endif


    // -----------------------------------
    // Timeout 
    // -----------------------------------
    initial begin

        reg [8*20:0]  tc_type;

        if ( $value$plusargs("TC_TYPE=%s",tc_type ) ) begin
            $display("TC_TYPE=%s\n",  tc_type);
        end

        case (tc_type)
            "benchmarks" : begin $display("TIMEOUTE=500ms\n");  #500ms ; end
            default      : begin $display("TIMEOUTE=3ms\n"  );  #3ms   ; end
        endcase
        $display("\nTimeout: Testcase FAIL!!\n\n");

        `ifndef DBG_ENABLE
            $display("Debug test, continue...\n");
            $finish;
        `endif
    end


    // ----------------------------------------------------------------------
    //  Dump waveform
    // ----------------------------------------------------------------------

    `ifndef VERILATOR
        initial begin
          $fsdbDumpfile("test.fsdb"); 
          $fsdbDumpvars;
          $fsdbDumpMDA(0, tb); 
        end
    `endif


    // ----------------------------------------------------------------------
    //  include hardware tc
    // ----------------------------------------------------------------------
    `include "./tc/clint.sv"
    `ifdef SOPHON_CLIC
        `include "./tc/clic.sv"
    `endif
    `ifdef SOPHON_EEI_GPIO
        `include "./tc/fgpio.sv"
    `endif
    `ifdef SOPHON_EXT_ACCESS
        `include "./tc/ext_access.sv"
    `endif

endmodule

