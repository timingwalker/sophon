
task clic_send_request(input logic shv, input logic [4:0] id, input logic [7:0] level);
begin

    @ (posedge clk);
    #0.1;

    clic_irq_req     = 1'b1;
    clic_irq_shv     = shv;
    clic_irq_id      = id;
    clic_irq_level   = level;
    
    if (shv==0)
        wait(clic_mnxti_clr==1'b1);
    else
        wait(clic_irq_ack==1'b1);

    @ (posedge clk);
    #0.1;
    clic_irq_req     = 1'b0;
    $display(">> clic request is sent\n");

end
endtask


task clic;
begin

    // ------------------------------------------------
    //  non-shv mode
    // ------------------------------------------------
    $display("====== non-shv test1: sent req when mie=0\n");
    clic_send_request(1'b0, 5'd16, 8'd255);
    $display(">> check if tohost=1\n");
    wait(tohost==1);

    $display("====== non-shv test2: sent req when mie=1\n");
    repeat(100)@(posedge clk);
    wait( u_dut.U_SOPHON_AXI_TOP.U_SOPHON_TOP.U_SOPHON.lsu_req_o==1'b0);
    clic_send_request(1'b0, 5'd16, 8'd255);
    $display(">> check if tohost=2\n");
    wait(tohost==2);

    $display("====== non-shv test3: (EXT mode) sent req when lsu_req=1 \n");
    repeat(100)@(posedge clk);
    wait( u_dut.U_SOPHON_AXI_TOP.U_SOPHON_TOP.U_SOPHON.lsu_req_o==1'b1);
    clic_send_request(1'b0, 5'd16, 8'd255);
    $display(">> check if tohost=3\n");
    wait(tohost==3);

    // ------------------------------------------------
    //  shv mode
    // ------------------------------------------------
    $display("====== shv test1: (EXT mode) sent shv req when lsu_req=0\n");
    repeat(100)@(posedge clk);
    wait( u_dut.U_SOPHON_AXI_TOP.U_SOPHON_TOP.U_SOPHON.lsu_req_o==1'b0);
    clic_send_request(1'b1, 5'd17, 8'd255);
    $display(">> check if tohost=8\n");
    wait(tohost==8);

    $display("====== shv test2: (EXT mode) sent shv req when lsu_req=1\n");
    repeat(100)@(posedge clk);
    wait( u_dut.U_SOPHON_AXI_TOP.U_SOPHON_TOP.U_SOPHON.lsu_req_o==1'b1);
    @(posedge clk);
    clic_send_request(1'b1, 5'd17, 8'd255);
    $display(">> check if tohost=20\n");
    wait(tohost==20);

    // ------------------------------------------------
    //  snapreg instruction
    // ------------------------------------------------
    $display("====== snapreg test1: sent noh-shv req\n");
    repeat(100)@(posedge clk);
    clic_send_request(1'b0, 5'd16, 8'd255);
    $display(">> if tohost=21, c-code return 0 and finish this testcase!\n");


end
endtask
