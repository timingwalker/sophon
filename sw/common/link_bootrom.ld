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


MEMORY
{
    BOOTROM (rx) : ORIGIN = 0x80000000, LENGTH = 2K
    DTCM    (rw) : ORIGIN = 0x80090000, LENGTH = 0x100
}


/*----------------------------------------------------------------------*/
/* Sections                                                             */
/*----------------------------------------------------------------------*/

SECTIONS
{

  /* text: test code section */
  .text.init : { 
      *(.text.init) 
  } > BOOTROM

  .text : {
      *(.text) 
  } > BOOTROM

  
  .tohost : { 
      *(.tohost) 
  } > DTCM 


  .data : {
      _sdata = .;
      *(.data .data.*) 
      __global_pointer$ = . + 0x60;
      *(.sdata .sdata.* .gnu.linkonce.s.*)
      *(.srodata .srodata.*) 
      _edata = .;
  } > DTCM AT > BOOTROM

  _sidata = LOADADDR(.data);


  .sbss : {
      . = ALIGN(4);
      _bss_start = .;
      *(.sbss .sbss.* .gnu.linkonce.sb.*)
      *(.scommon)
  } > DTCM

  .bss : {
      *(.bss) 
      _bss_end = .;
  } > DTCM


  .tdata :
  {
      _tdata_begin = .;
      *(.tdata)
      _tdata_end = .;
  } > DTCM


  .tbss :
  {
      *(.tbss)
      _tbss_end = .;
  } > DTCM


  _end = .;

  . = 0x80090100;
  __sp_pointer$ = .;

}

