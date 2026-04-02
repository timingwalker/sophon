
#include <stdint.h>
#include "common.h"

uintptr_t handle_trap(uintptr_t cause, uintptr_t epc, uintptr_t regs[32])
{
    return (epc);
}

int main()
{

    printf("Hello world!\n");

    // hardware infomation
    uint32_t hw_para;
    __asm__ volatile ("csrr %0, 0xCC0" : "=r" (hw_para));

    printf("\nHardware information:\n");

    if ( hw_para & (1<<HWINFO_EXT_INST) )
        printf("EXT_INST: 1\n");
    else
        printf("EXT_INST: 0\n");

    if ( hw_para & (1<<HWINFO_EXT_DATA) )
        printf("EXT_DATA: 1\n");
    else
        printf("EXT_DATA: 0\n");

    if ( hw_para & (1<<HWINFO_EXT_ACCESS) )
        printf("EXT_ACCESS: 1\n");
    else
        printf("EXT_ACCESS: 0\n");

    if ( hw_para & (1<<HWINFO_RVE) )
        printf("RVE: 1\n");
    else
        printf("RVE: 0\n");

    if ( hw_para & (1<<HWINFO_CLINT) )
        printf("CLINT: 1\n");
    else
        printf("CLINT: 0\n");

    if ( hw_para & (1<<HWINFO_CLIC) )
        printf("CLIC: 1\n");
    else
        printf("CLIC: 0\n");

    if ( hw_para & (1<<HWINFO_RVDEBUG) )
        printf("RVDEBUG: 1\n");
    else
        printf("RVDEBUG: 0\n");

    if ( hw_para & (1<<HWINFO_EEI_SREG) )
        printf("EEI_SREG: 1\n");
    else
        printf("EEI_SREG: 0\n");

    if ( hw_para & (1<<HWINFO_EEI_GPIO) )
        printf("EEI_GPIO: 1\n");
    else
        printf("EEI_GPIO: 0\n");

	return 0;
}

