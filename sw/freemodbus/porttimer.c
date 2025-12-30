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

/* ----------------------- Sophon includes ----------------------------------*/
#include <common.h>
/* ----------------------- Platform includes --------------------------------*/
#include "port.h"

/* ----------------------- Modbus includes ----------------------------------*/
#include "mb.h"
#include "mbport.h"

/* ----------------------- static functions ---------------------------------*/
static void prvvTIMERExpiredISR( void );

/* ----------------------- Start implementation -----------------------------*/
BOOL
xMBPortTimersInit( USHORT usTim1Timerout50us )
{
    _REG32(CLINT_BASE, CLINT_MTIMECMP)= usTim1Timerout50us*2000;
    return TRUE;
}


inline void
vMBPortTimersEnable(  )
{
    /* Enable the timer with the timeout passed to xMBPortTimersInit( ) */

    // set timer value
    _REG32(CLINT_BASE, CLINT_MTIME)= 0x00000000;
    // enable mie
     asm volatile("csrs mie, %0"::"r"(1<<7 )); // MTIE
    // enable MIE
    asm volatile("csrs mstatus, %0"::"r"(1<<3));
}

inline void
vMBPortTimersDisable(  )
{
    /* Disable any pending timers. */
    // disable mie
    asm volatile("csrc mie, %0"::"r"(1<<7 )); // MTIE
}

/* Create an ISR which is called whenever the timer has expired. This function
 * must then call pxMBPortCBTimerExpired( ) to notify the protocol stack that
 * the timer has expired.
 */
static void prvvTIMERExpiredISR( void )
{
    ( void )pxMBPortCBTimerExpired(  );
}


void TIM_IRQ_Handler(void)
{
#if DEBUG_DETAIL > 0
    printf("TIM_IRQ\n");
#endif
    prvvTIMERExpiredISR();
}

