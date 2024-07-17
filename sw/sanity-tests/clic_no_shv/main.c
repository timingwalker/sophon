
#include <stdint.h>


uint32_t counter = 0;
uint32_t flag_irq = 0;

void int16_handle(void)
{
    counter = counter + 1;
    flag_irq = 1;
}


int main()
{

    asm volatile("csrs mtvec, %0"::"r"(3));

    asm volatile("csrs mie, %0"::"r"(1<<11));
    asm volatile("csrs mstatus, %0"::"r"(1<<3));

    while( flag_irq==0 );
	return 0;

}

