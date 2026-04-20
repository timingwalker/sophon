
#include <stdint.h>
#include "common.h"

char fgpio_spi_single_itf_AG( char sent_data );
char fgpio_spi_single_itf_M( char sent_data );
char fgpio_spi_single_itf_ALT( char sent_data );
char fgpio_spi_single_itf_PmodD_AG( char sent_data );
char fgpio_spi_single_itf_PmodD_M( char sent_data );
char fgpio_spi_single_itf_PmodD_ALT( char sent_data );

int main()
{

	volatile uint8_t i = 0;
	volatile char MISO = 0;

    // ------------------------------------------------
    // single interface test
    // ------------------------------------------------

    int rdata;

    printf("Test Pmod A:\n");
    // ----------------------------------------------------------------------
    printf("Test AG:\n");
    printf("R 0F: ");
    rdata = fgpio_spi_single_itf_AG( 0x8F );
    printf("%x \n", rdata);

    printf("R 0B :");
    rdata = fgpio_spi_single_itf_AG( 0x8B );
    printf("%x \n", rdata);

    printf("R 0F: ");
    rdata = fgpio_spi_single_itf_AG( 0x8F );
    printf("%x \n", rdata);


    // ----------------------------------------------------------------------
    printf("Test M:\n");
    printf("R 0F: ");
    rdata = fgpio_spi_single_itf_M( 0x8F );
    printf("%x \n", rdata);

    printf("R 0B :");
    rdata = fgpio_spi_single_itf_M( 0x8B );
    printf("%x \n", rdata);

    printf("R 0F: ");
    rdata = fgpio_spi_single_itf_M( 0x8F );
    printf("%x \n", rdata);

    // ----------------------------------------------------------------------
    printf("Test ALT:\n");
    printf("R 0F: ");
    rdata = fgpio_spi_single_itf_ALT( 0x8F );
    printf("%x \n", rdata);

    printf("R 0B :");
    rdata = fgpio_spi_single_itf_ALT( 0x8B );
    printf("%x \n", rdata);

    printf("R 0F: ");
    rdata = fgpio_spi_single_itf_ALT( 0x8F );
    printf("%x \n", rdata);

    // ----------------------------------------------------------------------
    printf("\nTest Pmod D:\n");
    
    printf("R 0F: ");
    rdata = fgpio_spi_single_itf_PmodD_AG( 0x8F );
    printf("%x \n", rdata);

    printf("R 0F: ");
    rdata = fgpio_spi_single_itf_PmodD_M( 0x8F );
    printf("%x \n", rdata);

    printf("R 0F: ");
    rdata = fgpio_spi_single_itf_PmodD_ALT( 0x8F );
    printf("%x \n", rdata);


    while (1)
    {
    }

}


// emulate a single spi interface to test peak performance
char fgpio_spi_single_itf_AG( char sent_data )
{

    // save ra,sp
    asm volatile("add x12, x1, x0\n");
    asm volatile("add x13, x2, x0\n");

    // ------------------------------------------------
    //  Initial
    // ------------------------------------------------
    // set clock
    asm volatile("li x14,  22 \n");
    asm volatile("li x15,  0x6 \n");
    asm volatile( io_cfg_reg(x0,x14,x15) ); 
    // data channal: x2
    asm volatile("slli x2, x10, 8\n"); 
    
    // idle: set cs/clk=1
    asm volatile("li x14,  0x3D \n");
    asm volatile("li x15,  0x3D \n");
    asm volatile( io_out_raw(x0,x14,x15) );

    //asm volatile("li x15,  0x9 \n");
    asm volatile("li x15,  0x29 \n");

    // ------------------------------------------------
    // transmit
    // ------------------------------------------------
    
    // set cs=0
   
    asm volatile("li x14,  0x21 \n");
    //asm volatile("li x14,  0x09 \n");
    asm volatile( io_out_raw(x0,x14,x15) );

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 



    // read back
    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    // set cs=1
    asm volatile( "nop \n" );
    asm volatile( io_out_raw(x0,x15,x15) );

    // return value
    asm volatile("srli x10, x2, 16\n");

    // restore ra,sp
    asm volatile("add x1, x12, x0\n");
    asm volatile("add x2, x13, x0\n");

}



// emulate a single spi interface to test peak performance
char fgpio_spi_single_itf_M( char sent_data )
{

    // save ra,sp
    asm volatile("add x12, x1, x0\n");
    asm volatile("add x13, x2, x0\n");

    // ------------------------------------------------
    //  Initial
    // ------------------------------------------------
    // set clock
    asm volatile("li x14,  22 \n");
    asm volatile("li x15,  0x6 \n");
    asm volatile( io_cfg_reg(x0,x14,x15) ); 
    // data channal: x2
    asm volatile("slli x2, x10, 8\n"); 
    
    // idle: set cs/clk=1
    asm volatile("li x14,  0x3D \n");
    asm volatile("li x15,  0x3D \n");
    asm volatile( io_out_raw(x0,x14,x15) );

    //asm volatile("li x15,  0x9 \n");
    asm volatile("li x15,  0x29 \n");

    // ------------------------------------------------
    // transmit
    // ------------------------------------------------
    
    // set cs=0
   
    //asm volatile("li x14,  0x1 \n");
    asm volatile("li x14,  0x09 \n");
    asm volatile( io_out_raw(x0,x14,x15) );

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 



    // read back
    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    // set cs=1
    asm volatile( "nop \n" );
    asm volatile( io_out_raw(x0,x15,x15) );

    // return value
    asm volatile("srli x10, x2, 16\n");

    // restore ra,sp
    asm volatile("add x1, x12, x0\n");
    asm volatile("add x2, x13, x0\n");

}


// emulate a single spi interface to test peak performance
char fgpio_spi_single_itf_ALT( char sent_data )
{

    // save ra,sp
    asm volatile("add x12, x1, x0\n");
    asm volatile("add x13, x2, x0\n");

    // ------------------------------------------------
    //  Initial
    // ------------------------------------------------
    // set clock
    asm volatile("li x14,  22 \n");
    asm volatile("li x15,  0x6 \n");
    asm volatile( io_cfg_reg(x0,x14,x15) ); 
    // data channal: x2
    asm volatile("slli x2, x10, 8\n"); 
    
    // idle: set cs/clk=1
    asm volatile("li x14,  0x3D \n");
    asm volatile("li x15,  0x3D \n");
    asm volatile( io_out_raw(x0,x14,x15) );

    //asm volatile("li x15,  0x9 \n");
    asm volatile("li x15,  0x19 \n");

    // ------------------------------------------------
    // transmit
    // ------------------------------------------------
    
    // set cs=0
   
    //asm volatile("li x14,  0x1 \n");
    asm volatile("li x14,  0x09 \n");
    asm volatile( io_out_raw(x0,x14,x15) );

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 



    // read back
    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0b0100\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0b0010\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    // set cs=1
    asm volatile( "nop \n" );
    asm volatile( io_out_raw(x0,x15,x15) );

    // return value
    asm volatile("srli x10, x2, 16\n");

    // restore ra,sp
    asm volatile("add x1, x12, x0\n");
    asm volatile("add x2, x13, x0\n");

}


// emulate a single spi interface to test peak performance
// GPIO 8 - 11
char fgpio_spi_single_itf_PmodD_AG( char sent_data )
{

    // save ra,sp
    asm volatile("add x12, x1, x0\n");
    asm volatile("add x13, x2, x0\n");

    // ------------------------------------------------
    //  Initial
    // ------------------------------------------------
    // set clock
    asm volatile("li x14,  22 \n");
    asm volatile("li x15,  0x600 \n");
    asm volatile( io_cfg_reg(x0,x14,x15) ); 
    // data channal: x4
    asm volatile("slli x4, x10, 8\n"); 
    
    // idle: set cs/clk=1
    asm volatile("li x14,  0x3D00 \n");
    asm volatile("li x15,  0x3D00 \n");
    asm volatile( io_out_raw(x0,x14,x15) );

    //asm volatile("li x15,  0x9 \n");
    asm volatile("li x15,  0x1900 \n");

    // ------------------------------------------------
    // transmit
    // ------------------------------------------------
    
    // set cs=0
   
    //asm volatile("li x14,  0x1 \n");
    asm volatile("li x14,  0x1100 \n");
    asm volatile( io_out_raw(x0,x14,x15) );

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    // read back
    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 
    
    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 
    
    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 
    
    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 
    
    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    // set cs=1
    asm volatile( "nop \n" );
    asm volatile( io_out_raw(x0,x15,x15) );

    // return value
    asm volatile("srli x10, x4, 16\n");

    // restore ra,sp
    asm volatile("add x1, x12, x0\n");
    asm volatile("add x2, x13, x0\n");

}


// emulate a single spi interface to test peak performance
// GPIO 8 - 11
char fgpio_spi_single_itf_PmodD_M( char sent_data )
{

    // save ra,sp
    asm volatile("add x12, x1, x0\n");
    asm volatile("add x13, x2, x0\n");

    // ------------------------------------------------
    //  Initial
    // ------------------------------------------------
    // set clock
    asm volatile("li x14,  22 \n");
    asm volatile("li x15,  0x600 \n");
    asm volatile( io_cfg_reg(x0,x14,x15) ); 
    // data channal: x4
    asm volatile("slli x4, x10, 8\n"); 
    
    // idle: set cs/clk=1
    asm volatile("li x14,  0x3D00 \n");
    asm volatile("li x15,  0x3D00 \n");
    asm volatile( io_out_raw(x0,x14,x15) );

    //asm volatile("li x15,  0x9 \n");
    asm volatile("li x15,  0x2900 \n");

    // ------------------------------------------------
    // transmit
    // ------------------------------------------------
    
    // set cs=0
   
    //asm volatile("li x14,  0x1 \n");
    asm volatile("li x14,  0x0900 \n");
    asm volatile( io_out_raw(x0,x14,x15) );

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    // read back
    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 
    
    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 
    
    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 
    
    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 
    
    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    // set cs=1
    asm volatile( "nop \n" );
    asm volatile( io_out_raw(x0,x15,x15) );

    // return value
    asm volatile("srli x10, x4, 16\n");

    // restore ra,sp
    asm volatile("add x1, x12, x0\n");
    asm volatile("add x2, x13, x0\n");

}

// emulate a single spi interface to test peak performance
// GPIO 8 - 11
char fgpio_spi_single_itf_PmodD_ALT( char sent_data )
{

    // save ra,sp
    asm volatile("add x12, x1, x0\n");
    asm volatile("add x13, x2, x0\n");

    // ------------------------------------------------
    //  Initial
    // ------------------------------------------------
    // set clock
    asm volatile("li x14,  22 \n");
    asm volatile("li x15,  0x600 \n");
    asm volatile( io_cfg_reg(x0,x14,x15) ); 
    // data channal: x4
    asm volatile("slli x4, x10, 8\n"); 
    
    // idle: set cs/clk=1
    asm volatile("li x14,  0x3D00 \n");
    asm volatile("li x15,  0x3D00 \n");
    asm volatile( io_out_raw(x0,x14,x15) );

    //asm volatile("li x15,  0x9 \n");
    asm volatile("li x15,  0x1900 \n");

    // ------------------------------------------------
    // transmit
    // ------------------------------------------------
    
    // set cs=0
   
    //asm volatile("li x14,  0x1 \n");
    asm volatile("li x14,  0x0900 \n");
    asm volatile( io_out_raw(x0,x14,x15) );

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    // read back
    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 
    
    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 
    
    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 
    
    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 
    
    asm volatile("li x1,0x400\n");     
    asm volatile( io_out_batch(x0,x0,x0) ); 
    asm volatile("li x1,0x200\n");     
    asm volatile( io_in_batch(x0,x0,x0) ); 

    // set cs=1
    asm volatile( "nop \n" );
    asm volatile( io_out_raw(x0,x15,x15) );

    // return value
    asm volatile("srli x10, x4, 16\n");

    // restore ra,sp
    asm volatile("add x1, x12, x0\n");
    asm volatile("add x2, x13, x0\n");

}

void handle_trap(void)
{
}
