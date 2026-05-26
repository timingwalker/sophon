
#include <stdint.h>
#include "common.h"


#define OUT_X_L_G  0x18
#define OUT_X_H_G  0x19
#define OUT_Y_L_G  0x1A   
#define OUT_Y_H_G  0x1B
#define OUT_Z_L_G  0x1C
#define OUT_Z_H_G  0x1D

#define OUT_X_L_XL 0x28
#define OUT_X_H_XL 0x29
#define OUT_Y_L_XL 0x2A  
#define OUT_Y_H_XL 0x2B
#define OUT_Z_L_XL 0x2C
#define OUT_Z_H_XL 0x2D


#define CTRL_REG1_M  0x20
#define CTRL_REG2_M  0x21
#define CTRL_REG3_M  0x22
#define CTRL_REG4_M  0x23

#define OUT_X_L_M    0x28
#define OUT_X_H_M    0x29
#define OUT_Y_L_M    0x2A
#define OUT_Y_H_M    0x2B
#define OUT_Z_L_M    0x2C
#define OUT_Z_H_M    0x2D


#define WHO_AM_I_AG   0x0F
#define CTRL_REG1_G   0x10

#define WHO_AM_I_M    0x0F
#define CTRL_REG1_M   0x20

#define CTRL_REG6_XL   0x20

#define READ_FLAG     0x80
#define MULTI_READ    0x40

#define CS_AG         0xFFFFF7FF
#define CS_M          0xFFFFDFFF

char fgpio_spi_single_itf_AG( char sent_data );
char fgpio_spi_single_itf_M( char sent_data );
char fgpio_spi_single_itf_ALT( char sent_data );
char fgpio_spi_single_itf_PmodD(int16_t sent_data, int cs );
char fgpio_spi_single_itf_PmodD_M( char sent_data );
char fgpio_spi_single_itf_PmodD_ALT( char sent_data );

char write_reg( char addr, char wdata, int cs ){
    uint16_t sent_data;
    sent_data = (addr & 0x7F ) << 8;
    sent_data = sent_data | wdata;

    fgpio_spi_single_itf_PmodD( sent_data, cs  );

}

uint8_t read_reg( char addr, int cs){
    uint8_t rdata;
    uint16_t sent_data;
    sent_data = (addr | 0x80 ) << 8;
    sent_data = sent_data | 0x00;

    rdata= fgpio_spi_single_itf_PmodD( sent_data, cs );

    return rdata;
}

void lsm9ds1_init() {
    // Gyro: 
    write_reg(CTRL_REG1_G, 0xA0, CS_AG );

    // Acc: 
    write_reg(CTRL_REG6_XL, 0xB0, CS_AG); // CTRL_REG6_XL
}

void mag_init(void) {

    mag_reset();

    // CTRL_REG1_M: 80 Hz, XY high performance
    write_reg(CTRL_REG1_M, 0x7E, CS_M);

    // CTRL_REG2_M: ±4 Gauss
    write_reg(CTRL_REG2_M, 0x00, CS_M);


    // CTRL_REG4_M: Z high performance
    write_reg(CTRL_REG4_M, 0x0C, CS_M);

    // CTRL_REG3_M: continuous conversion mode
    write_reg(CTRL_REG3_M, 0x00, CS_M);
    usleep(1000);

}

void mag_reset(void) {
    // 1. Write software reset command 
    write_reg(CTRL_REG2_M, 0x0C, CS_M);  // Software reset

    // 2. Wait longer for reset completion
    usleep(100000);  // 100ms

    // 3. Check WHO_AM_I again
    uint8_t id = read_reg(WHO_AM_I_M, CS_M);
    printf("M sensor after reset: %x\n", id);
}

void mag_read_xyz(int16_t *mx, int16_t *my, int16_t *mz) {
        // Read data registers
        uint8_t xl = read_reg(OUT_X_L_M, CS_M);
        uint8_t xh = read_reg(OUT_X_H_M, CS_M);
        uint8_t yl = read_reg(OUT_Y_L_M, CS_M);
        uint8_t yh = read_reg(OUT_Y_H_M, CS_M);
        uint8_t zl = read_reg(OUT_Z_L_M, CS_M);
        uint8_t zh = read_reg(OUT_Z_H_M, CS_M);

        *mx = (int16_t)((xh << 8) | xl);
        *my = (int16_t)((yh << 8) | yl);
        *mz = (int16_t)((zh << 8) | zl);
}


void read_gyro_xyz(int16_t *gx, int16_t *gy, int16_t *gz) {
    uint8_t xl = read_reg(OUT_X_L_G     , CS_AG ) ;
    uint8_t xh = read_reg(OUT_X_L_G + 1 , CS_AG ) ;
    uint8_t yl = read_reg(OUT_Y_L_G     , CS_AG ) ;
    uint8_t yh = read_reg(OUT_Y_L_G + 1 , CS_AG ) ;
    uint8_t zl = read_reg(OUT_Z_L_G     , CS_AG ) ;
    uint8_t zh = read_reg(OUT_Z_L_G + 1 , CS_AG ) ;

    *gx = (int16_t)((xh << 8) | xl);
    *gy = (int16_t)((yh << 8) | yl);
    *gz = (int16_t)((zh << 8) | zl);
}

void read_accel_xyz(int16_t *ax, int16_t *ay, int16_t *az) {
    uint8_t xl = read_reg(OUT_X_L_XL     , CS_AG ) ;
    uint8_t xh = read_reg(OUT_X_L_XL + 1 , CS_AG ) ;
    uint8_t yl = read_reg(OUT_Y_L_XL     , CS_AG ) ;
    uint8_t yh = read_reg(OUT_Y_L_XL + 1 , CS_AG ) ;
    uint8_t zl = read_reg(OUT_Z_L_XL     , CS_AG ) ;
    uint8_t zh = read_reg(OUT_Z_L_XL + 1 , CS_AG ) ;

    *ax = (int16_t)((xh << 8) | xl);
    *ay = (int16_t)((yh << 8) | yl);
    *az = (int16_t)((zh << 8) | zl);
}





int main() {

    int16_t gx, gy, gz;
    int16_t ax, ay, az;
    int16_t mx, my, mz;

    uint8_t rdata;

    printf("Test Pomd_D\n");
    printf("AG:\n");
    printf("R 0F: ");
    rdata = read_reg(WHO_AM_I_AG, CS_AG);
    printf("%x \n", rdata);

    printf("W 10: ");
    write_reg(CTRL_REG1_G, 0x60, CS_AG);
    rdata = read_reg(CTRL_REG1_G, CS_AG);
    printf("R 10: %x \n", rdata);

    printf("M:\n");
    printf("R 0F: ");
    rdata = read_reg(WHO_AM_I_M, CS_M);
    printf("%x \n", rdata);

    // Check M sensor ID and retry if abnormal
    if (rdata != 0x3D) {
        printf("M sensor ID abnormal (%x), attempting re-initialization...\r\n", rdata);
        // Try reset
        mag_reset();
        // Check again
        rdata = read_reg(WHO_AM_I_M, CS_M);
        printf("M sensor ID after reset: %x\r\n", rdata);
    }

    lsm9ds1_init();
    mag_init();


    while (1) {
        read_gyro_xyz(&gx, &gy, &gz);
        read_accel_xyz(&ax, &ay, &az);

        mag_read_xyz(&mx, &my, &mz);

        uint64_t curr_time = get_mcycle();
        printf("%d,%d, %d,%d,%d,%d,%d,%d,%d,%d,%d\r\n",(uint32_t)(curr_time>>32), (uint32_t)(curr_time), gx, gy, gz, ax, ay, az, mx, my, mz);
        //printf("%d,%d,%d,%d,%d,%d,%d,%d,%d\r\n", gx, gy, gz, ax, ay, az, mx, my, mz);

        usleep(1000);
    }

    return 0;
}




//   int main()
//   {
//   
//   	volatile uint8_t i = 0;
//   	volatile char MISO = 0;
//   
//       // ------------------------------------------------
//       // single interface test
//       // ------------------------------------------------
//   
//       uint8_t rdata;
// 
//       printf("Test Pmod A:\n");
//       // ----------------------------------------------------------------------
//       printf("Test AG:\n");
//       printf("R 0F: ");
//       rdata = fgpio_spi_single_itf_AG( 0x8F );
//       printf("%x \n", rdata);
//   
//       printf("R 0B :");
//       rdata = fgpio_spi_single_itf_AG( 0x8B );
//       printf("%x \n", rdata);
//   
//       printf("R 0F: ");
//       rdata = fgpio_spi_single_itf_AG( 0x8F );
//       printf("%x \n", rdata);
//   
//   
//       // ----------------------------------------------------------------------
//       printf("Test M:\n");
//       printf("R 0F: ");
//       rdata = fgpio_spi_single_itf_M( 0x8F );
//       printf("%x \n", rdata);
//   
//       printf("R 0B :");
//       rdata = fgpio_spi_single_itf_M( 0x8B );
//       printf("%x \n", rdata);
//   
//       printf("R 0F: ");
//       rdata = fgpio_spi_single_itf_M( 0x8F );
//       printf("%x \n", rdata);
//   
//       // ----------------------------------------------------------------------
//       printf("Test ALT:\n");
//       printf("R 0F: ");
//       rdata = fgpio_spi_single_itf_ALT( 0x8F );
//       printf("%x \n", rdata);
//   
//       printf("R 0B :");
//       rdata = fgpio_spi_single_itf_ALT( 0x8B );
//       printf("%x \n", rdata);
//   
//       printf("R 0F: ");
//       rdata = fgpio_spi_single_itf_ALT( 0x8F );
//       printf("%x \n", rdata);
//   
//       // ----------------------------------------------------------------------
//       printf("\nTest Pmod D:\n");
//       
//       printf("R 0F: ");
//       rdata = fgpio_spi_single_itf_PmodD( 0x8F );
//       printf("%x \n", rdata);
//   
//       printf("R 0F: ");
//       rdata = fgpio_spi_single_itf_PmodD_M( 0x8F );
//       printf("%x \n", rdata);
//   
//       printf("R 0F: ");
//       rdata = fgpio_spi_single_itf_PmodD_ALT( 0x8F );
//       printf("%x \n", rdata);
//   
//   
//       while (1)
//       {
//       }
//   
//   }


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
char fgpio_spi_single_itf_PmodD(int16_t sent_data, int cs )
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
    asm volatile("slli x4, x10, 0\n"); 
    
    // idle: set cs/clk=1
    asm volatile("li x14,  0x3D00 \n");
    asm volatile("li x15,  0x3D00 \n");
    asm volatile( io_out_raw(x0,x14,x15) );

    //asm volatile("li x15,  0x9 \n");
    asm volatile("li x15,  0x3800 \n");

    // ------------------------------------------------
    // transmit
    // ------------------------------------------------
    
    // set cs=0
   
    //asm volatile("li x14,  0x1 \n");
    //asm volatile("li x14,  0x3000 \n");
    asm volatile( io_out_raw(x0,x11,x15) );

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
    asm volatile("slli x10, x4, 8\n");
    asm volatile("srli x10, x10, 24\n");

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
