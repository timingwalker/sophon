#include "uart.h"
#include "common.h"
#include <stdio.h>


void uart_init()
{
    volatile uint32_t clock;
    volatile uint32_t baudrate;
    volatile uint32_t value;

    // set LCR.DALB=1 to config DLL/DLM
    writel(_REG32(g_console_port, UART_REG_LCR) | 0x80 , g_console_port + UART_REG_LCR);

#ifdef __BOOTROM
    // clock=25M, set baudrate=115200
    value = 217;
    // 10M in gaoyun
    //value = 87;
#else
    clock    = 25000000; // 25M
    baudrate = 115200; 
    //baudrate = 460800; 
    value = clock / baudrate;
#endif

    _REG32(g_console_port, UART_REG_DLL) = value;
    _REG32(g_console_port, UART_REG_DLM) = value>>8;

    // set LCR: 8bit data, 1 bit stop, no parity, DLAB=0
    writel(0xFFFFFF03 , g_console_port + UART_REG_LCR);
}

void uart_putc(void* uartctrl, char c) 
{
    while ((((int) _REG32(uartctrl, UART_REG_LSR)) & 0x20) == 0);    
    //while ((((int) _REG32(uartctrl, UART_REG_LSR)) & 0x40) == 0);
    writel(c, uartctrl + UART_REG_RBR);
}

#ifndef __BOOTROM
void uart_puts(void* uartctrl, const char * s) 
{
    while (*s != '\0')
    {
        uart_putc(uartctrl, *s++);
    }
}
#endif

char uart_getc(void* uartctrl)
{
    int32_t val = -1;
    while( (((int) _REG32(uartctrl, UART_REG_LSR)) & 0x01) != 0x1 ) {;}
    val = readl(uartctrl + UART_REG_RBR);
    return val & 0xFF;
}              

#ifndef __BOOTROM
char uart_rd_lsr(void* uartctrl)
{
    int32_t val = -1;
    val = readl(uartctrl + UART_REG_LSR);
    return val ;
}              
#endif


// ----------------------------------------------------------------------
//  emulated UART using fGPIO/snapreg/CLIC 
// ----------------------------------------------------------------------

// TODO:  hw
#define CNT_OVER 217    // 115200 bps  @ 25M 

// ------------------------------------------------
//  RX state machine
// ------------------------------------------------

// check start bit
void __attribute__ ((naked)) int30_handle(void)
{

    SREG_SAVE(0,1,15);

    IO_IN_BIT(10,0,UART_RX);
    asm volatile("bne x10, x0, exit_int30\n");

    asm volatile("li x6, 31 \n");
    asm volatile("li x7, 1 \n");
    VSM_SET_SM(0,6,7);

    asm volatile("exit_int30:" );
    SREG_RECOVER(0,1,15);
    asm volatile( "mret" );

}

void __attribute__ ((naked)) int31_handle(void)
{

    SREG_SAVE(0,1,15);

    // read this bit
    IO_IN_BIT(3,0,UART_RX); 
    asm volatile("slli x3, x3, 7 \n");

    // load ctrl block
    asm volatile("la     x1, sys_uart_rx_ctrl\n"  );
    asm volatile("lbu    x2, 2(x1)\n"     ); // ovf, used as r_data
    // merge to data
    asm volatile("srli   x2, x2, 1 \n");
    asm volatile("or     x3, x3, x2 \n");
    asm volatile("sb     x3, 2(x1)\n"  );
    // add cnt
    asm volatile("lbu    x3, 3(x1)\n"    );
    asm volatile("addi   x3, x3, 1\n"    );
    asm volatile("sb     x3, 3(x1)\n"  );

    // send_cnt >= 8
    asm volatile("li     x2, 8\n"    );
    asm volatile("blt    x3, x2, exit_int31\n"     );
    asm volatile("sb     zero, 3(x1)\n"  ); // cnt=0
    // next state
    asm volatile("li x1, 28 \n");
    asm volatile("li x2, 1 \n");
    VSM_SET_SM(0,1,2);

    asm volatile("exit_int31:"  );
    SREG_RECOVER(0,1,15);
    asm volatile( "mret" );

}

// update rx ring buffer
void __attribute__ ((naked)) int28_handle(void)
{

    SREG_SAVE(0,1,15);

    /* inline push (buf at ctrl+4, no pointer load) --- */
    asm volatile("la    x3, sys_uart_rx_ctrl");
    asm volatile("lbu   x1, 0(x3)");          /* wr */
    asm volatile("lbu   x2, 1(x3)");          /* rd */
    asm volatile("lbu   x5, 2(x3)\n"    );    // data (ovf)
    asm volatile("addi  x4, x1, 1");
    asm volatile("andi  x4, x4, 7");          /* BUF_MASK=7 */
    asm volatile("beq   x4, x2, 1f");         /* full -> overflow */
    
    // asm volatile("slli  x6, x1, 2");          /* wr * 4 */
    asm volatile("add   x6, x3, x1");
    asm volatile("sb    x5, 4(x6)");          /* buf[wr] (+4 folded into immediate) */
    asm volatile("sb    x4, 0(x3)");          /* wr = next */
    asm volatile("j     2f");
    
    asm volatile("1:");                        /* --- overflow: count ovf only --- */
    // TODO: ovf is used as data

    asm volatile("2:");                        /* --- exit --- */
    // next state
    asm volatile("li x1, 30 \n");
    asm volatile("li x2, 1 \n");
    VSM_SET_SM(0,1,2);
    SREG_RECOVER(0,1,15);
    asm volatile( "mret" );

}


// ------------------------------------------------
//  TX state machine
// ------------------------------------------------

// check tx ring buffer
void __attribute__ ((naked)) int21_handle(void)
{

    SREG_SAVE(0,1,15);

    /* --- inline pop (ISR is the TX consumer) --- */
    asm volatile("la    x3, sys_uart_tx_ctrl");
    asm volatile("lbu   x1, 0(x3)");          /* wr (written by main) */
    asm volatile("lbu   x2, 1(x3)");          /* rd (written by ISR) */
    asm volatile("beq   x1, x2, 1f");         /* empty -> disable TX irq */
    
    asm volatile("add   x4, x3, x2");
    asm volatile("lbu   x5, 4(x4)");          /* buf[rd] */
    asm volatile("addi  x2, x2, 1");
    asm volatile("andi  x2, x2, 7");
    asm volatile("sb    x2, 1(x3)");          /* rd = next */
    
    /* --- mv to data(ovf) to be shifted out --- */
    asm volatile("sb    x5, 2(x3)");
    
    // start bit
    asm volatile("li x1, %0" :: "i"(UART_TX));
    IO_OUT_RAW(0,0,1);
    // next state
    asm volatile("li x1, 18 \n");
    VSM_SET_SM(0,1,0);

    asm volatile("1:");           
    SREG_RECOVER(0,1,15);
    asm volatile( "mret" );

}


void __attribute__ ((naked)) int18_handle(void)
{

    SREG_SAVE(0,1,15);

    asm volatile("la     x3, sys_uart_tx_ctrl\n"  );
    asm volatile("lbu    x5, 2(x3)\n"     ); // ovf, used as r_data

    asm volatile("slli x6, x5, %0" :: "i"(UART_TX_SHIFT));
    asm volatile("li x7, %0" :: "i"(UART_TX));
    IO_OUT_RAW(0,6,7); 

    asm volatile("srli   x5, x5, 1\n"    );
    asm volatile("sb     x5, 2(x3)\n"    );

    // read send_cnt
    asm volatile("lbu     x1, 3(x3)\n"    );
    // send_cnt++
    asm volatile("addi   x1, x1, 1\n"    );
    asm volatile("sb     x1, 3(x3)\n"  );
    // check if exit
    asm volatile("li     x2, 8\n"    );
    asm volatile("blt    x1, x2, exit_int18\n"     );
    // send_cnt >= 8
    asm volatile("sb     zero, 3(x3)\n"  );
    // set next state 
    asm volatile("li x1, 19 \n");
    VSM_SET_SM(0,1,0);

    asm volatile("exit_int18:\n");  
    SREG_RECOVER(0,1,15);
    asm volatile( "mret" );
}

void __attribute__ ((naked)) int19_handle(void)
{

    SREG_SAVE(0,1,15);

    // stop bit
    asm volatile("li x5,  0x1 \n");
    asm volatile("slli x6, x5, %0" :: "i"(UART_TX_SHIFT));
    asm volatile("li x7, %0" :: "i"(UART_TX));
    IO_OUT_RAW(0,6,7);

    // set next state 
    asm volatile("li x6, 21 \n");
    VSM_SET_SM(0,6,0);

    SREG_RECOVER(0,1,15);
    asm volatile( "mret" );

}

int tx_push(uint8_t data)
{
    uint8_t wr   = sys_uart_tx_ctrl.wr;
    uint8_t next = (wr + 1) & BUF_MASK;
    
    if (next == sys_uart_tx_ctrl.rd) {   /* full */
        //sys_uart_tx_ctrl.ovf++;          /* dropped: count ovf, not cnt */
        return 0;
    }
    
    sys_uart_tx_buf[wr] = data;          /* byte goes into low 8 bits of the word slot */
    sys_uart_tx_ctrl.wr = next;          /* (2) update pointer (sb) */
    
    return 1;
}

void sys_uart_init(void)
{
    // initial rx_ctrl
    sys_uart_rx_ctrl.wr  = 0;
    sys_uart_rx_ctrl.rd  = 0;
    sys_uart_rx_ctrl.ovf = 0;
    sys_uart_rx_ctrl.cnt = 0;
    // initial tx_ctrl
    sys_uart_tx_ctrl.wr  = 0;
    sys_uart_tx_ctrl.rd  = 0;
    sys_uart_tx_ctrl.ovf = 0;
    sys_uart_tx_ctrl.cnt = 0;

    // initial UART TX to 1
    asm volatile("li x5,  0x1 \n");
    asm volatile("slli x6, x5, %0" :: "i"(UART_TX_SHIFT));
    asm volatile("li x7, %0" :: "i"(UART_TX));
    IO_OUT_RAW(0,6,7);

    // rs1=255 is used to set count over valud of the timer
    asm volatile("li x7, 255 \n");
    asm volatile("li x6, 217 \n");
    VSM_SET_CMP(0,6,7);


}

void sys_uart_enabled(void)
{
    // ------------------------------------------------
    //   set VSM
    // ------------------------------------------------
    // set TX state machine 
    asm volatile("li x7, 0 \n");
    asm volatile("li x6, 21 \n");
    VSM_SET_SM(0,6,7);
    asm volatile("li x6, 217 \n");
    VSM_SET_CMP(0,6,7);
    // set RX state machine
    asm volatile("li x7, 1 \n");
    asm volatile("li x6, 30 \n");
    VSM_SET_SM(0,6,7);
    asm volatile("li x6, 100 \n");
    VSM_SET_CMP(0,6,7);
    // start VSM timer
    VSM_START(0,0,0);
}

void sys_uart_disabled(void)
{
    // stop VSM timer
    VSM_STOP(0,0,0);
}



