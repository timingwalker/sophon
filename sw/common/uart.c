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
#else
    clock    = 25000000; // 25M
    baudrate = 115200; 
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


