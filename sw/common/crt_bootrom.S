# =======================================
# exception is not enabled in bootcode!
# =======================================

#include "encoding.h"

.section ".text.init"
.globl _start
_start:

  # initialize global pointer
  .option push
  .option norelax
    la gp, __global_pointer$
  .option pop

  # la  tp, _end + 63
  # and tp, tp, -64
  la sp, __sp_pointer$

  j _brom_main


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
