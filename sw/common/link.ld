/*======================================================================*/
/* Proxy kernel linker script                                           */
/*======================================================================*/
/* This is the linker script used when building the proxy kernel. */

/*----------------------------------------------------------------------*/
/* Setup                                                                */
/*----------------------------------------------------------------------*/

/* The OUTPUT_ARCH command specifies the machine architecture where the
   argument is one of the names used in the BFD library. More
   specifically one of the entires in bfd/cpu-mips.c */

OUTPUT_ARCH( "riscv" )
ENTRY(_start)

/*----------------------------------------------------------------------*/
/* Sections                                                             */
/*----------------------------------------------------------------------*/

SECTIONS
{

  /* text: test code section */
  . = 0x80010000;
  .text.init : { *(.text.init) }
  .text : { *(.text) }

  . = 0x80090000;
  .tohost : { *(.tohost) }

  /* ============================================================
   *  * sysuart.ld - emulated System UART interface 
   *  * Layout: rx_ctrl(4B) rx_buf(8B) tx_ctrl(4B) tx_buf(8B) = 24B
   * ============================================================ */
  sys_uart_base    = 0x80090010;
  sys_uart_rx_ctrl = sys_uart_base + 0x00;   /* 4B: +0 wr +1 rd +2 ovf +3 cnt */
  sys_uart_rx_buf  = sys_uart_base + 0x04;   /* 8B (2 words, capacity 1) */
  sys_uart_tx_ctrl = sys_uart_base + 0x0C;   /* 4B */
  sys_uart_tx_buf  = sys_uart_base + 0x10;   /* 8B (2 words, capacity 1) */
  sys_uart_end     = sys_uart_base + 0x18;   /* total 24B */

  . = ALIGN(0x100);
  .rodata : { *(.rodata) }
  
  /* data segment */
  .data : { *(.data) }

  .sdata : {
    __global_pointer$ = . + 0x800;
    *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata*)
    *(.sdata .sdata.* .gnu.linkonce.s.*)
  }

  /* bss segment */
  .sbss : {
    . = ALIGN(4);
    _bss_start = .;
    *(.sbss .sbss.* .gnu.linkonce.sb.*)
    *(.scommon)
  }

  .bss : {
      *(.bss) 
    _bss_end = .;
  }

  /* thread-local data segment */
  .tdata :
  {
    _tdata_begin = .;
    *(.tdata)
    _tdata_end = .;
  }
  .tbss :
  {
    *(.tbss)
    _tbss_end = .;
  }

  /* End of uninitalized data segement */
  _end = .;
}

