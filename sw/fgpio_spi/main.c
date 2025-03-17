
#include <stdint.h>
#include "common.h"

char fgpio_spi_multi_itf_dma();
char fgpio_spi_single_itf( char sent_data );

#define PERF_PARALLEL

int main()
{

	volatile uint8_t i = 0;
	volatile char MISO = 0;

    // ------------------------------------------------
    // single interface test
    // ------------------------------------------------
#ifdef PERF_PEAK
    char ch[]  = "fGPIO SPI test!  ";
    while(1)
    {
        i=0;
        while (ch[i] != '\0')
        {
            fgpio_spi_single_itf( ch[i] );
            i++;
        }
    }
    // // loopback 
    // while (1)
    // {
    //     MISO = fgpio_spi_single_itf('!');
    //     fgpio_spi_single_itf( MISO );
    // }
#endif

    // ------------------------------------------------
    //  Multiple interfaces test
    // ------------------------------------------------
#ifdef PERF_PARALLEL
    
    char sentbuf_1[]  = "SPI1:Hello";
    char sentbuf_2[]  = "SPI2:";
    char sentbuf_3[]  = "SPI3:,";
    char sentbuf_4[]  = "SPI4:";
    char sentbuf_5[]  = "SPI5:world";
    char sentbuf_6[]  = "SPI6:";
    char sentbuf_7[]  = "SPI7:!";
    char sentbuf_8[]  = "SPI8:";

    // SPI1
    asm volatile("li x7, 10\n");   
    asm volatile("li x8, 0x80090000\n");   
    asm volatile("sw x7,0(x8)\n");   
    asm volatile("li x7, 0x80090100\n");   
    asm volatile("sw x7,4(x8)\n");   
    for (i=0;i<10;i++)
        _REG32(0x80090100,i*4) = sentbuf_1[i]<<8;
    // SPI2
    asm volatile("li x7, 5\n");   
    asm volatile("li x8, 0x80090008\n");   
    asm volatile("sw x7,0(x8)\n");   
    asm volatile("li x7, 0x80090200\n");   
    asm volatile("sw x7,4(x8)\n");   
    for (i=0;i<5;i++)
        _REG32(0x80090200,i*4) = sentbuf_2[i]<<8;
    // SPI3
    asm volatile("li x7, 6\n");   
    asm volatile("li x8, 0x80090010\n");   
    asm volatile("sw x7,0(x8)\n");   
    asm volatile("li x7, 0x80090300\n");   
    asm volatile("sw x7,4(x8)\n");   
    for (i=0;i<6;i++)
        _REG32(0x80090300,i*4) = sentbuf_3[i]<<8;
    // SPI4
    asm volatile("li x7, 5\n");   
    asm volatile("li x8, 0x80090018\n");   
    asm volatile("sw x7,0(x8)\n");   
    asm volatile("li x7, 0x80090400\n");   
    asm volatile("sw x7,4(x8)\n");   
    for (i=0;i<5;i++)
        _REG32(0x80090400,i*4) = sentbuf_4[i]<<8;
    // SPI5
    asm volatile("li x7, 10\n");   
    asm volatile("li x8, 0x80090020\n");   
    asm volatile("sw x7,0(x8)\n");   
    asm volatile("li x7, 0x80090500\n");   
    asm volatile("sw x7,4(x8)\n");   
    for (i=0;i<10;i++)
        _REG32(0x80090500,i*4) = sentbuf_5[i];
    // SPI6
    asm volatile("li x7, 5\n");   
    asm volatile("li x8, 0x80090028\n");   
    asm volatile("sw x7,0(x8)\n");   
    asm volatile("li x7, 0x80090600\n");   
    asm volatile("sw x7,4(x8)\n");   
    for (i=0;i<5;i++)
        _REG32(0x80090600,i*4) = sentbuf_6[i]<<8;
    // SPI7
    asm volatile("li x7, 6\n");   
    asm volatile("li x8, 0x80090030\n");   
    asm volatile("sw x7,0(x8)\n");   
    asm volatile("li x7, 0x80090700\n");   
    asm volatile("sw x7,4(x8)\n");   
    for (i=0;i<6;i++)
        _REG32(0x80090700,i*4) = sentbuf_7[i]<<8;
    // SPI8
    asm volatile("li x7, 5\n");   
    asm volatile("li x8, 0x80090038\n");   
    asm volatile("sw x7,0(x8)\n");   
    asm volatile("li x7, 0x80090800\n");   
    asm volatile("sw x7,4(x8)\n");   
    for (i=0;i<5;i++)
        _REG32(0x80090800,i*4) = sentbuf_8[i]<<8;

    while (1)
    {
        fgpio_spi_multi_itf_dma();
    }
#endif

}


// emulate a single spi interface to test peak performance
char fgpio_spi_single_itf( char sent_data )
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
    // // DMA addr
    // asm volatile("li x13, 0x80090000\n"); 
    
    // idle: set cs/clk=1
    asm volatile("li x14,  0x9 \n");
    asm volatile("li x15,  0x9 \n");
    asm volatile( io_out_raw(x0,x14,x15) );

    // ------------------------------------------------
    // transmit
    // ------------------------------------------------
    
    // set cs=0
    asm volatile("li x14,  0x1 \n");
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

    // set cs=1
    asm volatile( "nop \n" );
    asm volatile( io_out_raw(x0,x15,x15) );

    // return value
    asm volatile("srli x10, x2, 16\n");

    // restore ra,sp
    asm volatile("add x1, x12, x0\n");
    asm volatile("add x2, x13, x0\n");

}


char fgpio_spi_multi_itf_dma()
{

    // ------------------------------------------------
    //  Initial
    // ------------------------------------------------
    // set clock
    asm volatile("li x14,  22 \n");
    asm volatile("li x15,  0x66666666 \n");
    asm volatile( io_cfg_reg(x0,x14,x15) ); 
    // set counter 1
    asm volatile("li x14,  0 \n");
    asm volatile("li x15,  0b010000100010 \n");
    asm volatile( io_cfg_reg(x0,x14,x15) ); 
    // set counter 2
    asm volatile("li x14,  1 \n");
    asm volatile("li x15,  0b100001000010 \n");
    asm volatile( io_cfg_reg(x0,x14,x15) ); 
    // set counter 3
    asm volatile("li x14,  2 \n");
    asm volatile("li x15,  0b100000100010 \n");
    asm volatile( io_cfg_reg(x0,x14,x15) ); 
    // set counter 4
    asm volatile("li x14,  3 \n");
    asm volatile("li x15,  0b010000100010 \n");
    asm volatile( io_cfg_reg(x0,x14,x15) ); 
    // set counter 5
    asm volatile("li x14,  4 \n");
    asm volatile("li x15,  0b100001000010 \n");
    asm volatile( io_cfg_reg(x0,x14,x15) ); 
    // set counter 6
    asm volatile("li x14,  5 \n");
    asm volatile("li x15,  0b010000100010 \n");
    asm volatile( io_cfg_reg(x0,x14,x15) ); 
    // set counter 7
    asm volatile("li x14,  6 \n");
    asm volatile("li x15,  0b010000100010 \n");
    asm volatile( io_cfg_reg(x0,x14,x15) ); 
    // set counter 8
    asm volatile("li x14,  7 \n");
    asm volatile("li x15,  0b100001000010 \n");
    asm volatile( io_cfg_reg(x0,x14,x15) ); 
    // data channal: x2-x9
    // asm volatile("li x2,   0x0 \n"); 
    // asm volatile("li x3,   0x0 \n"); 
    // asm volatile("li x4,   0x0 \n"); 
    // asm volatile("li x5,   0x0 \n"); 
    // asm volatile("li x6,   0x0 \n"); 
    // asm volatile("li x7,   0x0 \n"); 
    // asm volatile("li x8,   0x0 \n"); 
    // asm volatile("li x9,   0x0 \n"); 
    // mask: all CS
    asm volatile("li x10, 0x88888888 \n"); //CS mask
    asm volatile("li x11, 0x88888888 \n"); //CS value
    // addr
    asm volatile("li x12, 20\n"); //REG_CMP
    // DMA addr
    asm volatile("li x13, 0x80090000\n"); 
    // idle: set cs/clk=1
    asm volatile("li x14,  0x99999999 \n");
    asm volatile("li x15,  0x99999999 \n");
    asm volatile( io_out_raw(x0,x14,x15) );

    // ------------------------------------------------
    // transmit
    // ------------------------------------------------
    asm volatile("bit_loop:");   
        // 1. common
    asm volatile("set_cs:\n");   
        asm volatile( io_cfg_reg(x1,x12,x0) );  
        asm volatile("slli x11,x1,1\n");  
        asm volatile("xor x11,x11,x10\n");  
        asm volatile( io_out_raw(x0,x11,x10) );     // set CS
        // 2. spi output:
    asm volatile("spi_out:\n");  
        asm volatile( io_out_batch(x0,x0,x0) ); 
        asm volatile("nop \n");   
        asm volatile("nop \n");   
        asm volatile("nop \n");   
        asm volatile("srli x1,x1,1\n");             // set DI mask
        asm volatile("beq x11,x10,dma\n");   
        // 3. spi input:
        asm volatile( io_in_batch(x0,x0,x0) ); 
        asm volatile("beqz x0, bit_loop\n");   
        // 4. dma
    asm volatile("dma:");
        // SPI1
        asm volatile("spi1_dma:lb x15,0(x13)\n");
        asm volatile("blt x0, x15, spi1_load_data\n"); 
        asm volatile("beqz x0, spi2_dma\n");   
        asm volatile("spi1_load_data:\n");  
        asm volatile("lw x14,4(x13)\n"); // x15: data addr
        asm volatile("lw x2,0(x14)\n");   
        asm volatile("addi x14,x14, 4\n");  
        asm volatile("sw x14,4(x13)\n");   
        asm volatile("addi x15,x15, -1\n");  
        asm volatile("sw x15,0(x13)\n");   
        asm volatile("li x14,  0 \n");
        asm volatile("li x15,  0b000000100010 \n");
        asm volatile( io_cfg_reg(x0,x14,x15) ); 
        // SPI2
        asm volatile("spi2_dma:lb x15,8(x13)\n");
        asm volatile("blt x0, x15, spi2_load_data\n"); 
        asm volatile("beqz x0, spi3_dma\n");   
        asm volatile("spi2_load_data:\n");  
        asm volatile("lw x14,12(x13)\n"); // x15: data addr
        asm volatile("lw x3,0(x14)\n");   
        asm volatile("addi x14,x14, 4\n");  
        asm volatile("sw x14,12(x13)\n");   
        asm volatile("addi x15,x15, -1\n");  
        asm volatile("sw x15,8(x13)\n");   
        asm volatile("li x14,  1 \n");
        asm volatile("li x15,  0b000001000010 \n");
        asm volatile( io_cfg_reg(x0,x14,x15) ); 
        // SPI3
        asm volatile("spi3_dma:lb x15,16(x13)\n");
        asm volatile("blt x0, x15, spi3_load_data\n"); 
        asm volatile("beqz x0, spi4_dma\n");   
        asm volatile("spi3_load_data:\n");  
        asm volatile("lw x14,20(x13)\n"); // x15: data addr
        asm volatile("lw x4,0(x14)\n");   
        asm volatile("addi x14,x14, 4\n");  
        asm volatile("sw x14,20(x13)\n");   
        asm volatile("addi x15,x15, -1\n");  
        asm volatile("sw x15,16(x13)\n");   
        asm volatile("li x14,  2 \n");
        asm volatile("li x15,  0b000000100010 \n");
        asm volatile( io_cfg_reg(x0,x14,x15) ); 
        // SPI4
        asm volatile("spi4_dma:lb x15,24(x13)\n");
        asm volatile("blt x0, x15, spi4_load_data\n"); 
        asm volatile("beqz x0, spi5_dma\n");   
        asm volatile("spi4_load_data:\n");  
        asm volatile("lw x14,28(x13)\n"); // x15: data addr
        asm volatile("lw x5,0(x14)\n");   
        asm volatile("addi x14,x14, 4\n");  
        asm volatile("sw x14,28(x13)\n");   
        asm volatile("addi x15,x15, -1\n");  
        asm volatile("sw x15,24(x13)\n");   
        asm volatile("li x14,  3 \n");
        asm volatile("li x15,  0b000000100010 \n");
        asm volatile( io_cfg_reg(x0,x14,x15) ); 
        // SPI5
        asm volatile("spi5_dma:lb x15,32(x13)\n");
        asm volatile("blt x0, x15, spi5_load_data\n"); 
        asm volatile("beqz x0, spi6_dma\n");   
        asm volatile("spi5_load_data:\n");  
        asm volatile("lw x14,36(x13)\n"); // x15: data addr
        asm volatile("lw x6,0(x14)\n");   
        asm volatile("addi x14,x14, 4\n");  
        asm volatile("sw x14,36(x13)\n");   
        asm volatile("addi x15,x15, -1\n");  
        asm volatile("sw x15,32(x13)\n");   
        asm volatile("li x14,  4 \n");
        asm volatile("li x15,  0b000001000010 \n");
        asm volatile( io_cfg_reg(x0,x14,x15) ); 
        // SPI6
        asm volatile("spi6_dma:lb x15,40(x13)\n");
        asm volatile("blt x0, x15, spi6_load_data\n"); 
        asm volatile("beqz x0, spi7_dma\n");   
        asm volatile("spi6_load_data:\n");  
        asm volatile("lw x14,44(x13)\n"); // x15: data addr
        asm volatile("lw x7,0(x14)\n");   
        asm volatile("addi x14,x14, 4\n");  
        asm volatile("sw x14,44(x13)\n");   
        asm volatile("addi x15,x15, -1\n");  
        asm volatile("sw x15,40(x13)\n");   
        asm volatile("li x14,  5 \n");
        asm volatile("li x15,  0b000000100010 \n");
        asm volatile( io_cfg_reg(x0,x14,x15) ); 
        // SPI7
        asm volatile("spi7_dma:lb x15,48(x13)\n");
        asm volatile("blt x0, x15, spi7_load_data\n"); 
        asm volatile("beqz x0, spi8_dma\n");   
        asm volatile("spi7_load_data:\n");  
        asm volatile("lw x14,52(x13)\n"); // x15: data addr
        asm volatile("lw x8,0(x14)\n");   
        asm volatile("addi x14,x14, 4\n");  
        asm volatile("sw x14,52(x13)\n");   
        asm volatile("addi x15,x15, -1\n");  
        asm volatile("sw x15,48(x13)\n");   
        asm volatile("li x14,  6 \n");
        asm volatile("li x15,  0b000000100010 \n");
        asm volatile( io_cfg_reg(x0,x14,x15) ); 
        // SPI8
        asm volatile("spi8_dma:lb x15,56(x13)\n");
        asm volatile("blt x0, x15, spi8_load_data\n"); 
        asm volatile("beqz x0, dma_exit\n");   
        asm volatile("spi8_load_data:\n");  
        asm volatile("lw x14,60(x13)\n"); // x15: data addr
        asm volatile("lw x9,0(x14)\n");   
        asm volatile("addi x14,x14, 4\n");  
        asm volatile("sw x14,60(x13)\n");   
        asm volatile("addi x15,x15, -1\n");  
        asm volatile("sw x15,56(x13)\n");   
        asm volatile("li x14,  7 \n");
        asm volatile("li x15,  0b000001000010 \n");
        asm volatile( io_cfg_reg(x0,x14,x15) ); 

        asm volatile("dma_exit:\n");
        asm volatile("beqz x0, bit_loop\n");  

}


void handle_trap(void)
{
}
