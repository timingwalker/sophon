
#include <stdint.h>
#include "common.h"
#include "uart.h"

// set 1 to printf debug infomation
#define DEBUG_INFO    0

#define ITCM_BASE    0x80010000
#define ITCM_SIZE    0x00080000 
#define DTCM_BASE    0x80090100 // skip tohost section
#define DTCM_SIZE    0x00080000 

/* XMODEM protocol definitions */
#define XMODEM_SOH   0x01    /* Start of Header (128-byte block) */
#define XMODEM_EOT   0x04    /* End of Transmission */
#define XMODEM_ACK   0x06    /* Acknowledge */
#define XMODEM_NAK   0x15    /* Negative Acknowledge (also starts checksum mode) */
#define XMODEM_CAN   0x18    /* Cancel */

#define XMODEM_BLOCK_SIZE  128

extern volatile uint32_t tobrom;

/* ================================================
 * CRC calculation function
 * ================================================ */
static uint16_t calc_crc16(const uint8_t *data, uint32_t size) {
    uint16_t crc = 0x0000;
    for (uint32_t i = 0; i < size; i++) {
        crc ^= (uint16_t)data[i] << 8;
        for (int j = 0; j < 8; j++) {
            if (crc & 0x8000) {
                crc = (crc << 1) ^ 0x1021;
            } else {
                crc <<= 1;
            }
        }
    }
    return crc;
}

/* ================================================
 * XMODEM receive functions
 * ================================================ */
static int xmodem_receive_block(uint8_t *buffer, uint32_t *block_num) {
    uint8_t header, pkt_num, pkt_num_inv;
    uint8_t data[XMODEM_BLOCK_SIZE];
    
    /* Wait for header */
    header = uart_getc(g_console_port);
    
    /* Check for EOT */
    if (header == XMODEM_EOT) {
        uart_putc(g_console_port, XMODEM_ACK);
        return 0;
    }
    
    /* Check for cancel */
    if (header == XMODEM_CAN) {
        if (uart_getc(g_console_port) == XMODEM_CAN) {
            uart_putc(g_console_port, XMODEM_ACK);
            return -2;
        }
    }
    
    /* Must be SOH */
    if (header != XMODEM_SOH) {
        uart_putc(g_console_port, XMODEM_NAK);
        return -1;
    }
    
    /* Get packet number and its complement */
    pkt_num = uart_getc(g_console_port);
    pkt_num_inv = uart_getc(g_console_port);
    
    /* Validate packet number */
    if ((uint8_t)(pkt_num + pkt_num_inv) != 0xFF) {
        uart_putc(g_console_port, XMODEM_NAK);
        return -1;
    }
    
    /* Receive 128 bytes of data */
    for (int i = 0; i < XMODEM_BLOCK_SIZE; i++) {
        data[i] = uart_getc(g_console_port);
    }
    
    /* Receive CRC16 */
    uint16_t received_crc = (uart_getc(g_console_port) << 8) | uart_getc(g_console_port);
    uint16_t calculated_crc = calc_crc16(data, XMODEM_BLOCK_SIZE);
    
    if (received_crc != calculated_crc) {

    #if DEBUG_INFO == 1
        uart_putc(g_console_port, 'C');
        uart_putc(g_console_port, 'R');
        uart_putc(g_console_port, 'C');
        uart_putc(g_console_port, 'R');
        uart_putc(g_console_port, ':');
        uart_putc(g_console_port, received_crc);
        uart_putc(g_console_port, received_crc>>8);
        uart_putc(g_console_port, ':');
        uart_putc(g_console_port, 'C');
        uart_putc(g_console_port, ':');
        uart_putc(g_console_port, calculated_crc);
        uart_putc(g_console_port, calculated_crc>>8);
        uart_putc(g_console_port, ':');
        uart_putc(g_console_port, 'D');
        uart_putc(g_console_port, ':');
        for (int i = 0; i < XMODEM_BLOCK_SIZE; i++) {
            uart_putc(g_console_port, data[i]);
        }
    #endif

        uart_putc(g_console_port, XMODEM_NAK);
        return -1;
    }
    
    /* Validate packet number sequence */
    uint8_t expected_num = (*block_num & 0xFF) + 1;
    if (pkt_num != expected_num) {
        uart_putc(g_console_port, XMODEM_NAK);
        return -1;
    }
    

    for (int i = 0; i < XMODEM_BLOCK_SIZE; i++) {
        buffer[i] = data[i];
    }
    
    /* Update block number */
    *block_num = pkt_num;
    
    /* Send ACK */
    uart_putc(g_console_port, XMODEM_ACK);
    return XMODEM_BLOCK_SIZE;
}


static int xmodem_receive(uint8_t *dest_addr, uint32_t max_size) {

    uint32_t total_received = 0;
    uint32_t block_num = 0;
    uint8_t *dest = dest_addr;
    int error_count = 0;
    
    /* Send 'C' to start CRC mode */
    uint32_t cycle_val_old;
    uint32_t cycle_val_new;
    __asm__ volatile ("csrr %0, 0xB00" : "=r" (cycle_val_old));
    __asm__ volatile ("csrr %0, 0xB00" : "=r" (cycle_val_new));
    while( (((int) _REG32(g_console_port, UART_REG_LSR)) & 0x01) != 0x1 ) {
        __asm__ volatile ("csrr %0, 0xB00" : "=r" (cycle_val_new));
        if ( (cycle_val_new - cycle_val_old) > 50000000 ) {
            __asm__ volatile ("csrr %0, 0xB00" : "=r" (cycle_val_old));
            uart_putc(g_console_port, 'C');  /* 0x43 */
        }
    }

    while (1) {

        int result = xmodem_receive_block(dest, &block_num);
        
        if (result > 0) {
            dest += result;
            total_received += result;
            error_count = 0;
            
            if (total_received > max_size) {
                uart_putc(g_console_port, XMODEM_CAN);
                uart_putc(g_console_port, XMODEM_CAN);
                return -1;
            }
        } else if (result == 0) {
            return total_received;
        } else {
            error_count++;
            if (error_count > 3) {
                uart_putc(g_console_port, XMODEM_CAN);
                uart_putc(g_console_port, XMODEM_CAN);
                return -1;
            }
        }
    }
}

/* ================================================
 * Bootloader entry point
 * ================================================ */
void xmodem_bootloader(void) {

    uart_putc(g_console_port, 'i');

    /* Receive firmware to ITCM */
    int received = xmodem_receive((uint8_t *)ITCM_BASE, ITCM_SIZE);
    
    if (received > 0) {
    #if DEBUG_INFO == 1
        volatile uint8_t *i_ram;
        i_ram = (volatile uint8_t *)ITCM_BASE;
        for (int i = 0; i < 5; i++) {
            uart_putc(g_console_port, i_ram[i]);
        }
        uart_putc(g_console_port, '\n');
    #endif
        uart_putc(g_console_port, '-');
    }
    else {
    #if DEBUG_INFO == 1
        uart_putc(g_console_port, 'E');
    #endif
        return -1;
    }

    uart_putc(g_console_port, 'd');

    int received_dtcm = xmodem_receive((uint8_t *)DTCM_BASE, DTCM_SIZE);

    if (received_dtcm > 0) {
    #if DEBUG_INFO == 1
        volatile uint8_t *d_ram;
        d_ram = (volatile uint8_t *)DTCM_BASE;
        for (int i = 0; i < 5; i++) {
            uart_putc(g_console_port, d_ram[i]);
        }
        uart_putc(g_console_port, '\n');
        uart_putc(g_console_port, '-');
    #endif

        tobrom = 0x66688888;

        uart_putc(g_console_port, 'j');
        uart_putc(g_console_port, '\n');

        asm volatile ( "li t0,0x80010000" );
        asm volatile ( "jalr ra, t0, 0" );

    }
    else {
    #if DEBUG_INFO == 1
        uart_putc(g_console_port, 'E');
    #endif
        return -2;
    }

    
    /* Failed, cancel transmission */
    uart_putc(g_console_port, XMODEM_CAN);
    uart_putc(g_console_port, XMODEM_CAN);

    #if DEBUG_INFO == 1
        uart_putc(g_console_port, 'F');
    #endif

}



int _brom_main()
{

    uint32_t hw_para;
    __asm__ volatile ("csrr %0, 0xCC0" : "=r" (hw_para));
    char uart_enabled = hw_para & (1<<HWINFO_EXT_DATA);
    if ( uart_enabled ) {
        uart_init();
    }

    // check tobrom
    if ( tobrom == 0x66688888 ) {  
        if ( uart_enabled ) {
            uart_putc(g_console_port, 'j');
            uart_putc(g_console_port, '\n');
        }
        asm volatile ( "li t0,0x80010000" );
        asm volatile ( "jalr ra, t0, 0" );
    }
    else {
        xmodem_bootloader();
    }

}

