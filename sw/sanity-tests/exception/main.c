
#include <stdint.h>
#include <common.h>
#include <encoding.h>

extern volatile uint64_t tohost;
volatile uint64_t counter;

uintptr_t handle_trap(uintptr_t cause, uintptr_t epc, uintptr_t regs[32])
{
    switch (cause){
        case CAUSE_MISALIGNED_FETCH    : counter = CAUSE_MISALIGNED_FETCH    ; epc=epc+4; break;
        case CAUSE_FETCH_ACCESS        : counter = CAUSE_FETCH_ACCESS        ; epc=epc+4; break;
        case CAUSE_ILLEGAL_INSTRUCTION : counter = CAUSE_ILLEGAL_INSTRUCTION ; epc=epc+4; break;
        case CAUSE_BREAKPOINT          : counter = CAUSE_BREAKPOINT          ; epc=epc+4; break;
        case CAUSE_MISALIGNED_LOAD     : counter = CAUSE_MISALIGNED_LOAD     ; epc=epc+4; break;
        case CAUSE_LOAD_ACCESS         : counter = CAUSE_LOAD_ACCESS         ; epc=epc+4; break;
        case CAUSE_MISALIGNED_STORE    : counter = CAUSE_MISALIGNED_STORE    ; epc=epc+4; break;
        case CAUSE_STORE_ACCESS        : counter = CAUSE_STORE_ACCESS        ; epc=epc+4; break;
        default: break;
    }

    return (epc);
}

int main()
{
    counter     = 0;

    asm volatile("lui t0, 0x80000 \n");
    asm volatile("addi t0, t0,2 \n");
    asm volatile("jalr t0 \n");
    while( counter!=CAUSE_MISALIGNED_FETCH ) {};

    asm volatile("lui t0, 0x90000 \n");
    asm volatile("jalr t0 \n");
    while( counter!=CAUSE_FETCH_ACCESS ) {};

    asm volatile( ".insn r 0x67,1,0x0,x0,x0,x6");
    while( counter!=CAUSE_ILLEGAL_INSTRUCTION ) {};

    asm volatile("ebreak \n");
    while( counter!=CAUSE_BREAKPOINT ) {};

    // in DTCM
    asm volatile("lui t0, 0x80000 \n");
    // outside DTCM
    asm volatile("lui t1, 0x80094 \n");

    asm volatile("lw a5, 2(t1) \n");
    while( counter!=CAUSE_MISALIGNED_LOAD ) {};

    asm volatile("sw a5, 2(t1) \n");
    while( counter!=CAUSE_MISALIGNED_STORE ) {};

    asm volatile("lh a5, 1(t1) \n");
    while( counter!=CAUSE_MISALIGNED_LOAD ) {};

    asm volatile("sh a5, 1(t1) \n");
    while( counter!=CAUSE_MISALIGNED_STORE ) {};

    asm volatile("lw a5, 12(t0) \n");
    while( counter!=CAUSE_LOAD_ACCESS ) {};

    asm volatile("lw a5, 12(t0) \n");
    while( counter!=CAUSE_LOAD_ACCESS ) {};

    asm volatile("sw a5, 12(t0) \n");
    while( counter!=CAUSE_STORE_ACCESS ) {};

	return 0;

}

