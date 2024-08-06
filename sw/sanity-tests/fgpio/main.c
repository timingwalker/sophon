
#include <stdint.h>
#include <common.h>
#include <encoding.h>

uint8_t gpio_input();
void gpio_flip();

uintptr_t handle_trap(uintptr_t cause, uintptr_t epc, uintptr_t regs[32])
{
    // MEI
    if (cause== (1<<31|IRQ_M_EXT) ){
        tohost_exit(0);
    }
    return (epc);
}

int main()
{

	volatile uint8_t gpio_in = 0;

    // enable mie
    asm volatile("csrs mie, %0"::"r"(1<<11));
    asm volatile("csrs mie, %0"::"r"(1<<7 ));
    asm volatile("csrs mie, %0"::"r"(1<<3 ));
    // enable MIE
    asm volatile("csrs mstatus, %0"::"r"(1<<3));

    gpio_in = gpio_input();

    if (gpio_in==1)
	    return gpio_in;

    gpio_flip();

}

uint8_t gpio_input()
{

	volatile uint8_t in_val = 0;
	volatile uint8_t rvalue = 0;

    // IO.in.raw
    asm volatile("li x6, 6 \n");
    asm volatile( ".insn r 0x0b,0,0x0,%0,x0,x6":"=r"(in_val) );
    if (in_val!=2)
        rvalue = 1;

    // IO.in.bit
    asm volatile("li x6, 3 \n");
    asm volatile("li x7, 7 \n");
    asm volatile( ".insn r 0x0b,0,0x1,%0,x6,x7":"=r"(in_val) );
    if (in_val!=0x80)
        rvalue = 1;
    
    return rvalue;
}


void gpio_flip()
{
    asm volatile("and x10, x10, x0 \n");
    asm volatile("ori x10, x12, 255\n");
    asm volatile("li x6, 0x8 \n");

	while (1) 
    {
        asm volatile( ".insn r 0x0b,0,0x40,x0,x10,x6" );
        asm volatile( ".insn r 0x0b,0,0x40,x0,x12,x6" );
        
        asm volatile( ".insn r 0x0b,0,0x40,x0,x10,x6" );
        asm volatile( ".insn r 0x0b,0,0x40,x0,x12,x6" );
        
        asm volatile( ".insn r 0x0b,0,0x40,x0,x10,x6" );
        asm volatile( ".insn r 0x0b,0,0x40,x0,x12,x6" );

    }
}

