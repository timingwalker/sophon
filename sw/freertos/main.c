
#include <stdint.h>
#include <common.h>
#include <encoding.h>

volatile uint64_t counter;

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
    return (epc);
}

int main()
{

    counter     = 0;

    printstr("Hello,world!");

	return 0;

}

