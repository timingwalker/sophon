task clic_no_shv;
begin

    $display("clic no shv is called\n");

    force u_dut.clic_irq_req_i=1'b1;
    force u_dut.clic_irq_shv_i=1'b0;
    force u_dut.clic_irq_id_i=5'd16;
    force u_dut.clic_irq_level_i=8'd255;
    
    wait(u_dut.clic_mnxti_clr_o==1'b1);

    @ (posedge clk);
    #1;
    force u_dut.clic_irq_req_i=1'b0;

end
endtask
