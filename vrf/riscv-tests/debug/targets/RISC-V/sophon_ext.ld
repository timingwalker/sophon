OUTPUT_ARCH( "riscv" )

SECTIONS
{
  . = 0x00001000;
  .text : 
  {
    *(.text.entry)
    *(.text)
  }

  . = 0x00012000;
  .tohost : { *(.tohost) }
  . = ALIGN(0x100);
  /* data segment */
  .data : { *(.data) }

  .sdata : {
    __global_pointer$ = . + 0x800;
    *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2)
    *(.srodata*)
    *(.sdata .sdata.* .gnu.linkonce.s.*)
  }

  /* bss segment */
  __bss_start = .;
  .sbss : {
    *(.sbss .sbss.* .gnu.linkonce.sb.*)
    *(.scommon)
  }
  .bss : { *(.bss) }
  __bss_end = .;

  __malloc_start = .;
  . = . + 512;

  /* End of uninitalized data segement */
  _end = .;
}

