
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

char uart_rd_lsr(void* uartctrl);

#endif /* _DRIVERS_UART_H */





#ifndef SYSUART_H
#define SYSUART_H

/* Parameters */
#define UART_RX 0    // gpio 0 => RX pin
#define UART_TX 0x2  // 2 = 2'b10 => gpio 1 => TX pin
#define UART_TX_SHIFT __builtin_ctz(UART_TX)

#define BUF_MASK       7          /* 8-byte buffer*/

/* ============================================================
 *  * Control block structure (4B)
 *  * IRON RULE: wr/rd/ovf/cnt share one 4B word.
 *  *   All updates MUST be single-byte accesses (lbu/sb).
 *  *   No read-modify-write on the whole word, no C bitfields -
 *  *   otherwise lost-update races occur.
 * ============================================================ */
typedef struct {
    volatile uint8_t    wr;    /* +0  RX: written by ISR / TX: written by main */
    volatile uint8_t    rd;    /* +1  RX: written by main / TX: written by ISR */
    volatile uint8_t    ovf;   /* +2  overflow counter */
    volatile uint8_t    cnt;   /* +3  transferred-bit counter (for sim, written by ISR) */
} ring_ctrl_t;                 /* 4B */

/* Linker absolute symbols (defined in *.ld) */
extern volatile ring_ctrl_t sys_uart_rx_ctrl;
extern volatile ring_ctrl_t sys_uart_tx_ctrl;
extern volatile uint8_t     sys_uart_rx_buf[8];
extern volatile uint8_t     sys_uart_tx_buf[8];

int tx_push(uint8_t data);
void sys_uart_init(void);
void sys_uart_enabled(void);
void sys_uart_disabled(void);

#endif

