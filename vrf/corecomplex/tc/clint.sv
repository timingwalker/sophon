
task clint;
begin

`ifdef CORE_COMPLEX_AXI_SLV
    `ifdef SOPHON_EXT_DATA
        $display("====== clint test2: irq_mti=0\n");
        repeat(100)@(posedge clk);
        axi_rand_master.run_write_word(32'h0600_5004, 64'h0000_0600_0000_0000, 8'd0, 3'b010);
        $display(">> check if tohost=4\n");
        wait(tohost==4);

        $display("====== clint test3: irq_msi=0\n");
        repeat(100)@(posedge clk);
        axi_rand_master.run_write_word(32'h0600_5008, 64'h0000_0000_0000_0001, 8'd0, 3'b010);
        $display(">> check if tohost=9\n");
        wait(tohost==9);
    `else
        $display("====== interface SOPHON_EXT_DATA is not enabled: core can not write clint register.\n");
        $display("====== clint test2: irq_mti test skip!\n");
        $display("====== clint test3: irq_msi test skip!\n");
    `endif
`else
    $display("====== interface CORE_COMPLEX_AXI_SLV is not enabled: mti/msi can not be triggered by testbench\n");
    $display("====== clint test2: irq_mti test skip!\n");
    $display("====== clint test3: irq_msi test skip!\n");
`endif

    $display("====== clint test1: irq_mei=0\n");
    repeat(1000)@(posedge clk);
`ifdef SOPHON_PLIC
    $display("====== clint test1: PLIC is enabled, force irq_mei!\n");
    force u_dut.U_SOPHON_AXI_TOP.irq_mei_i=1;
`else
    irq_mei = 1'b1;
`endif
    $display(">> check if tohost66\n");
    wait(tohost==66);
`ifdef SOPHON_PLIC
    force u_dut.U_SOPHON_AXI_TOP.irq_mei_i=0;
`else
    irq_mei = 1'b0;
`endif


end
endtask
