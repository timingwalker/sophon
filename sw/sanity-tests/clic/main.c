
#include <stdint.h>

extern volatile uint64_t tohost;
volatile uint64_t counter;
volatile uint64_t counter_old;

void int16_handle(void)
{
    counter = counter + 1;
}

void __attribute__ ((interrupt)) int17_handle(void)
{
    counter = counter + 5;
}


int main()
{
    volatile uint32_t dummy;
    volatile uint32_t second_trap_entry;

    dummy       = 16;
    counter     = 0;
    counter_old = 0;

    // CLIC mode : bit[1:0]=11
    asm volatile("csrs mtvec, %0"::"r"(3));
    // // mie is replace by clicintie in CLIC controller
    // asm volatile("csrs mie, %0"::"r"(1<<11));
    // enable interrupt
    asm volatile("csrs mstatus, %0"::"r"(1<<3));

    while( tohost!=13 ) {
        if (counter_old != counter){
            counter_old = counter;
            tohost  = counter;
        }
        dummy = dummy * dummy;
    };

    // set mtvec to the second strap_entry using snapreg instruction
    asm volatile("la %0, trap_entry_snapreg":"=r"(second_trap_entry):);
    asm volatile("csrw mtvec, %0"::"r"(second_trap_entry));
    // CLIC mode : bit[1:0]=11
    asm volatile("csrs mtvec, %0"::"r"(3));

    counter = 20;
    tohost  = 20;
    while( counter!=21 ) {
    };

	return 0;

}

