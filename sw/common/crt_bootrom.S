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

.section ".text"
.align 6
.globl trap_entry
trap_entry:
  addi sp, sp, -32
  sw ra,  0(sp)
  sw t0,  4(sp)
  sw t1,  8(sp)
  sw t2, 12(sp)
  sw a0, 16(sp)
  sw a1, 20(sp)
  sw a2, 24(sp)
  sw a3, 28(sp)

  csrr a0, mcause
  csrr a1, mepc
  csrr a2, mtval
  csrr a3, mstatus

  call trap_handler

  lw ra,  0(sp)
  lw t0,  4(sp)
  lw t1,  8(sp)
  lw t2, 12(sp)
  lw a0, 16(sp)
  lw a1, 20(sp)
  lw a2, 24(sp)
  lw a3, 28(sp)
  addi sp, sp, 32
1:j 1b
