`ifndef FGPIO_NUM
    `define FGPIO_NUM 24
`endif

module SOPHON_FPGA_TOP (
    input  logic       sys_clk,
    input  logic       sys_rst_n,
    input  logic       uart_rx,
    output logic       uart_tx,
    inout  wire [23:0] gpio,
    output logic [5:0] led
);

    logic core_clk;
    logic pll_lock;
    logic core_rst_n;

    rPLL u_core_pll (
        .CLKOUT   (             ),
        .LOCK     ( pll_lock    ),
        .CLKOUTP  (             ),
        .CLKOUTD  ( core_clk    ),
        .CLKOUTD3 (             ),
        .RESET    ( ~sys_rst_n  ),
        .RESET_P  ( 1'b0        ),
        .CLKIN    ( sys_clk     ),
        .CLKFB    ( 1'b0        ),
        .FBDSEL   ( 6'b0        ),
        .IDSEL    ( 6'b0        ),
        .ODSEL    ( 6'b0        ),
        .PSDA     ( 4'b0        ),
        .DUTYDA   ( 4'b0        ),
        .FDLY     ( 4'b0        )
    );
    // 10MHz
    defparam u_core_pll.FCLKIN = "27";
    defparam u_core_pll.DYN_IDIV_SEL = "false";
    defparam u_core_pll.IDIV_SEL = 2;
    defparam u_core_pll.DYN_FBDIV_SEL = "false";
    defparam u_core_pll.FBDIV_SEL = 19;
    defparam u_core_pll.DYN_ODIV_SEL = "false";
    defparam u_core_pll.ODIV_SEL = 4;
    defparam u_core_pll.PSDA_SEL = "0000";
    defparam u_core_pll.DYN_DA_EN = "false";
    defparam u_core_pll.DUTYDA_SEL = "1000";
    defparam u_core_pll.CLKOUT_FT_DIR = 1'b1;
    defparam u_core_pll.CLKOUTP_FT_DIR = 1'b1;
    defparam u_core_pll.CLKOUT_DLY_STEP = 0;
    defparam u_core_pll.CLKOUTP_DLY_STEP = 0;
    defparam u_core_pll.CLKFB_SEL = "internal";
    defparam u_core_pll.CLKOUT_BYPASS = "false";
    defparam u_core_pll.CLKOUTP_BYPASS = "false";
    defparam u_core_pll.CLKOUTD_BYPASS = "false";
    defparam u_core_pll.DYN_SDIV_SEL = 18;
    defparam u_core_pll.CLKOUTD_SRC = "CLKOUT";
    defparam u_core_pll.CLKOUTD3_SRC = "CLKOUT";
    defparam u_core_pll.DEVICE = "GW1NR-9C";

    RST_SYNC u_rst_sync (
        .clk_i       ( core_clk    ),
        .rst_ni      ( pll_lock    ),
        .rstn_sync_o ( core_rst_n  )
    );

`ifdef SOPHON_EEI_GPIO
    logic [`FGPIO_NUM-1:0] gpio_dir;
    logic [`FGPIO_NUM-1:0] gpio_in_val;
    logic [`FGPIO_NUM-1:0] gpio_out_val;

    //assign led = ~(gpio_dir[5:0] & gpio_out_val[5:0]);
    assign led[0] = sys_clk;
    assign led[1] = core_clk;
    assign led[2] = 1'b1;
    assign led[3] = pll_lock;
    assign led[4] = core_rst_n;
    assign led[5] = uart_tx;

    genvar i;
    generate
        for (i = 0; i < `FGPIO_NUM; i = i + 1) begin : gen_gpio
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
    assign gpio = {24{1'bz}};
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
