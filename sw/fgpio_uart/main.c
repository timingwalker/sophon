
#include <stdint.h>

void fgpio_uart_init();
void fgpio_uart_sendchar(char data);
char fgpio_uart_getchar();


int main()
{
    // This case use fGPIO to emulate an UART device
    // Baud = 2.0833 (25M/12)
    // RX   = GPIO 0
    // TX   = GPIO 1

	volatile uint8_t i = 0;
    char tdata;

    fgpio_uart_init();

    char ch[]  = "fGPIO UART loop test:\n";

    while (ch[i] != '\0')
    {
        fgpio_uart_sendchar( ch[i] );
        i++;
    }
    
    // get one char from RX and sent it back to TX
    // until getchar='<'
    while (1)
    {
        tdata = fgpio_uart_getchar();
        if (tdata=='<')
            break;
        fgpio_uart_sendchar( tdata );
    }

    char ch2[] = "\nFinish!";
    i=0;
    while (ch2[i] != '\0')
    {
        fgpio_uart_sendchar( ch2[i] );
        i++;
    }

	return 0;

}


void fgpio_uart_init()
{
    // set TX pin to 1
    asm volatile("li x6,  0x2 \n");
    asm volatile("li x7,  0x2 \n");
    asm volatile( ".insn r 0x0b,0,0x40,x0,x6,x7" );
}


char fgpio_uart_getchar()
{

    char tdata;

    asm volatile("li x10, 0 \n");
    asm volatile("li x6,  0 \n");
    asm volatile("li x7,  0 \n");

    // start bit
    asm volatile("start_bit: .insn r 0x0b,0,0x01,x10,x0,x0" );
    asm volatile("bne x10, x0, start_bit \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");

    // bit0
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile( ".insn r 0x0b,0,0x01,x6,x0,x7" );
    asm volatile("or x10, x10, x6 \n");
    asm volatile("li x7,  1 \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    // bit1
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile( ".insn r 0x0b,0,0x01,x6,x0,x7" );
    asm volatile("or x10, x10, x6 \n");
    asm volatile("li x7,  2 \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    // bit2
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile( ".insn r 0x0b,0,0x01,x6,x0,x7" );
    asm volatile("or x10, x10, x6 \n");
    asm volatile("li x7,  3 \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    // bit3
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile( ".insn r 0x0b,0,0x01,x6,x0,x7" );
    asm volatile("or x10, x10, x6 \n");
    asm volatile("li x7,  4 \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    // bit4
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile( ".insn r 0x0b,0,0x01,x6,x0,x7" );
    asm volatile("or x10, x10, x6 \n");
    asm volatile("li x7,  5 \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    // bit5
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile( ".insn r 0x0b,0,0x01,x6,x0,x7" );
    asm volatile("or x10, x10, x6 \n");
    asm volatile("li x7,  6 \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    // bit6
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile( ".insn r 0x0b,0,0x01,x6,x0,x7" );
    asm volatile("or x10, x10, x6 \n");
    asm volatile("li x7,  7 \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    // bit7
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile( ".insn r 0x0b,0,0x01,x6,x0,x7" );
    asm volatile("or x10, x10, x6 \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");

    // stop bit
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");

    asm volatile("mv %0 ,x10 \n":"=r"(tdata));
    return tdata;
}


void fgpio_uart_sendchar(char data)
{
    // GPIO1
    asm volatile("li x6,  0x2 \n");
    asm volatile("li x7,  0x2 \n");
    asm volatile("slli x10, x10, 1 \n");

    // start
    asm volatile( ".insn r 0x0b,0,0x40,x0,x0,x7" );
    asm volatile( ".insn r 0x0b,0,0x40,x0,x0,x7" );
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    
    // x10=a0
    // bit0
    asm volatile( ".insn r 0x0b,0,0x40,x0,x10,x7" );
    asm volatile("srli x10, x10, 1 \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    // bit1
    asm volatile( ".insn r 0x0b,0,0x40,x0,x10,x7" );
    asm volatile("srli x10, x10, 1 \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    // bit2
    asm volatile( ".insn r 0x0b,0,0x40,x0,x10,x7" );
    asm volatile("srli x10, x10, 1 \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    // bit3
    asm volatile( ".insn r 0x0b,0,0x40,x0,x10,x7" );
    asm volatile("srli x10, x10, 1 \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    // bit4
    asm volatile( ".insn r 0x0b,0,0x40,x0,x10,x7" );
    asm volatile("srli x10, x10, 1 \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    // bit5
    asm volatile( ".insn r 0x0b,0,0x40,x0,x10,x7" );
    asm volatile("srli x10, x10, 1 \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    // bit6
    asm volatile( ".insn r 0x0b,0,0x40,x0,x10,x7" );
    asm volatile("srli x10, x10, 1 \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    // bit7
    asm volatile( ".insn r 0x0b,0,0x40,x0,x10,x7" );
    asm volatile("srli x10, x10, 1 \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    
    // stop
    asm volatile( ".insn r 0x0b,0,0x40,x0,x6,x7" );
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
    asm volatile("nop \n");
}


void handle_trap(void)
{
}
