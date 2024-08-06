
task clint;
begin

    repeat(1000)@(posedge clk);
    irq_mei = 1'b1;
    wait(tohost==3);
    irq_mei = 1'b0;

    repeat(100)@(posedge clk);
    axi_rand_master.run_write_word(32'h0600_5004, 64'h0000_0600_0000_0000, 8'd0, 3'b010);
    wait(tohost==7);

    repeat(100)@(posedge clk);
    axi_rand_master.run_write_word(32'h0600_5008, 64'h0000_0000_0000_0001, 8'd0, 3'b010);
    wait(tohost==12);

end
endtask
