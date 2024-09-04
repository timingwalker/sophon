
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
    $display("clic request is sent\n");

end
endtask


task clic;
begin

    // ------------------------------------------------
    //  non-shv mode
    // ------------------------------------------------
    // sent req when mie=0
    clic_send_request(1'b0, 5'd16, 8'd255);

    // sent req when mie=1
    wait(tohost==1);
    repeat(100)@(posedge clk);
    wait( u_dut.U_SOPHON_AXI_TOP.U_SOPHON_TOP.U_SOPHON.lsu_req_o==1'b0);
    clic_send_request(1'b0, 5'd16, 8'd255);

    // sent req when lsu_req=1
    wait(tohost==2);
    repeat(100)@(posedge clk);
    wait( u_dut.U_SOPHON_AXI_TOP.U_SOPHON_TOP.U_SOPHON.lsu_req_o==1'b1);
    clic_send_request(1'b0, 5'd16, 8'd255);

    // ------------------------------------------------
    //  shv mode
    // ------------------------------------------------
    // sent shv req when lsu_req=0
    wait(tohost==3);
    repeat(100)@(posedge clk);
    wait( u_dut.U_SOPHON_AXI_TOP.U_SOPHON_TOP.U_SOPHON.lsu_req_o==1'b0);
    clic_send_request(1'b1, 5'd17, 8'd255);

    // sent shv req when lsu_req=1
    wait(tohost==8);
    repeat(100)@(posedge clk);
    wait( u_dut.U_SOPHON_AXI_TOP.U_SOPHON_TOP.U_SOPHON.lsu_req_o==1'b1);
    @(posedge clk);
    clic_send_request(1'b1, 5'd17, 8'd255);

    // ------------------------------------------------
    //  snapreg instruction
    // ------------------------------------------------
    wait(tohost==20);
    repeat(100)@(posedge clk);
    clic_send_request(1'b0, 5'd16, 8'd255);


end
endtask
