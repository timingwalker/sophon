
#include <stdint.h>


int main()
{

	// volatile uint8_t i = 0;

    gpio_flip();

	return 0;

}

void gpio_flip()
{
    asm volatile("and x10, x10, x0 \n");
    asm volatile("ori x10, x12, 255\n");

	while (1) 
    {
        asm volatile( ".insn r 0x0b,0,0x40,x0,x10,x0" );
        asm volatile( ".insn r 0x0b,0,0x40,x0,x12,x0" );
        
        asm volatile( ".insn r 0x0b,0,0x40,x0,x10,x0" );
        asm volatile( ".insn r 0x0b,0,0x40,x0,x12,x0" );
        
        asm volatile( ".insn r 0x0b,0,0x40,x0,x10,x0" );
        asm volatile( ".insn r 0x0b,0,0x40,x0,x12,x0" );
    }
}

void handle_trap(void)
{

}
