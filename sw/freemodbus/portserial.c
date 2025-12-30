/*
 * FreeModbus Libary: BARE Port
 * Copyright (C) 2006 Christian Walter <wolti@sil.at>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * File: $Id$
 */

#include "port.h"

/* ----------------------- Modbus includes ----------------------------------*/
#include "mb.h"
#include "mbport.h"
/* ----------------------- Sophon includes ----------------------------------*/
#include "uart.h"

/* ----------------------- static functions ---------------------------------*/
static void prvvUARTTxReadyISR( void );
static void prvvUARTRxISR( void );

/* ----------------------- Start implementation -----------------------------*/
void
vMBPortSerialEnable( BOOL xRxEnable, BOOL xTxEnable )
{
    /* If xRXEnable enable serial receive interrupts. If xTxENable enable
     * transmitter empty interrupts.
     */

    volatile uint32_t value;
    value = 0;

    if (xRxEnable==TRUE)
        value = value | 1;
    if (xTxEnable==TRUE)
        value = value | 2;

    // set LCR.DALB=0 to config IER
    // writel(_REG32(g_console_port, UART_REG_LCR) & 0x7F , g_console_port + UART_REG_LCR);
    _REG32(g_console_port, UART_REG_IER) = value;

}

BOOL
xMBPortSerialInit( UCHAR ucPORT, ULONG ulBaudRate, UCHAR ucDataBits, eMBParity eParity )
{

    // enabl PLIC interrupt
    _REG32(PLIC_BASE, PLIC_IE_0) = 1<<1;
    _REG32(PLIC_BASE, PLIC_PRIO_0) = 1;

    // enabl RISC-V core interrupt
    // enable mie
    asm volatile("csrs mie, %0"::"r"(1<<11 )); // MTIE
    // enable MIE
    asm volatile("csrs mstatus, %0"::"r"(1<<3));

    // the serialport is inited in CRT
    return TRUE;
}

BOOL
xMBPortSerialPutByte( CHAR ucByte )
{
    /* Put a byte in the UARTs transmit buffer. This function is called
     * by the protocol stack if pxMBFrameCBTransmitterEmpty( ) has been
     * called. */
    uart_putc(g_console_port, ucByte);

    return TRUE;
}

BOOL
xMBPortSerialGetByte( CHAR * pucByte )
{
    /* Return the byte in the UARTs receive buffer. This function is called
     * by the protocol stack after pxMBFrameCBByteReceived( ) has been called.
     */
    *pucByte = uart_getc(g_console_port);

    return TRUE;
}

/* Create an interrupt handler for the transmit buffer empty interrupt
 * (or an equivalent) for your target processor. This function should then
 * call pxMBFrameCBTransmitterEmpty( ) which tells the protocol stack that
 * a new character can be sent. The protocol stack will then call 
 * xMBPortSerialPutByte( ) to send the character.
 */
static void prvvUARTTxReadyISR( void )
{
    pxMBFrameCBTransmitterEmpty(  );
}

/* Create an interrupt handler for the receive interrupt for your target
 * processor. This function should then call pxMBFrameCBByteReceived( ). The
 * protocol stack will then call xMBPortSerialGetByte( ) to retrieve the
 * character.
 */
static void prvvUARTRxISR( void )
{
    pxMBFrameCBByteReceived(  );

}

void EXT_IRQ_Handler(void)
{

    int32_t id  = -1;
    int32_t lsr = -1;
    int32_t iir = -1;

    lsr = readl(g_console_port + UART_REG_LSR);
    iir = readl(g_console_port + UART_REG_IIR);
    id  = readl(PLIC_BASE + PLIC_CLAIM_COMPLET);
#if DEBUG_DETAIL > 0
    printf("lsr=%x iir=%x\n",lsr,iir);
    printf("id=%x\n",id);
#endif

    if ( id==1 ){

        // RX
        if ( (iir&0x0f) == 0x08 ){
            if ( (lsr&0x01) == 0x1 ){
                prvvUARTRxISR(  );
            }
        }

        // TX
        if ( (iir&0x0f) == 0x04 ){
            prvvUARTTxReadyISR();
        }

        _REG32(PLIC_BASE, PLIC_CLAIM_COMPLET) = 1;

    }

}
