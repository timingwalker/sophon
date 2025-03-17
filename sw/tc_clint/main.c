
#include <stdint.h>
#include <common.h>
#include <encoding.h>

extern volatile uint64_t tohost;
volatile uint64_t counter;
volatile uint64_t counter_old;

uintptr_t handle_trap(uintptr_t cause, uintptr_t epc, uintptr_t regs[32])
{
    // MEI
    if (cause== (1<<31|IRQ_M_EXT) ){
        counter = counter + 3;
    }
    // MTI
    else if (cause==(1<<31|IRQ_M_TIMER)){
        counter = counter + 4;
        _REG32(CLINT_BASE, CLINT_MTIMECMP)= 0xffffffff;
    }
    // MSI
    else if (cause==(1<<31|IRQ_M_SOFT)){
        counter = counter + 5;
        _REG32(CLINT_BASE, CLINT_MSIP)= 0x0;
    }
    tohost  = counter;
    return (epc);
}

int main()
{
    volatile uint32_t dummy;
    volatile uint32_t second_trap_entry;

    dummy       = 16;
    counter     = 0;
    counter_old = 0;

    // enable mie
    asm volatile("csrs mie, %0"::"r"(1<<11));
    asm volatile("csrs mie, %0"::"r"(1<<7 ));
    asm volatile("csrs mie, %0"::"r"(1<<3 ));
    // enable MIE
    asm volatile("csrs mstatus, %0"::"r"(1<<3));

    while( tohost!=12 ) {
        if (counter_old != counter){
            counter_old = counter;
            tohost  = counter;
        }
        dummy = dummy * dummy;
    };

	return 0;

}

