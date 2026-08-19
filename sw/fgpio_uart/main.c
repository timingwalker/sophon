
#include <stdint.h>
#include "common.h"
#include "uart.h"



int main()
{

    // ------------------------------------------------
    //  IRQ
    // ------------------------------------------------
    // enable mie
    asm volatile("csrs mie, %0"::"r"(1<<11));
    asm volatile("csrs mie, %0"::"r"(1<<7 ));
    asm volatile("csrs mie, %0"::"r"(1<<3 ));
    // enable MIE
    asm volatile("csrs mstatus, %0"::"r"(1<<3));
    // set interrupt to CLIC mode : bit[1:0]=11
    asm volatile("csrs mtvec, %0"::"r"(3));


    sys_uart_init();
    sys_uart_enabled();

    // test tx ctrl
    tx_push ('6');
    tx_push ('6');
    tx_push ('6');
    tx_push ('8');
    tx_push ('8');
    tx_push ('8');

    // uart loop: rx -> tx
    while(1)
    {
        uint8_t wr = sys_uart_rx_ctrl.wr;       
        uint8_t rd = sys_uart_rx_ctrl.rd;      

        if ( wr!=rd ) {
            uint8_t data = sys_uart_rx_buf[sys_uart_rx_ctrl.rd];
            sys_uart_rx_ctrl.rd = (sys_uart_rx_ctrl.rd + 1) & BUF_MASK;
            tx_push (data);
        }
    }

	return 0;

}


void handle_trap(void)
{
}
