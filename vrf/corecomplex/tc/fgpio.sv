
    // GPIO1:DUT TX
    // GPIO0:DUT RX
    // DUT baudrate: 2083333 (25M/12)
    logic fgpio_uart_tx;  
    logic fgpio_uart_rx;  

    uart_bus
    #(
        .BAUD_RATE ( 4166667 ) , // 50M/12
        .PARITY_EN ( 0       ) 
    )
    u_fgpio_uart_bus
    (
        .rx    ( fgpio_uart_rx ) ,
        .tx    ( fgpio_uart_tx ) ,
        .rx_en ( 1'b1          ) 
    );

    assign fgpio_uart_rx  = gpio_dir[1] ? gpio_out_val[1] : 1'b1;
    assign gpio_in_val[0] = gpio_dir[0] ? gpio_out_val[0] : fgpio_uart_tx;


    assign gpio_in_val[1] = 1'b1;
    assign gpio_in_val[2] = 1'b0;
    assign gpio_in_val[3] = 1'b1;
    for ( genvar h = 4; h < `FGPIO_NUM; h = h + 1 ) begin
        assign gpio_in_val[h] = 1'b1;
    end

    task fgpio_uart;
    begin
    
        #0.2ms;
    
        #50us;
        u_fgpio_uart_bus.send_char("h");
        #50us;
        u_fgpio_uart_bus.send_char("e");
        #50us;
        u_fgpio_uart_bus.send_char("l");
        #50us;
        u_fgpio_uart_bus.send_char("l");
        #50us;
        u_fgpio_uart_bus.send_char("o");
        #50us;
        u_fgpio_uart_bus.send_char("!");
        #50us;
        u_fgpio_uart_bus.send_char("<");
        #50us;
        
    end
    endtask

    task fgpio_spi;
    begin
        #0.1ms;
        repeat(10)@(posedge clk);
        // SPI 1
        axi_rand_master.run_write_word(32'h8009_0004, 64'h8009_0100_0000_0000, 8'd0, 3'b010);
        axi_rand_master.run_write_word(32'h8009_0100, 64'h0000_0000_0000_1111, 8'd0, 3'b010);
        axi_rand_master.run_write_word(32'h8009_0000, 64'h0000_0000_0000_0001, 8'd0, 3'b010);
        // SPI 2
        axi_rand_master.run_write_word(32'h8009_000c, 64'h8009_0200_0000_0000, 8'd0, 3'b010);
        axi_rand_master.run_write_word(32'h8009_0200, 64'h0000_0000_0000_2222, 8'd0, 3'b010);
        axi_rand_master.run_write_word(32'h8009_0204, 64'h0000_3333_0000_0000, 8'd0, 3'b010);
        axi_rand_master.run_write_word(32'h8009_0008, 64'h0000_0000_0000_0002, 8'd0, 3'b010);
        // SPI 3
        axi_rand_master.run_write_word(32'h8009_0014, 64'h8009_0300_0000_0000, 8'd0, 3'b010);
        axi_rand_master.run_write_word(32'h8009_0300, 64'h0000_6666_0000_3333, 8'd0, 3'b011);
        axi_rand_master.run_write_word(32'h8009_0308, 64'h0000_9999_0000_8888, 8'd0, 3'b011);
        axi_rand_master.run_write_word(32'h8009_0310, 64'h0000_0000_0000_1111, 8'd0, 3'b010);
        axi_rand_master.run_write_word(32'h8009_0010, 64'h0000_0000_0000_0005, 8'd0, 3'b010);
        // SPI 4
        axi_rand_master.run_write_word(32'h8009_001c, 64'h8009_0400_0000_0000, 8'd0, 3'b010);
        axi_rand_master.run_write_word(32'h8009_0400, 64'h0000_0000_0000_4444, 8'd0, 3'b010);
        axi_rand_master.run_write_word(32'h8009_0018, 64'h0000_0000_0000_0001, 8'd0, 3'b010);
        // SPI 5
        axi_rand_master.run_write_word(32'h8009_0024, 64'h8009_0500_0000_0000, 8'd0, 3'b010);
        axi_rand_master.run_write_word(32'h8009_0500, 64'h0000_0000_0000_5555, 8'd0, 3'b010);
        axi_rand_master.run_write_word(32'h8009_0020, 64'h0000_0000_0000_0001, 8'd0, 3'b010);
        // SPI 6
        axi_rand_master.run_write_word(32'h8009_002c, 64'h8009_0600_0000_0000, 8'd0, 3'b010);
        axi_rand_master.run_write_word(32'h8009_0600, 64'h0000_0000_0000_6666, 8'd0, 3'b010);
        axi_rand_master.run_write_word(32'h8009_0028, 64'h0000_0000_0000_0001, 8'd0, 3'b010);
        // SPI 7
        axi_rand_master.run_write_word(32'h8009_0034, 64'h8009_0700_0000_0000, 8'd0, 3'b010);
        axi_rand_master.run_write_word(32'h8009_0700, 64'h0000_0000_0000_7777, 8'd0, 3'b010);
        axi_rand_master.run_write_word(32'h8009_0030, 64'h0000_0000_0000_0001, 8'd0, 3'b010);
        // SPI 8
        axi_rand_master.run_write_word(32'h8009_003c, 64'h8009_0800_0000_0000, 8'd0, 3'b010);
        axi_rand_master.run_write_word(32'h8009_0800, 64'h0000_0000_0000_8888, 8'd0, 3'b010);
        axi_rand_master.run_write_word(32'h8009_0038, 64'h0000_0000_0000_0001, 8'd0, 3'b010);

        // SPI 6
        axi_rand_master.run_write_word(32'h8009_002c, 64'h8009_0600_0000_0000, 8'd0, 3'b010);
        axi_rand_master.run_write_word(32'h8009_0600, 64'h0000_0000_0000_6868, 8'd0, 3'b010);
        axi_rand_master.run_write_word(32'h8009_0028, 64'h0000_0000_0000_0001, 8'd0, 3'b010);
    end
    endtask

    task fgpio;
    begin
        #1ms;
        repeat(10)@(posedge clk);
        irq_mei = 1'b1;
    end
    endtask


