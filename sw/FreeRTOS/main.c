
#include <stdint.h>
#include <common.h>
#include <encoding.h>
#include <FreeRTOS.h>
#include "task.h"

extern void freertos_vector_table( void );
extern void freertos_risc_v_trap_handler(void);
extern volatile uint64_t tohost;
volatile uint64_t irq_counter;
TaskHandle_t xHandle_task1;

#define mainVECTOR_MODE_DIRECT	1

uintptr_t handle_trap(uintptr_t cause, uintptr_t epc, uintptr_t regs[32])
{
    // MEI
    if (cause== (1<<31|IRQ_M_EXT) ){
        irq_counter = irq_counter + 3;
    }
    // MTI
    else if (cause==(1<<31|IRQ_M_TIMER)){
        irq_counter = irq_counter + 4;
        _REG32(CLINT_BASE, CLINT_MTIMECMP)= 0xffffffff;
    }
    // MSI
    else if (cause==(1<<31|IRQ_M_SOFT)){
        irq_counter = irq_counter + 5;
        _REG32(CLINT_BASE, CLINT_MSIP)= 0x0;
    }
	
    return (epc);
}

void init_task1(void *pvParameters)
{
    int counter     = 0;

    tohost = 1;

    while (1)
    {
        printf("TASK1....%d\r\n", counter);
        counter++;
		//vTaskDelay(1000);
        if (counter%2==0){
            tohost = 11;
            taskYIELD();
            //vTaskPrioritySet( xHandle_task1, tskIDLE_PRIORITY + 8 );
        }
    }
}

void init_task2(void *pvParameters)
{
    int counter     = 0;
    tohost = 2;

    while (1)
    {
        printf("TASK2....%d\r\n", counter);
        counter++;
		//vTaskDelay(1000);
        if (counter%2==0){
            tohost = 22;
            taskYIELD();
            //vTaskPrioritySet( xHandle_task1, tskIDLE_PRIORITY + 8 );
        }
    }
}

int main()
{

	uint32_t mstatus;
	BaseType_t r;

	printf("-----------------" __DATE__ " " __TIME__ "-----------------\r\n");

	__asm volatile( "csrr %0, mstatus"::"r"(mstatus) );
	printf("mstatus:%x\r\n", mstatus);
	
	#if( mainVECTOR_MODE_DIRECT == 1 )
	{
		__asm__ volatile( "csrw mtvec, %0" :: "r"( freertos_risc_v_trap_handler ) );
	}
	#else
	{
		__asm__ volatile( "csrw mtvec, %0" :: "r"( ( uintptr_t )freertos_vector_table | 0x1 ) );
	}
	#endif

    r = xTaskCreate(init_task1, "T1", configMINIMAL_STACK_SIZE * 2, NULL, tskIDLE_PRIORITY + 6, &xHandle_task1);
	printf("xTaskCreate1:%d\r\n", r);

	r = xTaskCreate(init_task2, "T2", configMINIMAL_STACK_SIZE * 2, NULL, tskIDLE_PRIORITY + 6, NULL);
	printf("xTaskCreate2:%d\r\n", r);

    /* start scheduler */
    vTaskStartScheduler();

    while(1) {
    }

	return 0;

}

void vApplicationGetTimerTaskMemory( StaticTask_t **ppxTimerTaskTCBBuffer, StackType_t **ppxTimerTaskStackBuffer, uint32_t *pulTimerTaskStackSize )
{
/* If the buffers to be provided to the Timer task are declared inside this
function then they must be declared static - otherwise they will be allocated on
the stack and so not exists after this function exits. */
static StaticTask_t xTimerTaskTCB;
static StackType_t uxTimerTaskStack[ configTIMER_TASK_STACK_DEPTH ];

	/* Pass out a pointer to the StaticTask_t structure in which the Timer
	task's state will be stored. */
	*ppxTimerTaskTCBBuffer = &xTimerTaskTCB;

	/* Pass out the array that will be used as the Timer task's stack. */
	*ppxTimerTaskStackBuffer = uxTimerTaskStack;

	/* Pass out the size of the array pointed to by *ppxTimerTaskStackBuffer.
	Note that, as the array is necessarily of type StackType_t,
	configMINIMAL_STACK_SIZE is specified in words, not bytes. */
	*pulTimerTaskStackSize = configTIMER_TASK_STACK_DEPTH;
}

void vApplicationGetIdleTaskMemory( StaticTask_t **ppxIdleTaskTCBBuffer, StackType_t **ppxIdleTaskStackBuffer, uint32_t *pulIdleTaskStackSize )
{
/* If the buffers to be provided to the Idle task are declared inside this
function then they must be declared static - otherwise they will be allocated on
the stack and so not exists after this function exits. */
static StaticTask_t xIdleTaskTCB;
static StackType_t uxIdleTaskStack[ configMINIMAL_STACK_SIZE ];

	/* Pass out a pointer to the StaticTask_t structure in which the Idle task's
	state will be stored. */
	*ppxIdleTaskTCBBuffer = &xIdleTaskTCB;

	/* Pass out the array that will be used as the Idle task's stack. */
	*ppxIdleTaskStackBuffer = uxIdleTaskStack;

	/* Pass out the size of the array pointed to by *ppxIdleTaskStackBuffer.
	Note that, as the array is necessarily of type StackType_t,
	configMINIMAL_STACK_SIZE is specified in words, not bytes. */
	*pulIdleTaskStackSize = configMINIMAL_STACK_SIZE;
}

void vApplicationMallocFailedHook( void )
{
	/* vApplicationMallocFailedHook() will only be called if
	configUSE_MALLOC_FAILED_HOOK is set to 1 in FreeRTOSConfig.h.  It is a hook
	function that will get called if a call to pvPortMalloc() fails.
	pvPortMalloc() is called internally by the kernel whenever a task, queue,
	timer or semaphore is created using the dynamic allocation (as opposed to
	static allocation) option.  It is also called by various parts of the
	demo application.  If heap_1.c, heap_2.c or heap_4.c is being used, then the
	size of the	heap available to pvPortMalloc() is defined by
	configTOTAL_HEAP_SIZE in FreeRTOSConfig.h, and the xPortGetFreeHeapSize()
	API function can be used to query the size of free heap space that remains
	(although it does not provide information on how the remaining heap might be
	fragmented).  See http://www.freertos.org/a00111.html for more
	information. */
	printf( "\r\n\r\nMalloc failed\r\n" );
	portDISABLE_INTERRUPTS();
	for( ;; );
}

void vApplicationStackOverflowHook( TaskHandle_t pxTask, char *pcTaskName )
{
	( void ) pcTaskName;
	( void ) pxTask;

	/* Run time stack overflow checking is performed if
	configCHECK_FOR_STACK_OVERFLOW is defined to 1 or 2.  This hook
	function is called if a stack overflow is detected. */
	printf( "\r\n\r\nStack overflow in %s\r\n", pcTaskName );
	portDISABLE_INTERRUPTS();
	for( ;; );
}

void vApplicationTickHook( void )
{
	//printf("vApplicationTickHook\r\n");
}
