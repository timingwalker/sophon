task axi_slv_port_replace_write(input logic [31:0] addr, input logic [63:0] wdata, input logic [2:0] size );
    logic [63:0] old_rdata;
    logic [63:0] rdata;

    axi_rand_master.run_read_single(old_rdata, 1,1, addr);
    axi_rand_master.run_write_word(addr, wdata, 8'd0, size);
    axi_rand_master.run_read_single(rdata, 1,1, addr);
    if ( rdata !== wdata ) begin
        $display("\nAXI_SLV_PORT 0x%h test 1 FAIL!!!: Wdata=%h, rdata=%h", addr,wdata, rdata);
        `ifndef DBG_ENABLE
            $finish;
        `endif
    end
    else $display("\nAXI_SLV_PORT 0x%h test 1 PASS: Wdata=%h, rdata=%h",addr, wdata, rdata);

    axi_rand_master.run_write_word(addr, old_rdata, 8'd0, size);
    axi_rand_master.run_read_single(rdata, 1,1, addr);
    if ( rdata !== old_rdata ) begin
        $display("AXI_SLV_PORT 0x%h test 2 FAIL!!!: rdata=%h, old_rdata=%h",addr, rdata, old_rdata);
        `ifndef DBG_ENABLE
            $finish;
        `endif
    end
    else $display("AXI_SLV_PORT 0x%h test 2 PASS: rdata=%h, old_rdata=%h",addr, rdata, old_rdata);
endtask


task mem_scan_test(input logic [31:0] base_addr, input logic [31:0] bank_num, input logic [31:0] step);
    logic [31:0] addr_offset;
    logic [63:0] test_data;
    for (i=0;i<bank_num;i=i+1) begin
        // base
        test_data   = {$urandom, $urandom};
        axi_slv_port_replace_write(base_addr, test_data, 3'b011);
        // middle
        addr_offset = $urandom_range(step/8-1,32'h0000_0000)*8;
        test_data   = {$urandom, $urandom};
        axi_slv_port_replace_write(base_addr+addr_offset, test_data, 3'b011);
        // end
        test_data   = {$urandom, $urandom};
        axi_slv_port_replace_write(base_addr+step-32'h0000_0008, test_data, 3'b011);
        // increase addr
        base_addr = base_addr + step;
    end
endtask


task ext_access;
begin

    logic flag_axi_access_itcm;
    logic flag_axi_access_dtcm;
    logic flag_core_access_ext_mem;

    flag_axi_access_itcm     = 1'b0;
    flag_axi_access_dtcm     = 1'b0;
    flag_core_access_ext_mem = 1'b0;

    `ifdef SOPHON_EXT_ACCESS

        $display($realtime, ": Configure: Set Soft Reset = 0......");
        axi_rand_master.run_write_word(32'h0600_0004, 64'h0000_0000_0000_0000, 8'd0, 3'b010);

        // Inst RAM
        flag_axi_access_itcm = 1'b1;
        $display("\n===================================================");
        $display($realtime, ": TEST: AXI ACCESS ITCM......");
        $display("===================================================");
        // axi_slv_port_replace_write(SOPHON_PKG::ITCM_BASE+32'h0000_0000, 64'h1234_5678_9abc_def0, 3'b011);
        mem_scan_test(SOPHON_PKG::ITCM_BASE, ITCM_BANK_NUM, 32'h0000_1000);
        $display("\n---------------------------------------------------");
        $display($realtime, ": TEST: AXI ACCESS ITCM PASS!");
        flag_axi_access_itcm = 1'b0;

        // Data RAM
        flag_axi_access_dtcm = 1'b1;
        $display("\n===================================================");
        $display($realtime, ": TEST: AXI ACCESS DTCM......");
        $display("===================================================");
        // axi_slv_port_replace_write(SOPHON_PKG::DTCM_BASE+32'h0000_0000, 64'h2435_a845_2345_9864, 3'b011);
        mem_scan_test(SOPHON_PKG::DTCM_BASE, DTCM_BANK_NUM, 32'h0000_1000);
        $display("\n---------------------------------------------------");
        $display($realtime, ": TEST: AXI ACCESS DTCM PASS!");
        flag_axi_access_dtcm = 1'b0;

        // // Out of range
        // axi_rand_master.run_read_single(1,1, 32'h0001_0000);

        // sys reg
        $display("\n===================================================");
        $display($realtime, ": TEST: AXI ACCESS SYS_REG......");
        $display("===================================================");
        axi_slv_port_replace_write(32'h0600_0000, {32'd0, $urandom}, 3'b011);

        $display($realtime, ": Configure: Set Soft Reset = 1......");
        axi_rand_master.run_write_word(32'h0600_0004, 64'h0000_0001_0000_0000, 8'd0, 3'b010);
        flag_core_access_ext_mem = 1'b1;

        // Data RAM & CPU runing
        $display("\n===================================================");
        $display($realtime, ": TEST: AXI ACCESS DTCM (CPU runing)......");
        $display("===================================================");
        mem_scan_test(SOPHON_PKG::DTCM_BASE, DTCM_BANK_NUM, 32'h0000_1000);

        $display($realtime, ": Configure: Set fromhost = 1......");
        if (mem_mode=="EXT") 
            axi_rand_master.run_write_word(32'h0001_1040, 64'h0000_0000_0000_0001, 8'd0, 3'b010);
        else
            axi_rand_master.run_write_word(32'h8009_0040, 64'h0000_0000_0000_0001, 8'd0, 3'b010);
    `endif
    
end
endtask

