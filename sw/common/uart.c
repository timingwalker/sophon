#include "uart.h"
#include "common.h"
#include <stdio.h>


void uart_init()
{
    volatile uint32_t clock;
    volatile uint32_t baudrate;
    volatile uint32_t value;

    clock    = 40000000; // 40M
    baudrate = 115200; 

    // set LCR.DALB=1 to config DLL/DLM
    writel(_REG32(g_console_port, UART_REG_LCR) | 0x80 , g_console_port + UART_REG_LCR);

    // // clock=100M, set baudrate=115200
    // _REG32(g_console_port, UART_REG_DLL) = 868;
    // _REG32(g_console_port, UART_REG_DLM) = 868>>8;
    // // clock=20M, set baudrate=115200
    // _REG32(g_console_port, UART_REG_DLL) = 174;
    // _REG32(g_console_port, UART_REG_DLM) = 174>>8;
    // // clock=25M, set baudrate=115200
    // _REG32(g_console_port, UART_REG_DLL) = 216;
    // _REG32(g_console_port, UART_REG_DLM) = 216>>8;
    // // clock=50M, set baudrate=115200
    // _REG32(g_console_port, UART_REG_DLL) = 434;
    // _REG32(g_console_port, UART_REG_DLM) = 434>>8;
    value = clock / baudrate;
    _REG32(g_console_port, UART_REG_DLL) = value;
    _REG32(g_console_port, UART_REG_DLM) = value>>8;

    // set LCR: 8bit data, 1 bit stop, no parity, DLAB=0
    writel(0xFFFFFF03 , g_console_port + UART_REG_LCR);
}

void uart_putc(void* uartctrl, char c) 
{
    while ((((int) _REG32(uartctrl, UART_REG_LSR)) & 0x20) == 0);    
    //while ((((int) _REG32(uartctrl, UART_REG_LSR)) & 0x40) == 0);
    //_REG32(uartctrl, UART_REG_THR) = c
    writel(c, uartctrl + UART_REG_RBR);
}

void uart_puts(void* uartctrl, const char * s) 
{
    while (*s != '\0')
    {
        uart_putc(uartctrl, *s++);
    }
    //uart_put_hex64(uartctrl, UART_BD);
    //printf("The Baud rate is %d! \n\r",UART_BD);
}

char uart_getc(void* uartctrl)
{
    int32_t val = -1;
    while( (((int) _REG32(uartctrl, UART_REG_LSR)) & 0x01) != 0x1 ) {;}

    //val = (int32_t) _REG32(uartctrl, UART_REG_RBR);
    val = readl(uartctrl + UART_REG_RBR);
    return val & 0xFF;
}              


