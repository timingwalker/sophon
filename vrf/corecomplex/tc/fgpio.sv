
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

    task fgpio;
    begin
        #1ms;
        repeat(10)@(posedge clk);
        irq_mei = 1'b1;
    end
    endtask


