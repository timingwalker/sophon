`ifndef FGPIO_NUM
    `define FGPIO_NUM 24
`endif

module SOPHON_FPGA_TOP (
    input  logic       sys_clk,
    input  logic       sys_rst_n,
    input  logic       uart_rx,
    output logic       uart_tx,
    inout  wire [23:6] gpio,
    output logic [5:0] led
);

    logic core_clk;
    logic pll_lock;
    logic core_rst_n;

    GOWIN_RPLL_10M u_core_pll (
        .clkin  ( sys_clk    ),
        .reset  ( ~sys_rst_n ),
        .clkout ( core_clk   ),
        .lock   ( pll_lock   )
    );

    assign core_rst_n = sys_rst_n & pll_lock;

`ifdef SOPHON_EEI_GPIO
    logic [`FGPIO_NUM-1:0] gpio_dir;
    logic [`FGPIO_NUM-1:0] gpio_in_val;
    logic [`FGPIO_NUM-1:0] gpio_out_val;

    //assign led = ~(gpio_dir[5:0] & gpio_out_val[5:0]);
    assign led[0] = sys_clk;
    assign led[1] = core_clk;
    assign led[3] = pll_lock;
    assign led[4] = core_rst_n;
    assign led[5] = uart_tx;
    assign gpio_in_val[5:0] = gpio_out_val[5:0];

    genvar i;
    generate
        for (i = 6; i < `FGPIO_NUM; i = i + 1) begin : gen_gpio
            assign gpio[i] = gpio_dir[i] ? gpio_out_val[i] : 1'bz;
            assign gpio_in_val[i] = gpio[i];
        end
    endgenerate
`else
    //assign led = 6'b110111;
    assign led[0] = sys_clk;
    assign led[1] = pll_lock;
    assign led[2] = core_rst_n;
    assign led[3] = 1'b1;
    assign led[4] = uart_tx;
    assign led[5] = uart_rx;
    assign gpio = {18{1'bz}};
`endif

    CORE_COMPLEX u_core_complex (
        .clk_i          ( core_clk      ),
        .rst_ni         ( core_rst_n    ),
        .hart_id_i      ( 32'h0000_0000 ),
        .uart_rx_i      ( uart_rx       ),
        .uart_tx_o      ( uart_tx       )
`ifdef SOPHON_EEI_GPIO
       ,
        .gpio_dir_o     ( gpio_dir      ),
        .gpio_in_val_i  ( gpio_in_val   ),
        .gpio_out_val_o ( gpio_out_val  )
`endif
    );

endmodule
