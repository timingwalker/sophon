ENTRY(_prog_start)

SECTIONS
{

    . = 0x80000000;
    .text.init : { *(.text.init) }
    .text : { *(.text) }

    . = 0x80090000;
    .tohost : { *(.tohost) }
    . = ALIGN(0x1000);
    /* data segment */
    .data : { *(.data) }

    .sdata : {
        __global_pointer$ = . + 0x800;
        *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata*)
        *(.sdata .sdata.* .gnu.linkonce.s.*)
    }

    /* bss segment */
    .sbss : {
        *(.sbss .sbss.* .gnu.linkonce.sb.*)
        *(.scommon)
    }
    .bss : { *(.bss) }

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

