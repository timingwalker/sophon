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
// Create Date   : 2022-10-31 10:42:04
// Last Modified : 2024-04-11 17:50:04
// Description   : SOPHON: A time-repeatable and low-latency RISC-V core
// ----------------------------------------------------------------------

module SOPHON (
     input  logic                        clk_i
    ,input  logic                        clk_neg_i
    ,input  logic                        rst_ni
    ,input  logic [31:0]                 bootaddr_i
    ,input  logic [31:0]                 hart_id_i
    // irq
    ,input  logic                        irq_mei_i
    ,input  logic                        irq_mti_i
    ,input  logic                        irq_msi_i
    // debug halt request
    ,input  logic                        dm_req_i
    // instruction fetch interface
    ,output logic                        inst_req_o
    ,output logic [31:0]                 inst_addr_o
    ,input  logic                        inst_ack_i
    ,input  logic [31:0]                 inst_data_i
    ,input  logic                        inst_error_i
    // lsu interface
    ,output logic                        lsu_req_o
    ,output logic                        lsu_we_o
    ,output logic [31:0]                 lsu_addr_o
    ,output logic [31:0]                 lsu_wdata_o
    ,output logic [3:0]                  lsu_amo_o
    ,output logic [1:0]                  lsu_size_o
    ,output logic [3:0]                  lsu_strb_o
    ,input  logic                        lsu_ack_i
    ,input  logic                        lsu_error_i
    ,input  logic [31:0]                 lsu_rdata_i
`ifdef SOPHON_EEI
    // enhanced extension interface
    ,output logic                        eei_req_o
    ,output logic                        eei_ext_o
    ,output logic [2:0]                  eei_funct3_o
    ,output logic [6:0]                  eei_funct7_o
    ,output logic [4:0]                  eei_batch_start_o
    ,output logic [4:0]                  eei_batch_len_o
    ,output logic [31:0]                 eei_rs_val_o[SOPHON_PKG::EEI_RS_MAX-1:0]
    ,input  logic                        eei_ack_i  //nedege
    ,input  logic [1:0]                  eei_rd_op_i
    ,input  logic [4:0]                  eei_rd_len_i
    ,input  logic                        eei_error_i
    ,input  logic [31:0]                 eei_rd_val_i[SOPHON_PKG::EEI_RD_MAX-1:0]
`endif
`ifdef SOPHON_CLIC
    // CLIC interface
    ,input  logic                        clic_irq_req_i
    ,input  logic                        clic_irq_shv_i
    ,input  logic [4:0]                  clic_irq_id_i
    ,input  logic [7:0]                  clic_irq_level_i
    ,output logic                        clic_irq_ack_o
    ,output logic [7:0]                  clic_irq_intthresh_o
    ,output logic                        clic_mnxti_clr_o
    ,output logic [4:0]                  clic_mnxti_id_o
`endif
`ifdef PROBE
    // Debug signal
    ,output logic [139:0]                probe_sophon_o
`endif
);


    // ----------------------------------------------------------------------
    //  SIGNAL DEFINE
    // ----------------------------------------------------------------------
    logic        is_add, is_addi, is_sub, 
                 is_slt, is_slti, is_sltiu, is_sltu,
                 is_and, is_andi, is_or, is_ori, is_xor, is_xori, 
                 is_sll, is_slli, is_srl, is_srli, is_sra, is_srai,
                 is_lui, is_auipc, is_nop;
    logic        is_jal, is_jalr,
                 is_beq, is_bne, is_blt, is_bltu, is_bge, is_bgeu;
    logic        is_lw, is_lh, is_lhu, is_lb, is_lbu, 
                 is_sw, is_sh, is_sb;
    logic        is_csrrw, is_csrrs, is_csrrc, is_csrrwi, is_csrrsi, is_csrrci;
    logic        is_ecall, is_ebreak, is_wfi;
    logic        is_fence, is_fence_i;
    logic        is_mret, is_dret;
    logic        op_is_branch, op_is_store, op_is_load, op_is_jal, op_is_jalr,
                 op_is_alui, op_is_alu, op_is_csr, op_is_lui, op_is_auipc, op_is_fence ;
    logic        rvi_other, rvi_jump, rvi_branch, rvi_load, rvi_store,
                 `ifdef SOPHON_EEI rvi_cust, `endif
                 rvi_alui, rvi_alu, rvi_system, rvi_fence, rvi_csr;

    logic        mstatus_mie, mstatus_mpie;
    logic [1:0]  mstatus_mpp;
    logic [31:0] mie, mscratch, mtval,
                 mtvec,mepc,mcause;
    logic [63:0] mcycle, minstret;
`ifdef SOPHON_CLIC
    logic [7:0]  mpil;
    logic        minhv;
    logic [31:0] mintthresh, mnxti, mtvt;
`endif

    logic        ex_inst_access, ex_illg_instr, ex_load_store,
                 ex_branch, ex_csr_addr;
    logic        mei_en_pending, mti_en_pending, msi_en_pending;
    logic        ex_vld, irq_vld, irq_ex_vld;
    logic        clint_irq_vld;

    logic [31:0] jump_branch_target;
    logic        branch_taken;
    logic        lsu_valid;
    logic        debug_mode, dm_start;
    logic        ebreakm;
`ifdef SOPHON_CLIC
    logic        clic_hard_ack; 
    logic        clic_npc_load, clic_npc_load_1d;
    logic [4:0]  clic_irq_id_i_1d;
`endif


    // ----------------------------------------------------------------------
    //  ==== INSTRUCTION FETCH
    // ----------------------------------------------------------------------
    logic [2:0]  rst_cnt;
    logic        rst_dly_neg;
    logic        if_vld, if_vld_pos, if_vld_neg;
    logic        retire_vld;
    logic [31:0] inst_data_1d;
    logic        inst_data_1d_vld;
    logic        if_stall, if_stall_dm, if_stall_lsu
    `ifdef SOPHON_EEI  ,if_stall_eei  `endif
    `ifdef SOPHON_CLIC ,if_stall_clic `endif ;
    logic        npc_sel_bootaddr, npc_sel_transfer;
    logic        npc_sel_dm_halt, npc_sel_dm_ex, npc_sel_dm_exit;
    logic        npc_sel_ex, npc_sel_ex_exit;
    logic        npc_sel_clint_direct, npc_sel_clint_vector;
    logic [31:0] pc, npc, dpc;

    // ------------------------------------------------
    //  Delay reset signal inside the core
    //   1. Wait the default value of bootaddr_i takes
    //      effect if it comes from a registers.
    //   2. Align the instruction fetching request to 
    //      the negedge clock.
    // ------------------------------------------------
    assign rst_dly_neg = &rst_cnt;
    always_ff @(posedge clk_neg_i, negedge rst_ni) begin
        if (~rst_ni) begin
            rst_cnt <= 3'd0;
        end
        else if (rst_cnt<3'd7) begin
            rst_cnt <= rst_cnt + 3'd1;
        end
    end

    // ------------------------------------------------
    //  npc select signal:
    //   1. change at negedge clock
    //   2. stable when inst_req & ~inst_ack
    // ------------------------------------------------
    always_ff @(posedge clk_neg_i, negedge rst_ni) begin
        if ( ~rst_ni ) 
            npc_sel_bootaddr <= 1'b1;
        else if ( if_vld & npc_sel_bootaddr )
            npc_sel_bootaddr <= 1'b0;
    end

    always_ff @(posedge clk_neg_i, negedge rst_ni) begin
        if(~rst_ni) 
            npc_sel_dm_halt <= 1'b0;
        else if ( dm_start )
            npc_sel_dm_halt <= 1'b1;
        //else if ( if_vld && ( npc==SOPHON_PKG::DM_HALT) )
        else if ( if_vld )
            npc_sel_dm_halt <= 1'b0;
    end

    // When dret retired, debug_mode is cleared and so is is_dret.
    // This signal is used to keep npc stable if it takes several cycles
    // to fetch a new instruction, e.g. access external memories.
    logic  fetching_dpc;
    assign npc_sel_dm_exit = is_dret | fetching_dpc;
    always_ff @(posedge clk_neg_i, negedge rst_ni) begin
        if(~rst_ni) 
            fetching_dpc <= 1'b0;
        else if ( if_vld )
            fetching_dpc <= 1'b0;
        else if ( is_dret )
            fetching_dpc <= 1'b1;
    end

    assign npc_sel_dm_ex        = ex_vld & debug_mode;
    assign npc_sel_ex           = ex_vld;
    assign npc_sel_ex_exit      = is_mret;

    assign npc_sel_clint_direct = clint_irq_vld && (mtvec[1:0]==2'd0);
    assign npc_sel_clint_vector = clint_irq_vld && (mtvec[1:0]==2'd1);

    assign npc_sel_transfer     = rvi_jump | branch_taken;

`ifdef SOPHON_CLIC
    logic [31:0] clic_npc_vector;
    logic        npc_sel_clic_vector;
    logic        npc_sel_clic_direct;
    always_ff @(posedge clk_neg_i, negedge rst_ni) begin
        if(~rst_ni) 
            npc_sel_clic_direct <= 1'b0;
        else if ( clic_irq_req_i & clic_hard_ack & (~clic_irq_shv_i) ) 
            npc_sel_clic_direct <= 1'b1;
        else if ( if_vld ) 
            npc_sel_clic_direct <= 1'b0;
    end
    always_ff @(posedge clk_neg_i, negedge rst_ni) begin
        if(~rst_ni) 
            npc_sel_clic_vector <= 1'b0;
        else if ( clic_npc_load & lsu_valid ) 
            npc_sel_clic_vector <= 1'b1;
        else if ( if_vld ) 
            npc_sel_clic_vector <= 1'b0;
    end
`endif

    // ------------------------------------------------
    //  npc/pc change at negedge
    // ------------------------------------------------
    always_comb begin
        if ( npc_sel_bootaddr ) 
            npc = bootaddr_i;
        // DEBUG MODE: 
        //   1. entering
        else if ( npc_sel_dm_halt )
            npc = SOPHON_PKG::DM_HALT;
        //   2. exception occurs
        else if ( npc_sel_dm_ex ) 
            npc = is_ebreak ? SOPHON_PKG::DM_HALT : SOPHON_PKG::DM_EXCEPTION;
        //   3. exiting
        else if ( npc_sel_dm_exit ) 
            npc = dpc;
        // EXCEPTION and Interrupt: 
        //   1. exception outside the debug mode, all redirect to mtvec-base
        else if ( npc_sel_ex ) 
            npc = {mtvec[31:2], 2'b0}; 
        //   2. CLINT irq: direct mode
        else if ( npc_sel_clint_direct ) 
            npc = {mtvec[31:2], 2'b0}; 
        //   3. CLINT irq: vector mode
        else if ( npc_sel_clint_vector ) 
            npc = {mtvec[31:2], 2'b0} + ({1'b0,mcause[30:0]}<<2); 
        //   4. CLIC irq
    `ifdef SOPHON_CLIC
        else if ( npc_sel_clic_direct ) 
            npc = {mtvec[31:6], 6'd0};
        else if ( npc_sel_clic_vector ) 
            npc = {clic_npc_vector[31:1], 1'b0};
    `endif
        //   5. exiting
        else if ( npc_sel_ex_exit )
            npc = mepc;
        // TRANSFER INSTRUCTIONS:
        else if ( npc_sel_transfer ) 
            npc = jump_branch_target;
        else 
            npc = pc+ 32'd4;
    end

    always_ff @(posedge clk_neg_i, negedge rst_ni) begin
        if ( ~rst_ni ) 
            pc <= 32'd0;
        else if ( if_vld ) 
            pc <= npc;
    end

    // ------------------------------------------------
    //  IF interface
    // ------------------------------------------------
    assign inst_addr_o = npc;
    assign inst_req_o  = rst_dly_neg & (~if_stall);
    assign if_vld      = inst_req_o & inst_ack_i;

    assign if_stall    = if_stall_dm
                       | if_stall_lsu            
    `ifdef SOPHON_EEI  | if_stall_eei  `endif
    `ifdef SOPHON_CLIC | if_stall_clic `endif
                       ;

    // capture inst_data_i at negedge clk 
    // may add pre-decode logic before 1d to balance timing
    always_ff @(posedge clk_neg_i, negedge rst_ni) begin
        if (~rst_ni)
            inst_data_1d <= 32'd0;
        else if (if_vld)
            inst_data_1d <= inst_data_i;
    end

    always_ff @(posedge clk_neg_i, negedge rst_ni) begin
        if (~rst_ni)
            inst_data_1d_vld <= 1'b0;
        else if (if_vld)
            inst_data_1d_vld <= 1'b1;
        // clear when the current instruction is retired
        // and the next one is not fetched
        else if (retire_vld)
            inst_data_1d_vld <= 1'b0;
    end

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni)
            if_vld_pos <= 1'b0;
        else 
            if_vld_pos <= if_vld;
    end

    always_ff @(posedge clk_neg_i, negedge rst_ni) begin
        if(~rst_ni)
            if_vld_neg <= 1'b0;
        else 
            if_vld_neg <= if_vld;
    end


    // ----------------------------------------------------------------------
    //  ==== INSTRUCTION DECODE
    // ----------------------------------------------------------------------
    logic [6:0]     opcode;
    logic [2:0]     funct3;
    logic [6:0]     funct7;
    logic [4:0]     rs1_idx,rs2_idx,rd_idx;
    logic [32:0]    s_j_imm,s_i_imm,s_s_imm,
                    s_b_imm,u_i_imm,u_u_imm;

    // ------------------------------------------------
    //  common decode
    // ------------------------------------------------
    assign opcode  = inst_data_1d[6:0];
    assign funct3  = inst_data_1d[14:12];
    assign funct7  = inst_data_1d[31:25];
    assign rs1_idx = inst_data_1d[19:15];
    assign rs2_idx = inst_data_1d[24:20];
    assign rd_idx  = inst_data_1d[11:7];

    // immediate
    assign s_i_imm = { {22{inst_data_1d[31]}}, inst_data_1d[30:25], inst_data_1d[24:21], inst_data_1d[20] };
    assign u_i_imm = { 1'b0, {21{inst_data_1d[31]}}, inst_data_1d[30:25], inst_data_1d[24:21], inst_data_1d[20] };
    assign s_j_imm = { {13{inst_data_1d[31]}}, inst_data_1d[19:12], inst_data_1d[20], inst_data_1d[30:25], inst_data_1d[24:21], 1'b0 };
    assign s_b_imm = { {21{inst_data_1d[31]}}, inst_data_1d[7], inst_data_1d[30:25], inst_data_1d[11:8], 1'b0 };
    assign u_u_imm = { 1'b0, inst_data_1d[31], inst_data_1d[30:20], inst_data_1d[19:12], 12'd0};
    assign s_s_imm = { {21{inst_data_1d[31]}}, inst_data_1d[31:25], inst_data_1d[11:7]};

    // opcode
    assign op_is_branch = opcode==7'b1100011;
    assign op_is_jal    = opcode==7'b1101111;
    assign op_is_jalr   = opcode==7'b1100111;
    assign op_is_load   = opcode==7'b0000011;
    assign op_is_store  = opcode==7'b0100011;
    assign op_is_alui   = opcode==7'b0010011;
    assign op_is_alu    = opcode==7'b0110011;
    assign op_is_csr    = opcode==7'b1110011;
    assign op_is_lui    = opcode==7'b0110111;
    assign op_is_auipc  = opcode==7'b0010111;
    assign op_is_fence  = opcode==7'b0001111;

    // ------------------------------------------------
    //  RV32I instruction
    // ------------------------------------------------
    // jump
    assign is_jal    = op_is_jal;
    assign is_jalr   = op_is_jalr   && (funct3==3'b000);
    // branch
    assign is_beq    = op_is_branch && (funct3==3'b000) ;
    assign is_bne    = op_is_branch && (funct3==3'b001) ;
    assign is_blt    = op_is_branch && (funct3==3'b100) ;
    assign is_bge    = op_is_branch && (funct3==3'b101) ;
    assign is_bltu   = op_is_branch && (funct3==3'b110) ;
    assign is_bgeu   = op_is_branch && (funct3==3'b111) ;
    // load
    assign is_lb     = op_is_load   && (funct3==3'b000) ;
    assign is_lh     = op_is_load   && (funct3==3'b001) ;
    assign is_lw     = op_is_load   && (funct3==3'b010) ;
    assign is_lbu    = op_is_load   && (funct3==3'b100) ;
    assign is_lhu    = op_is_load   && (funct3==3'b101) ;
    // sotre
    assign is_sb     = op_is_store  && (funct3==3'b000) ;
    assign is_sh     = op_is_store  && (funct3==3'b001) ;
    assign is_sw     = op_is_store  && (funct3==3'b010) ;
    // alu - imediate
    assign is_addi   = op_is_alui   && (funct3==3'b000) ;
    assign is_slti   = op_is_alui   && (funct3==3'b010) ;
    assign is_sltiu  = op_is_alui   && (funct3==3'b011) ;
    assign is_xori   = op_is_alui   && (funct3==3'b100) ;
    assign is_ori    = op_is_alui   && (funct3==3'b110) ;
    assign is_andi   = op_is_alui   && (funct3==3'b111) ;
    assign is_slli   = op_is_alui   && (funct3==3'b001) && (funct7==7'b0000000) ;
    assign is_srli   = op_is_alui   && (funct3==3'b101) && (funct7==7'b0000000) ;
    assign is_srai   = op_is_alui   && (funct3==3'b101) && (funct7==7'b0100000) ;
    // alu - register
    assign is_add    = op_is_alu    && (funct3==3'b000) && (funct7==7'b0000000) ;
    assign is_sub    = op_is_alu    && (funct3==3'b000) && (funct7==7'b0100000) ;
    assign is_sll    = op_is_alu    && (funct3==3'b001) && (funct7==7'b0000000) ;
    assign is_slt    = op_is_alu    && (funct3==3'b010) && (funct7==7'b0000000) ;
    assign is_sltu   = op_is_alu    && (funct3==3'b011) && (funct7==7'b0000000) ;
    assign is_xor    = op_is_alu    && (funct3==3'b100) && (funct7==7'b0000000) ;
    assign is_srl    = op_is_alu    && (funct3==3'b101) && (funct7==7'b0000000) ;
    assign is_sra    = op_is_alu    && (funct3==3'b101) && (funct7==7'b0100000) ;
    assign is_or     = op_is_alu    && (funct3==3'b110) && (funct7==7'b0000000) ;
    assign is_and    = op_is_alu    && (funct3==3'b111) && (funct7==7'b0000000) ;
    // CSR
    assign is_csrrw  = op_is_csr    && (funct3==3'b001) ;
    assign is_csrrs  = op_is_csr    && (funct3==3'b010) ;
    assign is_csrrc  = op_is_csr    && (funct3==3'b011) ;
    assign is_csrrwi = op_is_csr    && (funct3==3'b101) ;
    assign is_csrrsi = op_is_csr    && (funct3==3'b110) ;
    assign is_csrrci = op_is_csr    && (funct3==3'b111) ;
    // others
    assign is_lui    = op_is_lui;
    assign is_auipc  = op_is_auipc;
    assign is_fence  = op_is_fence & (funct3==3'b000) ;
    // system
    assign is_ecall  = inst_data_1d==32'b000000000000_00000_000_00000_1110011 ;
    assign is_ebreak = inst_data_1d==32'b000000000001_00000_000_00000_1110011 ;
    assign is_mret   = inst_data_1d==32'b001100000010_00000_000_00000_1110011 ;
    assign is_wfi    = inst_data_1d==32'b000100000101_00000_000_00000_1110011 ;

    // ------------------------------------------------
    //  zifencei
    // ------------------------------------------------
    assign is_fence_i= op_is_fence & (funct3==3'b001) ;

    // ------------------------------------------------
    //  debug
    // ------------------------------------------------
    assign is_dret   = debug_mode & (inst_data_1d==32'h7b200073);

    // ------------------------------------------------
    //  Instruction type
    // ------------------------------------------------
    assign rvi_jump   = is_jal|is_jalr;
    assign rvi_branch = is_beq|is_bne|is_blt|is_bge|is_bltu|is_bgeu;
    assign rvi_load   = is_lb|is_lh|is_lw|is_lbu|is_lhu;
    assign rvi_store  = is_sb|is_sh|is_sw;
    assign rvi_alui   = is_addi|is_slti|is_sltiu|is_xori|is_ori|is_andi|is_slli|is_srli|is_srai;
    assign rvi_alu    = is_add|is_sub|is_sll|is_slt|is_sltu|is_xor|is_srl|is_sra|is_or|is_and;
    assign rvi_csr    = is_csrrw|is_csrrs|is_csrrc|is_csrrwi|is_csrrsi|is_csrrci;
    assign rvi_system = is_ecall|is_ebreak|is_mret|is_wfi|is_dret;
    assign rvi_fence  = is_fence|is_fence_i;
    assign rvi_other  = is_lui|is_auipc;


    // ----------------------------------------------------------------------
    //  ==== ALU // TODO: optimize ALU data path
    // ----------------------------------------------------------------------
    logic signed [32:0]    adder_op1, adder_op2, adder_result;
    logic signed [32:0]    cmp_op1, cmp_op2;
    logic                  cmp_result;
    logic        [32:0]    and_op1, and_op2;
    logic        [31:0]    bit_result;
    logic        [31:0]    shifter_result;
    logic        [32:0]    shifter_operand;
    logic        [31:0]    shifter_right_result;
    logic        [32:0]    shifter_right_result_ext;
    logic        [31:0]    shifter_left_result;
    logic        [31:0]    rs1_value_reverse;
    logic        [4:0]     shamt;
    logic                  rs1_equal_rs2;
    logic        [31:0]    rs1_val, rs2_val, rd_val, rs1_val_org;
    logic        [31:0]    regfile[31:0];
    logic                  wb_adder, wb_cmp, wb_bit,
                           wb_shifter, wb_lsu, wb_csr;

    // ------------------------------------------------
    //  ADDER
    // ------------------------------------------------
    always_comb begin
        unique case (1)
            // use pc as op1
            is_beq  , 
            is_bne  , 
            is_blt  , 
            is_bltu , 
            is_bge  , 
            is_bgeu , 
            is_auipc, 
            is_jal  : adder_op1 = $signed({1'b0, pc});
            is_jalr : adder_op1 = $signed({1'b0, rs1_val_org});
            // use rs1_val as op1: add/addi/sub/load/store 
            default : adder_op1 = $signed({rs1_val[31], rs1_val});
        endcase
    end

    always_comb begin
        unique case (1)
            is_jal      : adder_op2 = $signed(s_j_imm);
            is_jalr     , 
            is_addi     : adder_op2 = $signed(s_i_imm);
            is_sub      : adder_op2 = -$signed({rs2_val[31], rs2_val});
            is_beq      , 
            is_bne      , 
            is_blt      , 
            is_bltu     , 
            is_bge      , 
            is_bgeu     : adder_op2 = $signed(s_b_imm);
            is_auipc    : adder_op2 = $signed(u_u_imm);
            op_is_load  : adder_op2 = $signed(s_i_imm);
            op_is_store : adder_op2 = $signed(s_s_imm);
            default     : adder_op2 = $signed({rs2_val[31], rs2_val});
        endcase
    end

    assign adder_result = adder_op1 + adder_op2;
    assign wb_adder     = is_add | is_addi | is_sub | is_auipc;

    // ------------------------------------------------
    //  COMPARE
    // ------------------------------------------------
    always_comb begin
        unique case (1)
            is_slt  , 
            is_slti : cmp_op1 = $signed( {rs1_val[31], rs1_val} ) ;
            is_sltu ,
            is_sltiu: cmp_op1 = $signed( {1'b0, rs1_val}       ) ;
            is_blt  : cmp_op1 = $signed( {rs1_val[31], rs1_val} ) ;
            is_bltu : cmp_op1 = $signed( {1'b0, rs1_val}        ) ;
            is_bge  : cmp_op1 = $signed( {rs1_val[31], rs1_val} ) ;
            is_bgeu : cmp_op1 = $signed( {1'b0, rs1_val}        ) ;
            // not use
            default : cmp_op1 = $signed( {1'b0, rs1_val}        ) ;
        endcase
    end

    always_comb begin
        unique case (1)
            is_slt   : cmp_op2 = $signed({rs2_val[31], rs2_val} ) ;
            is_slti  : cmp_op2 = $signed(s_i_imm                ) ;
            is_sltiu : cmp_op2 = $signed(u_i_imm                ) ;
            is_sltu  : cmp_op2 = $signed({1'b0, rs2_val}        ) ;
            is_blt   : cmp_op2 = $signed({rs2_val[31], rs2_val} ) ;
            is_bltu  : cmp_op2 = $signed({1'b0, rs2_val}        ) ;
            is_bge   : cmp_op2 = $signed({rs2_val[31], rs2_val} ) ;
            is_bgeu  : cmp_op2 = $signed({1'b0, rs2_val}        ) ;
            // not use
            default  : cmp_op2 = $signed({rs2_val[31], rs2_val});
        endcase
    end

    assign cmp_result  = (cmp_op1<cmp_op2) ? 1'b1 : 1'b0;
    assign wb_cmp      = is_slt | is_slti | is_sltiu | is_sltu;

    // equal
    assign rs1_equal_rs2 = (rs1_val==rs2_val) ? 1'b1 : 1'b0;
    assign branch_taken =   (  rs1_equal_rs2  & is_beq           )
                            | ( ~rs1_equal_rs2  & is_bne           )
                            | (  cmp_result     & (is_blt|is_bltu) ) 
                            | ( ~cmp_result     & (is_bge|is_bgeu) ) ;

    // ------------------------------------------------
    //  BIT PROCESS
    // ------------------------------------------------
    always_comb begin
        unique case (1)
            is_and  : bit_result = rs1_val & rs2_val;
            is_andi : bit_result = rs1_val & s_i_imm[31:0];
            is_or   : bit_result = rs1_val | rs2_val;
            is_ori  : bit_result = rs1_val | s_i_imm[31:0];
            is_xor  : bit_result = rs1_val ^ rs2_val;
            is_xori : bit_result = rs1_val ^ s_i_imm[31:0];
            default : bit_result = 32'd0;
        endcase
    end

    assign wb_bit = is_and | is_andi | is_or | is_ori | is_xor | is_xori;

    // ------------------------------------------------
    //  SHIFTER
    // ------------------------------------------------
    for (genvar i=0; i<32; i++) begin:gen_shifter_reverse
        assign rs1_value_reverse[i] = rs1_val[31-i];
        assign shifter_left_result[i] = shifter_right_result[31-i];
    end

    always_comb begin
        unique case (1)
            is_sll  , 
            is_slli : shifter_operand = {1'b0, rs1_value_reverse};
            is_srl  , 
            is_srli : shifter_operand = {1'b0, rs1_val};
            is_sra  , 
            is_srai : shifter_operand = {rs1_val[31], rs1_val};
            default : shifter_operand = 32'd0;
        endcase
    end

    assign shamt = (is_sll|is_srl|is_sra) ? rs2_val[4:0] : inst_data_1d[24:20];

    assign shifter_right_result_ext = $unsigned( $signed(shifter_operand)>>>shamt );
    assign shifter_right_result = shifter_right_result_ext[31:0];

    assign shifter_result = (is_sll|is_slli) ? shifter_left_result : shifter_right_result;
    assign wb_shifter = is_sll | is_slli | is_srl | is_srli | is_sra | is_srai;

    // ------------------------------------------------
    //  Branch
    // ------------------------------------------------
    logic pre_dec_jalr;

    // pre decode jalr to calculate target address
    assign pre_dec_jalr = if_vld_pos && (inst_data_i[6:0]==7'b1100111) && (inst_data_i[14:12]==3'b000);

    always_ff @(posedge clk_neg_i, negedge rst_ni) begin
        if(~rst_ni) 
            rs1_val_org <= 32'd0;
        else if ( pre_dec_jalr )
            rs1_val_org <= regfile [ inst_data_i[19:15] ];
    end

    // Jump & branch: target pc comes from adder
    //  - Jal   : pc=pc+jimm*2
    //  - Jalr  : pc=rs1+iimm, hardware set least-significant bit to zero
    //  - Branch: pc=pc+bimm*2, check condition first, 
    assign jump_branch_target = {adder_result[31:1], adder_result[0] & ~is_jalr};


    // ----------------------------------------------------------------------
    //  ==== LOAD STORE UNIT
    // ----------------------------------------------------------------------
    logic        lsu_error;
    logic [31:0] lsu_result;
    logic        store_access_fault, load_access_fault;
    logic        store_addr_misalign, load_addr_misalign;
    logic        inst_lsu;

    // ------------------------------------------------
    //  LSU interface
    // ------------------------------------------------
    assign inst_lsu    = rvi_load|rvi_store;

    // send lsu request one by one, align to posedge clock
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni) 
            lsu_req_o <= 1'b0;
        else if (lsu_ack_i)
            lsu_req_o <= 1'b0;
        // keep if_vld_pos to make sure this is a effective l/d instruction
        else if ( if_vld_pos & inst_lsu & ~irq_ex_vld )
            lsu_req_o <= 1'b1;
   `ifdef SOPHON_CLIC
        // clic load npc
        else if ( clic_hard_ack & clic_irq_shv_i )
            lsu_req_o <= 1'b1;
    `endif
    end

    always_comb begin
        if ( inst_lsu ) begin
        `ifdef SOPHON_CLIC
            if ( clic_npc_load )
                lsu_addr_o = {mtvt[31:6], 6'd0} + (clic_irq_id_i_1d<<2);
            else
        `endif
                lsu_addr_o = adder_result[31:0];
        end
    `ifdef SOPHON_CLIC
        else if ( clic_npc_load )
            lsu_addr_o = {mtvt[31:6], 6'd0} + (clic_irq_id_i_1d<<2);
    `endif
        else 
            lsu_addr_o = 32'd0;
    end

    always_comb begin
        if ( lsu_req_o ) begin
            unique case (1)
                is_lw,
                is_sw: lsu_size_o = 2'b10;
                is_lh,
                is_sh,
                is_lhu: lsu_size_o = 2'b01;
                is_lb,
                is_sb,
                is_lbu: lsu_size_o = 2'b00;
                // should be 2'b10, CLIC load 4 byte
                default : lsu_size_o = 2'b10;
            endcase
        end
        else 
            lsu_size_o = 32'd0;
    end

    assign lsu_we_o   = `ifdef SOPHON_CLIC clic_npc_load ? 1'b0: `endif (lsu_req_o&rvi_store) ? 1'b1 : 1'b0 ;
    assign lsu_amo_o  = 4'd0; 

    // capture at negedge to align lsu_stall & npc
    always_ff @(posedge clk_neg_i, negedge rst_ni) begin
        if(~rst_ni) 
            lsu_valid <= 1'b0;
        else 
            lsu_valid <= lsu_req_o & lsu_ack_i;
    end

    always_ff @(posedge clk_neg_i, negedge rst_ni) begin
        if(~rst_ni) begin
            lsu_error <= 1'b0;
        end
        else if ( lsu_req_o & lsu_ack_i ) begin
            lsu_error <= lsu_error_i;
        end
    end

    assign if_stall_lsu =     ( if_vld_neg & inst_lsu & ~irq_ex_vld )
                            | ( lsu_req_o & ~lsu_valid );

    assign wb_lsu  = lsu_valid & rvi_load;

    // ------------------------------------------------
    //  load result
    // ------------------------------------------------
    always_comb begin
        lsu_result = 32'd0;
        if ( is_lw ) begin
            lsu_result = lsu_rdata_i[31:0];
        end
        else if ( is_lh ) begin
            if (lsu_addr_o[1]==1'b1) 
                lsu_result = { {16{lsu_rdata_i[31]}}, lsu_rdata_i[31:16] };
            else
                lsu_result = { {16{lsu_rdata_i[15]}}, lsu_rdata_i[15:0] };
        end
        else if ( is_lhu ) begin
            if (lsu_addr_o[1]==1'b1) 
                lsu_result = { 16'd0, lsu_rdata_i[31:16] };
            else
                lsu_result = { 16'd0, lsu_rdata_i[15:0] };
        end
        else if ( is_lb ) begin
            if (lsu_addr_o[1:0]==2'd0) 
                lsu_result = { {24{lsu_rdata_i[7]}}, lsu_rdata_i[7:0] };
            else if (lsu_addr_o[1:0]==2'd1) 
                lsu_result = { {24{lsu_rdata_i[15]}}, lsu_rdata_i[15:8] };
            else if (lsu_addr_o[1:0]==2'd2) 
                lsu_result = { {24{lsu_rdata_i[23]}}, lsu_rdata_i[23:16] };
            else if (lsu_addr_o[1:0]==2'd3) 
                lsu_result = { {24{lsu_rdata_i[31]}}, lsu_rdata_i[31:24] };
        end
        else if ( is_lbu ) begin
            if (lsu_addr_o[1:0]==2'd0) 
                lsu_result = { {24'd0}, lsu_rdata_i[7:0] };
            else if (lsu_addr_o[1:0]==2'd1) 
                lsu_result = { {24'd0}, lsu_rdata_i[15:8] };
            else if (lsu_addr_o[1:0]==2'd2) 
                lsu_result = { {24'd0}, lsu_rdata_i[23:16] };
            else if (lsu_addr_o[1:0]==2'd3) 
                lsu_result = { {24'd0}, lsu_rdata_i[31:24] };
        end
    end

    // ------------------------------------------------
    //  store data
    // ------------------------------------------------
    always_comb begin
        lsu_strb_o = 4'b0000;
        lsu_wdata_o = 32'd0;
        if (lsu_req_o) begin
            if (is_sw) begin
                lsu_strb_o = 4'b1111;
                lsu_wdata_o = rs2_val;
            end
            else if (is_sh) begin
                if (lsu_addr_o[1]==1'b1) begin
                    lsu_strb_o = 4'b1100;
                    lsu_wdata_o = {rs2_val[15:0], 16'd0};
                end
                else begin
                    lsu_strb_o = 4'b0011;
                    lsu_wdata_o = { 16'd0, rs2_val[15:0]};
                end
            end
            else if (is_sb) begin
                if (lsu_addr_o[1:0]==2'd0) begin
                    lsu_strb_o = 4'b0001;
                    lsu_wdata_o = { 24'd0, rs2_val[7:0]};
                end
                else if (lsu_addr_o[1:0]==2'd1) begin
                    lsu_strb_o = 4'b0010;
                    lsu_wdata_o = { 16'd0, rs2_val[7:0], 8'd0};
                end
                else if (lsu_addr_o[1:0]==2'd2) begin
                    lsu_strb_o = 4'b0100;
                    lsu_wdata_o = { 8'd0, rs2_val[7:0], 16'd0};
                end
                else if (lsu_addr_o[1:0]==2'd3) begin
                    lsu_strb_o = 4'b1000;
                    lsu_wdata_o = { rs2_val[7:0], 24'd0};
                end
            end
            else begin
                lsu_strb_o = 4'b0000;
                lsu_wdata_o = 32'd0;
            end
        end
    end

    // ------------------------------------------------
    //  LSU address misalign
    // ------------------------------------------------
    always_comb begin
        unique case (1)
            is_lw   : load_addr_misalign = |lsu_addr_o[1:0] ;
            is_lh   ,
            is_lhu  : load_addr_misalign = lsu_addr_o[0] ;
            is_lb   ,
            is_lbu  : load_addr_misalign = 1'b0;
            default : load_addr_misalign = 1'b0;
        endcase
    end

    always_comb begin
        unique case (1)
            is_sw   : store_addr_misalign = |lsu_addr_o[1:0] ;
            is_sh   : store_addr_misalign = lsu_addr_o[0] ;
            is_sb   : store_addr_misalign = 1'b0 ;
            default : store_addr_misalign = 1'b0 ;
        endcase
    end

    // ------------------------------------------------
    // LSU access fault: decide by platform
    // ------------------------------------------------
    assign store_access_fault = rvi_store & lsu_valid & lsu_error;
    assign load_access_fault  =                   (  rvi_load
                                 `ifdef SOPHON_CLIC  | clic_npc_load `endif
                                                  )
                                                   & lsu_valid 
                                                   & lsu_error;


    // ----------------------------------------------------------------------
    //  ==== CSR REGISTER
    // ----------------------------------------------------------------------
    logic        csr_wr, csr_rd;
    logic [11:0] csr_addr;
    logic [31:0] csr_wdata, csr_rdata;
    logic [31:0] csr_rdata_dm, csr_rdata_rvi `ifdef SOPHON_CLIC ,csr_rdata_clic `endif ;

    logic [1:0]  curr_priv;
    logic        is_clic;
    logic        is_csr_rvi, is_csr_dm `ifdef SOPHON_CLIC ,is_csr_clic `endif ;

`ifdef SOPHON_CLIC
    logic [7:0]  curr_clic_level;
    logic        clic_en_pending;
    logic        mnxti_vld, mnxti_clr;
    logic        csr_cs_mnxti, csr_wr_mnxti;
    logic        clic_irq_direct_vld, clic_irq_vector_vld;
    logic        clic_irq_vld;
    logic [4:0]  mnxti_id;
    logic        csr_wr_mnxti_pos, csr_wr_mnxti_pos_1d;
    logic        wb_stall_clic;
    logic        clic_npc_load_error;
`endif


    // only support m mode
    assign curr_priv = 2'b11;
    assign csr_addr  = inst_data_1d[31:20];
    assign wb_csr    = rvi_csr;

    always_comb begin
        csr_wdata = 32'd0;
        unique case (1)
            is_csrrw  : csr_wdata =  rs1_val;
            is_csrrs  : csr_wdata =  rs1_val | csr_rdata;
            is_csrrc  : csr_wdata = ~rs1_val & csr_rdata;
            is_csrrwi : csr_wdata =  {27'd0, rs1_idx};
            is_csrrsi : csr_wdata =  {27'd0, rs1_idx} | csr_rdata;
            is_csrrci : csr_wdata = ~{27'd0, rs1_idx} & csr_rdata;
            default   : csr_wdata = 32'd0;
        endcase
    end

    always_comb begin
        csr_wr = 1'b0;
        csr_rd = 1'b0;
        if ( inst_data_1d_vld & (is_csrrw|is_csrrwi) ) begin
            csr_wr = 1'b1;
            csr_rd = |rd_idx; // rd != x0
        end
        else if ( inst_data_1d_vld & (is_csrrs|is_csrrc|is_csrrsi|is_csrrci) ) begin
            // rs1 or uimm != x0, thay are in the smae location
            csr_wr = |rs1_idx; 
            csr_rd = 1'b1;
        end
    end

    // ------------------------------------------------
    //  CSR Register Write Logic
    // ------------------------------------------------
    // MSTATUS
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni) begin
            mstatus_mie  <= 1'b0;
        end
        else if ( if_vld & irq_ex_vld ) begin
            mstatus_mie  <= 1'b0;
        end
        else if ( is_mret & retire_vld ) begin
            mstatus_mie <= mstatus_mpie;
        end
        else if ( rvi_csr && csr_wr && (csr_addr==SOPHON_PKG::CSR_MSTATUS) ) begin
            mstatus_mie  <= csr_wdata[3] ;
        end
        `ifdef SOPHON_CLIC
            else if ( clic_hard_ack ) begin
                mstatus_mie  <= 1'b0;
            end
            // access by mnxti, always update mie regardless of CLIC interface
            //else if ( is_clic & csr_wr_mnxti ) begin
            else if ( is_clic & csr_cs_mnxti & csr_wr ) begin
                mstatus_mie  <= csr_wdata[3] ;
            end
        `endif
    end

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni) begin
            mstatus_mpie <= 1'b1;
            mstatus_mpp  <= 2'b11;
        end
        else if ( irq_ex_vld ) begin
            mstatus_mpie <= mstatus_mie;
            mstatus_mpp  <= curr_priv;
        end
        else if ( is_mret & retire_vld ) begin
            mstatus_mpie <= 1'b1;
            mstatus_mpp  <= 2'b11;
        end
        else if ( rvi_csr && csr_wr && (csr_addr==SOPHON_PKG::CSR_MSTATUS) ) begin
            mstatus_mpie <= csr_wdata[7] ;
            mstatus_mpp  <= csr_wdata[11+:2] | 2'b11 ; // WARL 
        end
        `ifdef SOPHON_CLIC
            else if ( is_clic && rvi_csr && csr_wr && (csr_addr==SOPHON_PKG::CSR_MCAUSE) ) begin
                mstatus_mpie <= csr_wdata[27] ;
                mstatus_mpp  <= csr_wdata[29:28] | 2'b11 ; // WARL
            end
        `endif
    end

    // MIP
    // Sophon only support M mode, MSIP/MTIP/MEIP are read-only register

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni) begin
            mie <= 32'd0;
        end
        else if ( ~is_clic && rvi_csr && csr_wr && (csr_addr==SOPHON_PKG::CSR_MIE) ) begin
            mie <= { 20'd0,  
                     csr_wdata[SOPHON_PKG::BIT_MEI] , 3'd0, 
                     csr_wdata[SOPHON_PKG::BIT_MTI] , 3'd0,
                     csr_wdata[SOPHON_PKG::BIT_MSI] , 3'd0 };
        end
    end

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni) begin
            mtvec <= 32'd0;
        end
        else if ( rvi_csr && csr_wr && (csr_addr==SOPHON_PKG::CSR_MTVEC) ) begin
            `ifdef SOPHON_CLIC
                if ( (csr_wdata[1:0]==2'b00) || (csr_wdata[1:0]==2'b01) )
                    mtvec <= csr_wdata;
                else if ( csr_wdata[1:0]==2'b11 )
                    mtvec <= csr_wdata & 32'hFFFF_FFC3; // 'hC3='b11000011
                else 
                    mtvec <= { csr_wdata[31:6], mtvec[5:0] };
            `else
                // WARL 'hD='b1101, in CLINT only platform, bit1=1 is illegal
                mtvec <= csr_wdata & 32'hFFFF_FFFD;
            `endif
        end
    end

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni) begin
            mscratch <= 32'd0;
        end
        else if ( rvi_csr && csr_wr && (csr_addr==SOPHON_PKG::CSR_MSCRATCH) ) begin
            mscratch <= csr_wdata;
        end
    end
    
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni) 
            mepc <= 32'd0;
        else if ( irq_ex_vld ) 
            mepc <= pc;
        `ifdef SOPHON_CLIC
            else if ( clic_npc_load_error )
                mepc <= lsu_addr_o;
        `endif
        else if ( rvi_csr && csr_wr && (csr_addr==SOPHON_PKG::CSR_MEPC) ) begin
            mepc <= {csr_wdata[31:2], 2'd0};
        end
    end

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni)                           mcause <= 32'd0;
        // exception
        else if (ex_branch                  ) mcause <= {1'b0, 31'd0};
        else if (ex_inst_access             ) mcause <= {1'b0, 31'd1};
        else if (ex_illg_instr|ex_csr_addr  ) mcause <= {1'b0, 31'd2};
        else if (is_ebreak                  ) mcause <= {1'b0, 31'd3};
        else if (load_addr_misalign         ) mcause <= {1'b0, 31'd4};
        else if (load_access_fault          ) mcause <= {1'b0, 31'd5};
        else if (store_addr_misalign        ) mcause <= {1'b0, 31'd6};
        else if (store_access_fault         ) mcause <= {1'b0, 31'd7};
        else if (is_ecall                   ) mcause <= {1'b0, 31'd11};
        // interrupt
        else if (msi_en_pending             ) mcause <= {1'b1, 31'd3};
        else if (mti_en_pending             ) mcause <= {1'b1, 31'd7};
        else if (mei_en_pending             ) mcause <= {1'b1, 31'd11};
        `ifdef SOPHON_CLIC
        else if (clic_irq_vld               ) mcause <= {1'b1, mcause[30:5], clic_irq_id_i};
        else if (csr_wr_mnxti               ) mcause <= {1'b1, mcause[30:5], clic_irq_id_i};
        `endif
        // software write
        else if ( rvi_csr && csr_wr && (csr_addr==SOPHON_PKG::CSR_MCAUSE) ) 
            `ifdef SOPHON_CLIC
                // in CLIC mode, this physical register only hold interrupt flag & id, other 
                // field should not be written, otherwise it will disturb CLINT mode value
                mcause <= {csr_wdata[31], mcause[30:5], csr_wdata[4:0]};
            `else
                mcause <= csr_wdata;
            `endif
    end

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni)                           mtval <= 32'd0;
        // exception
        else if (ex_branch                  ) mtval <= jump_branch_target;
        else if (ex_inst_access             ) mtval <= inst_addr_o;
        else if (ex_illg_instr|ex_csr_addr  ) mtval <= inst_data_1d;
        else if (is_ebreak                  ) mtval <= 32'd0;
        else if (load_addr_misalign         ) mtval <= lsu_addr_o;
        else if (load_access_fault          ) mtval <= lsu_addr_o;
        else if (store_addr_misalign        ) mtval <= lsu_addr_o;
        else if (store_access_fault         ) mtval <= lsu_addr_o;
        else if (is_ecall                   ) mtval <= 32'd0;
        // interrupt
        else if (msi_en_pending             ) mtval <= 32'd0;
        else if (mti_en_pending             ) mtval <= 32'd0;
        else if (mei_en_pending             ) mtval <= 32'd0;
        // software write
        else if ( rvi_csr && (csr_addr==SOPHON_PKG::CSR_MTVAL) ) mtval <= csr_wdata;
    end

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni) 
            mcycle <= 64'd0;
        else if ( rvi_csr && csr_wr && (csr_addr==SOPHON_PKG::CSR_MCYCLEH) ) 
            mcycle <= {csr_wdata, mcycle[31:0]};
        else if ( rvi_csr && csr_wr && (csr_addr==SOPHON_PKG::CSR_MCYCLE) ) 
            mcycle <= {mcycle[63:32], csr_wdata};
        else if (rst_dly_neg)
            mcycle <= mcycle + 64'd1;
    end

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni) 
            minstret <= 64'd0;
        else if ( rvi_csr && csr_wr && (csr_addr==SOPHON_PKG::CSR_MINSTRETH) ) 
            minstret <= {csr_wdata, minstret[31:0]};
        else if ( rvi_csr && csr_wr && (csr_addr==SOPHON_PKG::CSR_MINSTRET) ) 
            minstret <= {minstret[63:32], csr_wdata};
        else if ( retire_vld ) 
            minstret <= minstret + 64'd1;
    end


`ifdef SOPHON_CLIC

        always_ff @(posedge clk_i, negedge rst_ni) begin
            if(~rst_ni) 
                mtvt <= 32'd0;
            else if ( rvi_csr && csr_wr && (csr_addr==SOPHON_PKG::CSR_MTVT) ) 
                mtvt <= csr_wdata & 32'hFFFF_FFC0; // Align to 64 byte
        end

        assign clic_irq_intthresh_o = mintthresh;
        always_ff @(posedge clk_i, negedge rst_ni) begin
            if(~rst_ni) begin
                mintthresh <= 32'd0;
            end
            else if ( rvi_csr && csr_wr && (csr_addr==SOPHON_PKG::CSR_MINTTHRESH) ) begin
                mintthresh <= csr_wdata & 32'h0000_00FF;
            end
        end

        always_ff @(posedge clk_i, negedge rst_ni) begin
            if (~rst_ni) 
                mpil <= 8'd0;
            else if ( clic_irq_vld )
                mpil <= curr_clic_level;
            else if ( rvi_csr && csr_wr && is_clic && (csr_addr==SOPHON_PKG::CSR_MCAUSE) ) 
                mpil <= csr_wdata[23:16];
        end

        always_ff @(posedge clk_i, negedge rst_ni) begin
            if (~rst_ni) 
                minhv <= 1'b0;
            else if ( clic_irq_vector_vld ) 
                minhv <= 1'b1;
            else if ( clic_npc_load & lsu_valid & (~lsu_error) ) 
                minhv <= 1'b0;
            else if ( rvi_csr && csr_wr && is_clic && (csr_addr==SOPHON_PKG::CSR_MCAUSE) ) 
                minhv <= csr_wdata[30];
        end


        // mnxti
        assign mnxti_vld    = is_clic & clic_irq_req_i & (clic_irq_level_i>mpil) & (clic_irq_level_i>mintthresh) & ~clic_irq_shv_i ;
        assign mnxti        = mnxti_vld ? ( mtvt + (clic_irq_id_i<<2) ) : 32'd0;
        assign csr_cs_mnxti = (csr_addr==SOPHON_PKG::CSR_XNXTI) & ( is_csrrsi | is_csrrci | (is_csrrs&(rs1_idx==5'd0)) );
        assign csr_wr_mnxti = mnxti_vld & csr_cs_mnxti & csr_wr;

        // sent to CLIC to clear clicintip register
        assign mnxti_clr = csr_wr_mnxti_pos & ~csr_wr_mnxti_pos_1d;
        always_ff @(posedge clk_i, negedge rst_ni) begin
            if (~rst_ni) begin
                csr_wr_mnxti_pos <= 1'b0;
                csr_wr_mnxti_pos_1d <= 1'b0;
            end
            else begin
                csr_wr_mnxti_pos <= csr_wr_mnxti;
                csr_wr_mnxti_pos_1d <= csr_wr_mnxti_pos;
            end
        end

        always_ff @(posedge clk_i, negedge rst_ni) begin
            if (~rst_ni) 
                mnxti_id <= 5'd0;
            else if ( mnxti_clr )
                mnxti_id <= 5'd0;
            else if ( csr_wr_mnxti )
                mnxti_id <= clic_irq_id_i;
        end

    `endif


    // ------------------------------------------------
    //  CSR Register Read Logic
    // ------------------------------------------------
    always_comb begin
        csr_rdata   = 32'b0;
        ex_csr_addr = 1'b0;
        if ( rvi_csr ) begin
            unique case ( 1 )
                is_csr_rvi  : csr_rdata = csr_rdata_rvi;
                is_csr_dm   : csr_rdata = csr_rdata_dm;
            `ifdef SOPHON_CLIC
                is_csr_clic : csr_rdata = csr_rdata_clic;
            `endif
                default     : begin 
                              csr_rdata   = 32'd0;
                              ex_csr_addr = 1'b1; 
                              end
            endcase
        end
        else begin
            csr_rdata   = 32'd0;
            ex_csr_addr = 1'b0; 
        end
     end

    // ------------------------------------------------
    //  RV32I CSR register rdata
    // ------------------------------------------------
    always_comb begin
        csr_rdata_rvi   = 32'b0;
        if ( rvi_csr & csr_rd ) begin
            unique case ( csr_addr )
                SOPHON_PKG::CSR_MVENDORID , 
                SOPHON_PKG::CSR_MARCHID   , 
                SOPHON_PKG::CSR_MIMPID    : csr_rdata_rvi = 32'd0;
                SOPHON_PKG::CSR_MHARTID   : csr_rdata_rvi = hart_id_i;
                SOPHON_PKG::CSR_MSTATUS   : csr_rdata_rvi = { 19'd0        , 
                                              mstatus_mpp  , 3'b0, 
                                              mstatus_mpie , 3'b0,
                                              mstatus_mie  , 3'd0 };
                SOPHON_PKG::CSR_MISA      : csr_rdata_rvi = { 2'b01 , // RV32
                                              4'd0  , // WLRL
                                              26'd0   // Extensions
                                            }
                                            // I ISA
                                            | 32'd1 << 8 ;
                SOPHON_PKG::CSR_MIE       : csr_rdata_rvi = {32{~is_clic}} & mie;
                SOPHON_PKG::CSR_MTVEC     : csr_rdata_rvi = mtvec;
                SOPHON_PKG::CSR_MSCRATCH  : csr_rdata_rvi = mscratch;
                SOPHON_PKG::CSR_MEPC      : csr_rdata_rvi = mepc;
                SOPHON_PKG::CSR_MCAUSE    : csr_rdata_rvi = `ifdef SOPHON_CLIC is_clic ? { mcause[31], 
                                                                                       minhv, 
                                                                                       mstatus_mpp, 
                                                                                       mstatus_mpie, 
                                                                                       3'd0, 
                                                                                       mpil, 
                                                                                       4'd0, 
                                                                                       mcause[11:0] }
                                                                                    : `endif
                                                          mcause ;
                SOPHON_PKG::CSR_MTVAL     : csr_rdata_rvi = mtval;
                SOPHON_PKG::CSR_MIP       : csr_rdata_rvi = {32{~is_clic}} & { 19'd0   ,  
                                                                         irq_mei_i , 3'b0, 
                                                                         irq_mti_i , 3'b0,
                                                                         irq_msi_i , 3'd0 };

                SOPHON_PKG::CSR_MCYCLE    : csr_rdata_rvi = mcycle[31:0];
                SOPHON_PKG::CSR_MCYCLEH   : csr_rdata_rvi = mcycle[63:32];

                SOPHON_PKG::CSR_MINSTRET  : csr_rdata_rvi = minstret[31:0];
                SOPHON_PKG::CSR_MINSTRETH : csr_rdata_rvi = minstret[63:32];
                default                 : csr_rdata_rvi   = 32'd0;
            endcase
        end
    end

    assign is_csr_rvi = rvi_csr & csr_addr inside { SOPHON_PKG::CSR_MVENDORID, SOPHON_PKG::CSR_MARCHID, SOPHON_PKG::CSR_MIMPID, SOPHON_PKG::CSR_MHARTID, 
                                                    SOPHON_PKG::CSR_MSTATUS, SOPHON_PKG::CSR_MISA, SOPHON_PKG::CSR_MIE, SOPHON_PKG::CSR_MTVEC, 
                                                    SOPHON_PKG::CSR_MSCRATCH, SOPHON_PKG::CSR_MEPC, SOPHON_PKG::CSR_MCAUSE, SOPHON_PKG::CSR_MTVAL, 
                                                    SOPHON_PKG::CSR_MIP, SOPHON_PKG::CSR_MCYCLE, SOPHON_PKG::CSR_MCYCLEH, SOPHON_PKG::CSR_MINSTRET, 
                                                    SOPHON_PKG::CSR_MINSTRETH
                                                  };


    // ----------------------------------------------------------------------
    //  ==== ENHANCED EXTENSION INTERFACE
    // ----------------------------------------------------------------------
    `ifdef SOPHON_EEI
        logic        op_is_cust0, op_is_cust1;
        logic [4:0]  rs_idx[1:0];
        logic        retire_eei;
        logic        wr_regfile_eei;
        logic [31:0] eei_rd_idx_bit;
        logic [4:0]  eei_rd_start, eei_rd_len_i_inner;
        logic        wb_stall;

        assign op_is_cust0     = opcode==7'b0001011;
        assign op_is_cust1     = opcode==7'b0101011;
        assign rvi_cust        = op_is_cust0|op_is_cust1;

        assign if_stall_eei    = eei_req_o & (~eei_ack_i);

        assign eei_req_o         = rvi_cust;
        assign eei_ext_o         = op_is_cust1 ? 1'b1 : 1'b0;
        assign eei_funct3_o      = funct3;
        assign eei_funct7_o      = funct7;
        assign eei_batch_start_o = op_is_cust0 ? 5'd0 : rs1_idx;
        assign eei_batch_len_o   = op_is_cust0 ? 5'd2 : rs2_idx;

        
        localparam EXT_RF_LEN  = 32 + SOPHON_PKG::EEI_RS_MAX -1;
        logic  [31:0] ext_regfile[EXT_RF_LEN-1:0];
        for (genvar i=0; i<EXT_RF_LEN; i++) begin : gen_ext_regfile
            if ( i<32 ) 
                assign ext_regfile[i] = regfile[i];
            else 
                assign ext_regfile[i] = regfile[i-32];
        end

        assign rs_idx[0] = rs1_idx;
        assign rs_idx[1] = rs2_idx;
        for (genvar i=0; i<SOPHON_PKG::EEI_RS_MAX; i++) begin : gen_eei_rs_val_o
            if ( i<2 ) begin: gen_eei_rs0_rs1
                assign eei_rs_val_o[i] = op_is_cust0 ? ext_regfile [ rs_idx[i] ] : ext_regfile[eei_batch_start_o+i];
            end
            else begin: gen_eei_rs_extent
                assign eei_rs_val_o[i] = ext_regfile[eei_batch_start_o+i];
            end
        end

        always_comb begin
            eei_rd_start = 5'd0;
            eei_rd_len_i_inner   = 5'd0;
            if (eei_rd_op_i==2'd1) begin
                eei_rd_start = rd_idx;
                eei_rd_len_i_inner   = 5'd1;
            end
            else if (eei_rd_op_i==2'd2) begin
                eei_rd_start = rs1_idx;
                eei_rd_len_i_inner   = eei_rd_len_i;
            end
        end

        integer j;
        assign wr_regfile_eei = ~wb_stall & eei_req_o & eei_ack_i & (~eei_error_i) & (eei_rd_op_i==2'd1 || eei_rd_op_i==2'd2);
        always_comb begin
            eei_rd_idx_bit = 32'd0;
            for (j=0; j<32; j=j+1)
                if (eei_rd_op_i==2'd1)
                    eei_rd_idx_bit[j] = ( rd_idx==j ) ? 1'b1 : 1'b0;
                else
                    eei_rd_idx_bit[j] = ( (eei_rd_start<=6'(j)) && ((eei_rd_len_i_inner+eei_rd_start)>6'(j)) ) ? 1'b1 : 1'b0;
        end

        assign retire_eei   = ~wb_stall & eei_req_o & eei_ack_i & (~eei_error_i);
    `endif


    // ----------------------------------------------------------------------
    //  ==== CLIC
    // ----------------------------------------------------------------------
    `ifdef SOPHON_CLIC

        assign clic_mnxti_clr_o  = mnxti_clr;
        assign clic_mnxti_id_o   = mnxti_id;

        assign is_clic         = (mtvec[5:0]==6'b0000_11) ? 1'b1 : 1'b0;
        assign if_stall_clic   = clic_npc_load;
        assign clic_en_pending = is_clic & clic_irq_req_i && mstatus_mie && (clic_irq_level_i>curr_clic_level) ;

        always_ff @(posedge clk_i, negedge rst_ni) begin
            if (~rst_ni) begin
                clic_irq_id_i_1d <= 5'd0;
            end
            else if ( clic_irq_req_i & clic_irq_ack_o )
                clic_irq_id_i_1d <= clic_irq_id_i;
            else if ( is_mret & retire_vld )
                clic_irq_id_i_1d <= 5'd0;
        end

        // ------------------------------------------------
        //  CLIC IRQ valid
        // ------------------------------------------------

        // hard_ack change npc and update all irq context,
        // last 1 cycle because mie will be cleared in next cycle
        // 1. if there is an outstanding lsu request, wait
        // 2. if the current instrunction is load/store, there is no problem, clic request will
        //    override load/store request in lsu interface
        assign clic_hard_ack  = clic_en_pending & ~lsu_req_o;
        assign clic_irq_ack_o = clic_hard_ack | mnxti_clr;

        // negedge signal, update irq context
        always_ff @(posedge clk_neg_i, negedge rst_ni) begin
            if(~rst_ni) begin
                clic_irq_direct_vld <= 1'b0;
                clic_irq_vector_vld <= 1'b0;
            end
            else begin
                clic_irq_direct_vld <= clic_irq_req_i & clic_hard_ack & (~clic_irq_shv_i);
                clic_irq_vector_vld <= clic_irq_req_i & clic_hard_ack &   clic_irq_shv_i ;
            end
        end

        assign clic_irq_vld        = clic_irq_direct_vld | clic_irq_vector_vld;

        // ------------------------------------------------
        //  CLIC vector mode
        // ------------------------------------------------
        always_ff @(posedge clk_neg_i, negedge rst_ni) begin
            if(~rst_ni) begin
                clic_npc_load <= 1'b0;
            end
            else if ( clic_irq_req_i & clic_hard_ack & clic_irq_shv_i ) begin
                clic_npc_load <= 1'b1;
            end
            else if ( clic_npc_load & lsu_valid ) begin
                clic_npc_load <= 1'b0;
            end
        end

        always_ff @(posedge clk_neg_i, negedge rst_ni) begin
            if(~rst_ni) 
                clic_npc_load_1d <= 1'b0;
            else
                clic_npc_load_1d <= clic_npc_load;
        end

        always_ff @(posedge clk_i, negedge rst_ni) begin
            if(~rst_ni) 
                clic_npc_vector <= 32'd0;
            else if (clic_npc_load & lsu_req_o & lsu_ack_i)
                clic_npc_vector <= lsu_rdata_i;
        end

        assign clic_npc_load_error = clic_npc_load & lsu_valid & lsu_error;

        // ------------------------------------------------
        //  current clic level
        // ------------------------------------------------
        always_ff @(posedge clk_i, negedge rst_ni) begin
            if(~rst_ni) begin
                curr_clic_level <= 8'd0;
            end
            else if (clic_hard_ack) begin
                curr_clic_level <= clic_irq_level_i;
            end
            else if (is_mret) begin
                curr_clic_level <= mpil; 
            end
            else if ( csr_wr_mnxti ) begin
                curr_clic_level <= clic_irq_level_i;
            end
        end

        // ------------------------------------------------
        //  CLIC CSR register rdata
        // ------------------------------------------------
        logic  not_rd_mnxti;
        assign not_rd_mnxti = (csr_addr==SOPHON_PKG::CSR_XNXTI) ? csr_cs_mnxti : 1'b1;

        always_comb begin
            csr_rdata_clic = 32'b0;
            if ( rvi_csr & & csr_rd & not_rd_mnxti ) begin
                unique case (csr_addr)
                    SOPHON_PKG::CSR_MTVT       : csr_rdata_clic = mtvt; 
                    SOPHON_PKG::CSR_MINTSTATUS : csr_rdata_clic = {curr_clic_level,24'd0};
                    SOPHON_PKG::CSR_MINTTHRESH : csr_rdata_clic = mintthresh;
                    SOPHON_PKG::CSR_XNXTI      : csr_rdata_clic = mnxti;
                    default                  : csr_rdata_clic = 32'd0;
                endcase
            end
        end

        assign is_csr_clic = rvi_csr & csr_addr inside { SOPHON_PKG::CSR_MTVT, SOPHON_PKG::CSR_MINTSTATUS, 
                                                         SOPHON_PKG::CSR_MINTTHRESH, SOPHON_PKG::CSR_XNXTI };
    `else
        assign is_clic    = 1'b0;
    `endif


    // ----------------------------------------------------------------------
    //  ==== DEBUG MODE
    // ----------------------------------------------------------------------
    logic        [3:0]     xdebugver;
    logic        [1:0]     prv;
    logic                  step;
    logic                  dm_req_neg;
    logic        [2:0]     dm_cause_d, dm_cause;
    logic        [31:0]    dscratch0, dscratch1, dscratch2;

    always_ff @(posedge clk_neg_i, negedge rst_ni) begin
        if(~rst_ni) begin
            dm_req_neg <= 1'b0;
        end
        else begin
            dm_req_neg <= dm_req_i;
        end
    end

    assign if_stall_dm = dm_start;

    // dm_start should only ariase when there is no pending instruction fetch 
    // request, i.e. wait a complete instruction fetching. 
    always_comb begin
        if ( ~debug_mode & ( retire_vld | (ex_vld&if_vld_neg) ) ) begin
            if ( is_ebreak & ebreakm ) begin // priority 3
                dm_start = 1'b1;
                dm_cause_d = 3'd1;
            end
            else if ( dm_req_neg ) begin // priority 1
                dm_start = 1'b1;
                dm_cause_d = 3'd3;
            end
            else if ( step ) begin // priority 0
                dm_start = 1'b1;
                dm_cause_d = 3'd4;
            end
            else begin
                dm_start = 1'b0;
                dm_cause_d = 3'd0;
            end
        end
        else begin
            dm_start = 1'b0;
            dm_cause_d = 3'd0;
        end
    end

    always_ff @(posedge clk_neg_i, negedge rst_ni) begin
        if(~rst_ni) begin
            debug_mode <= 1'b0;
            dm_cause <= 3'd0;
        end
        else if ( dm_start ) begin
            debug_mode <= 1'b1;
            dm_cause <= dm_cause_d;
        end
        else if ( debug_mode & retire_vld & is_dret ) begin
            debug_mode <= 1'b0;
            dm_cause <= 3'd0;
        end
    end

    // ------------------------------------------------
    //  debug mode CSR register write
    // ------------------------------------------------

    assign xdebugver = 4'd4;

    assign prv = curr_priv;

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni) begin
            ebreakm <= 1'b0;
            step    <= 1'b0;
        end
        else if ( debug_mode & rvi_csr & csr_wr & (csr_addr==SOPHON_PKG::CSR_DCSR) ) begin
            ebreakm <= csr_wdata[15];
            step    <= csr_wdata[ 2];
        end
    end

    // // dpc
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni) 
            dpc <= 32'd0;
        else if ( debug_mode & rvi_csr & csr_wr & (csr_addr==SOPHON_PKG::CSR_DPC) ) 
            dpc <= csr_wdata;
        // ebreak records the current pc, debugger takes care of it
        else if ( ~debug_mode & retire_vld & is_ebreak & ebreakm )
            dpc <= pc;
        // step records the next pc
        else if ( ~debug_mode & ( retire_vld | (ex_vld&if_vld_neg) ) & step ) 
            dpc <= npc;
        // record the last npc before debug mode
        else if ( ~debug_mode & ( retire_vld | (ex_vld&if_vld_neg) ) & dm_req_neg)
           dpc <= npc;
    end

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni) begin
            dscratch0 <= 32'd0;
            dscratch1 <= 32'd0;
            dscratch2 <= 32'd0;
        end
        else if ( debug_mode & rvi_csr & csr_wr ) begin
            if (csr_addr==SOPHON_PKG::CSR_DSCRATCH0)  dscratch0 <= csr_wdata;
            if (csr_addr==SOPHON_PKG::CSR_DSCRATCH1)  dscratch1 <= csr_wdata;
            if (csr_addr==SOPHON_PKG::CSR_DSCRATCH2)  dscratch2 <= csr_wdata;
        end
    end

    // ------------------------------------------------
    //  debug mode CSR register rdata
    // ------------------------------------------------
    assign is_csr_dm = debug_mode & rvi_csr & csr_addr inside { SOPHON_PKG::CSR_DCSR, SOPHON_PKG::CSR_DPC, SOPHON_PKG::CSR_DSCRATCH0,
                                                                SOPHON_PKG::CSR_DSCRATCH1, SOPHON_PKG::CSR_DSCRATCH2
                                                              };

    always_comb begin
        csr_rdata_dm   = 32'b0;
        if ( debug_mode & rvi_csr & csr_rd ) begin
            unique case (csr_addr)
                SOPHON_PKG::CSR_DCSR      : csr_rdata_dm = { xdebugver, 12'd0, ebreakm, 6'd0, dm_cause, 3'd0, step, prv };
                SOPHON_PKG::CSR_DPC       : csr_rdata_dm = dpc;
                SOPHON_PKG::CSR_DSCRATCH0 : csr_rdata_dm = dscratch0;
                SOPHON_PKG::CSR_DSCRATCH1 : csr_rdata_dm = dscratch1;
                SOPHON_PKG::CSR_DSCRATCH2 : csr_rdata_dm = dscratch2;
                default                 : csr_rdata_dm = 32'd0;
            endcase
        end
    end


    // ----------------------------------------------------------------------
    //  ==== INSTRUCTION COMMIT
    // ----------------------------------------------------------------------
    logic       wr_regfile;
    logic       retire_ebreak;
    logic       wb_stall_lsu;
    logic       retire_wr_rd, retire_no_rd;
    logic       retire_store, retire_ecall;

    always_comb begin
        unique case (1)
            wb_adder   : rd_val = adder_result[31:0];
            wb_cmp     : rd_val = {31'b0, cmp_result};
            wb_bit     : rd_val = bit_result;
            wb_shifter : rd_val = shifter_result;
            wb_lsu     : rd_val = lsu_result;
            wb_csr     : rd_val = csr_rdata;
            is_lui     : rd_val = u_u_imm[31:0];
            is_jal     , 
            is_jalr    : rd_val = pc + 4;
            default    : rd_val = 32'd0;
        endcase
    end

    assign wb_stall_lsu  = ~(if_vld_neg|lsu_valid);

`ifdef SOPHON_CLIC
    assign wb_stall_clic = clic_npc_load|clic_npc_load_1d;
`endif

    assign wb_stall    = irq_vld 
                       | ex_vld 
                       | wb_stall_lsu
    `ifdef SOPHON_CLIC | wb_stall_clic `endif ;

    assign wr_regfile = ~wb_stall & ( wb_adder   | wb_cmp | wb_bit
                                    | wb_shifter | wb_lsu | wb_csr
                                    | is_lui     | is_jal | is_jalr );

    // regfile
    genvar i;
    generate
        for (i=1; i<32; i=i+1) begin:gen_regfile
            //always_ff @(posedge clk_i, negedge rst_ni) begin
            always_ff @(posedge clk_i) begin
                // if(~rst_ni) begin
                //     regfile[i] <= 32'd0;
                // end
                // // Sophon write port
                // else if ( wr_regfile && (rd_idx==i) ) begin
                if ( wr_regfile && (rd_idx==i) ) begin
                    regfile[i] <= rd_val;
                end
            `ifdef SOPHON_EEI
                // EEI write port
                else if ( wr_regfile_eei && (eei_rd_idx_bit[i]==1) ) begin
                    regfile[i] <= eei_rd_val_i[i-eei_rd_start];
                end
            `endif
            end
        end
    endgenerate
    assign regfile[0] = 32'd0;

    assign rs1_val = regfile[rs1_idx];
    assign rs2_val = regfile[rs2_idx];

    // retire instruction
    assign retire_store  = rvi_store & lsu_valid;
    assign retire_ecall  = is_ecall  & if_vld_neg & ~irq_vld;
    assign retire_ebreak = is_ebreak & if_vld_neg & ~irq_vld;

    assign retire_wr_rd = wr_regfile;
    assign retire_no_rd = retire_ecall 
                        | retire_ebreak
                        | ( ~wb_stall & ( rvi_branch | retire_store | is_fence
                                        | is_fence_i | (rvi_csr & ~csr_wr) | is_dret
                                        | is_mret | is_wfi) );

    assign retire_vld = retire_wr_rd 
                      | retire_no_rd 
    `ifdef SOPHON_EEI | retire_eei    `endif  ;


    // ----------------------------------------------------------------------
    //  ==== EXCEPTION & INTERRUPT
    // ----------------------------------------------------------------------

    assign irq_ex_vld = irq_vld | ex_vld;

    // ------------------------------------------------
    //  interrupt
    // ------------------------------------------------
    assign mei_en_pending  = mstatus_mie & irq_mei_i & mie[SOPHON_PKG::BIT_MEI] & (~is_clic);
    assign mti_en_pending  = mstatus_mie & irq_mti_i & mie[SOPHON_PKG::BIT_MTI] & (~is_clic);
    assign msi_en_pending  = mstatus_mie & irq_msi_i & mie[SOPHON_PKG::BIT_MSI] & (~is_clic);

    always_ff @(posedge clk_neg_i, negedge rst_ni) begin
        if(~rst_ni) 
            clint_irq_vld <= 1'b0;
        else if ( ~lsu_req_o & (mei_en_pending | mti_en_pending | msi_en_pending) )
            clint_irq_vld <= 1'b1;
        else if ( if_vld )
            clint_irq_vld <= 1'b0;
    end

    assign irq_vld =                    clint_irq_vld 
                     `ifdef SOPHON_CLIC | clic_irq_vld  `endif ;

    // ----------------------------------------------------------------------
    //  Exception
    // ----------------------------------------------------------------------

    //  exception: instruction access
    always_ff @(posedge clk_neg_i, negedge rst_ni) begin
        if (~rst_ni)
            ex_inst_access <= 1'b0;
        else if (if_vld)
            ex_inst_access <= inst_error_i;
    end

    // exception: branch addr misaligned 
    assign ex_branch =   ( jump_branch_target[1] & (is_jal|is_jalr) )
                       | ( jump_branch_target[1] & branch_taken & rvi_branch );

    //  exception: illegal instruction
    assign ex_illg_instr = inst_data_1d_vld & ~( | rvi_csr     | rvi_branch  | rvi_jump   
                                                 | rvi_load    | rvi_store   | rvi_alui    
                                                 | rvi_alu     | rvi_system  | rvi_other  
                                                 | rvi_fence
                                                 `ifdef SOPHON_EEI | rvi_cust `endif 
                                               );

    // exception: LSU 
    // lsu_addr_o may change in the last half cycle if rs1=rd and cause a wrong exception, mask it using lsu_valid
    assign ex_load_store = inst_data_1d_vld & (   ( ~lsu_valid & ( load_addr_misalign | store_addr_misalign )) 
                                                | ( load_access_fault | store_access_fault ) );

    // priority: irq > exception
    assign ex_vld = ~npc_sel_bootaddr & ~irq_vld & ( ex_illg_instr | ex_load_store  | ex_csr_addr |
                                                     ex_branch     | ex_inst_access | is_ecall    |
                                                     (is_ebreak & (~ebreakm|debug_mode)) ) ;


`ifdef PROBE
    assign probe_sophon_o[31:0]   = pc               ; 
    assign probe_sophon_o[63:32]  = inst_data_1d     ; 
    assign probe_sophon_o[95:64]  = dpc              ; 
    assign probe_sophon_o[127:96] = npc              ; 
    assign probe_sophon_o[128]    = if_vld           ; 
    assign probe_sophon_o[129]    = inst_data_1d_vld ; 
    assign probe_sophon_o[130]    = retire_vld       ; 
    assign probe_sophon_o[131]    = ex_vld           ; 
    assign probe_sophon_o[132]    = debug_mode       ; 
    assign probe_sophon_o[133]    = is_dret          ; 
    assign probe_sophon_o[134]    = rvi_csr          ; 
    assign probe_sophon_o[135]    = csr_wr           ; 
`endif
    

`ifndef VERILATOR

    inst_itf_stable: assert property ( @(posedge clk_neg_i) disable iff (~rst_ni) 
                                       ((inst_req_o && !inst_ack_i) |=> $stable(inst_addr_o)) ) 
                            else $fatal(1,"Instruction fetcing interface unstable!");

    inst_lsu_stable: assert property ( @(posedge clk_neg_i) disable iff (~rst_ni) 
                                       ((lsu_req_o && !lsu_ack_i) |=> $stable({lsu_we_o, lsu_addr_o, lsu_wdata_o, lsu_amo_o, lsu_size_o, lsu_strb_o})) ) 
                            else $fatal(1,"LSU interface unstable!");

`endif


endmodule

