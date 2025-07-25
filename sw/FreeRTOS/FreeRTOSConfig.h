/*
 * FreeRTOS V202212.01
 * Copyright (C) 2020 Amazon.com, Inc. or its affiliates.  All Rights Reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * https://www.FreeRTOS.org
 * https://github.com/FreeRTOS
 *
 */

#ifndef FREERTOS_CONFIG_H
#define FREERTOS_CONFIG_H

#if __riscv_xlen == 32
#define REGSIZE		4
#define REGSHIFT	2
#define LOAD		lw
#define STOR		sw
#elif __riscv_xlen == 64
#define REGSIZE		8
#define REGSHIFT	3
#define LOAD		ld
#define STOR		sd
#endif /* __riscv_xlen */

#ifdef __ASSEMBLER__
#define CONS(NUM, TYPE)NUM
#else
#define CONS(NUM, TYPE)NUM##TYPE
#endif /* __ASSEMBLER__ */

#define PRIM_HART			0

#define CLINT_ADDR     0x06005000
#define CLINT_MTIME    0x00
#define CLINT_MTIMECMP 0x04
#define CLINT_MSIP     0x08


#if 0
    #define CLINT_ADDR			CONS(0x02000000, UL)
    #define CLINT_MSIP			CONS(0x0000, UL)
    #define CLINT_MTIMECMP		CONS(0x4000, UL)
    #define CLINT_MTIME			CONS(0xbff8, UL)

    #define NS16550_ADDR		CONS(0x10000000, UL)

    #ifndef __ASSEMBLER__

    int xGetCoreID( void );
    void vSendString( const char * s );
#endif

#endif /* __ASSEMBLER__ */

/*-----------------------------------------------------------
 * Application specific definitions.
 *
 * These definitions should be adjusted for your particular hardware and
 * application requirements.
 *
 * THESE PARAMETERS ARE DESCRIBED WITHIN THE 'CONFIGURATION' SECTION OF THE
 * FreeRTOS API DOCUMENTATION AVAILABLE ON THE FreeRTOS.org WEB SITE.
 *
 * See http://www.freertos.org/a00110.html
 *----------------------------------------------------------*/

/* See https://www.freertos.org/Using-FreeRTOS-on-RISC-V.html */
#define configMTIME_BASE_ADDRESS		( CLINT_ADDR + CLINT_MTIME )
#define configMTIMECMP_BASE_ADDRESS		( CLINT_ADDR + CLINT_MTIMECMP )
#define configISR_STACK_SIZE_WORDS		( 300 )

#define configUSE_PREEMPTION			1
#define configUSE_IDLE_HOOK				0
#define configUSE_TICK_HOOK				1
#define configCPU_CLOCK_HZ				( ( unsigned long ) 40000000 )
#define configTICK_RATE_HZ				( ( TickType_t ) 1000 )
#define configMINIMAL_STACK_SIZE		( ( unsigned short ) 120 )
#define configTOTAL_HEAP_SIZE			( ( size_t ) ( 80 * 1024 ) )
#define configMAX_TASK_NAME_LEN			( 12 )
#define configUSE_TRACE_FACILITY		0
#define configUSE_16_BIT_TICKS			0
#define configIDLE_SHOULD_YIELD			0
#define configUSE_MUTEXES				1
#define configUSE_RECURSIVE_MUTEXES		1
#define configCHECK_FOR_STACK_OVERFLOW	0
// #define configCHECK_FOR_STACK_OVERFLOW	2
#define configUSE_MALLOC_FAILED_HOOK	1
#define configUSE_QUEUE_SETS			1
#define configUSE_COUNTING_SEMAPHORES	1
#define configUSE_PORT_OPTIMISED_TASK_SELECTION 1

#define configMAX_PRIORITIES			( 9UL )
#define configQUEUE_REGISTRY_SIZE		10
#define configSUPPORT_STATIC_ALLOCATION	0

/* Timer related defines. */
#define configUSE_TIMERS				1
#define configTIMER_TASK_PRIORITY		( configMAX_PRIORITIES - 3 )
#define configTIMER_QUEUE_LENGTH		20
#define configTIMER_TASK_STACK_DEPTH	( configMINIMAL_STACK_SIZE * 2 )

#define configUSE_TASK_NOTIFICATIONS	1
#define configTASK_NOTIFICATION_ARRAY_ENTRIES 3

/* Set the following definitions to 1 to include the API function, or zero
to exclude the API function. */

#define INCLUDE_vTaskPrioritySet				1
#define INCLUDE_uxTaskPriorityGet				1
#define INCLUDE_vTaskDelete						1
#define INCLUDE_vTaskCleanUpResources			0
#define INCLUDE_vTaskSuspend					1
#define INCLUDE_vTaskDelayUntil					1
#define INCLUDE_vTaskDelay						1
#define INCLUDE_uxTaskGetStackHighWaterMark		1
#define INCLUDE_xTaskGetSchedulerState			1
#define INCLUDE_xTimerGetTimerDaemonTaskHandle	1
#define INCLUDE_xTaskGetIdleTaskHandle			1
#define INCLUDE_xSemaphoreGetMutexHolder		1
#define INCLUDE_eTaskGetState					1
#define INCLUDE_xTimerPendFunctionCall			1
#define INCLUDE_xTaskAbortDelay					1
#define INCLUDE_xTaskGetCurrentTaskHandle		1
#define INCLUDE_xTaskGetHandle					1

/* This demo makes use of one or more example stats formatting functions.  These
format the raw data provided by the uxTaskGetSystemState() function in to human
readable ASCII form.  See the notes in the implementation of vTaskList() within
FreeRTOS/Source/tasks.c for limitations. */
#define configUSE_STATS_FORMATTING_FUNCTIONS	0

/* The QEMU target is capable of running all the tests tasks at the same
 * time. */
#define configRUN_ADDITIONAL_TESTS				1

//void vAssertCalled( const char *pcFileName, uint32_t ulLine );
#define configASSERT( x ) if( ( x ) == 0 ) { taskDISABLE_INTERRUPTS(); for( ;; ); }	

/* The test that checks the trigger level on stream buffers requires an
allowable margin of error on slower processors (slower than the Win32
machine on which the test is developed). */
#define configSTREAM_BUFFER_TRIGGER_LEVEL_TEST_MARGIN   2

#define intqHIGHER_PRIORITY		( configMAX_PRIORITIES - 5 )
#define bktPRIMARY_PRIORITY		( configMAX_PRIORITIES - 4 )
#define bktSECONDARY_PRIORITY	( configMAX_PRIORITIES - 5 )

#endif /* FREERTOS_CONFIG_H */
