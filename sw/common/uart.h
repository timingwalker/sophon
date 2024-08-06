
#ifndef _DRIVERS_UART_H
#define _DRIVERS_UART_H
#include <stdint.h>
#include "common.h"


#ifndef g_console_port 
#define g_console_port          (void *)UART0_BASE    //adapt the UART Number
#endif

#define UART_REG_DLL  0x00 // Receiver Buffer Register (Read Only)
#define UART_REG_DLM  0x04 // Interrupt Enable Register

#define UART_REG_RBR  0x00 // Receiver Buffer Register (Read Only)
#define UART_REG_IER  0x04 // Interrupt Enable Register
#define UART_REG_IIR  0x08 // Interrupt Identity Register (Read Only)
#define UART_REG_LCR  0x0c // Line Control Register
#define UART_REG_MCR  0x10 // MODEM Control Register
#define UART_REG_LSR  0x14 // Line Status Register
#define UART_REG_MSR  0x18 // MODEM Status Register
#define UART_REG_SCR  0x1c // Scratch Register


void uart_init();
void uart_putc(void* uartctrl, char c);
char uart_getc(void* uartctrl);
void uart_puts(void* uartctrl, const char * s);


#endif /* _DRIVERS_UART_H */

