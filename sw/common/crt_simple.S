# See LICENSE for license details.

#include "encoding.h"

#if __riscv_xlen == 64
# define LREG ld
# define SREG sd
# define REGBYTES 8
#else
# define LREG lw
# define SREG sw
# define REGBYTES 4
#endif

.section ".text.init"
.globl _start
_start:

  j _init_simple_crt


.section ".tohost","aw",@progbits
.align 2
.globl tobrom
tobrom: .word 0
.align 2
.globl tohost
tohost: .word 0
.align 2
.globl fromhost
fromhost: .word 0
.align 2
.globl hwinfo
hwinfo: .word 0
