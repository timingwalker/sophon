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
  li  x1, 0
  li  x2, 0
  li  x3, 0
  li  x4, 0
  li  x5, 0
  li  x6, 0
  li  x7, 0
  li  x8, 0
  li  x9, 0
  li  x10,0
  li  x11,0
  li  x12,0
  li  x13,0
  li  x14,0
  li  x15,0
#if __RV32E == 0
  li  x16,0
  li  x17,0
  li  x18,0
  li  x19,0
  li  x20,0
  li  x21,0
  li  x22,0
  li  x23,0
  li  x24,0
  li  x25,0
  li  x26,0
  li  x27,0
  li  x28,0
  li  x29,0
  li  x30,0
  li  x31,0
#endif


  # make sure XLEN agrees with compilation choice
  li t0, 1
  slli t0, t0, 31
#if __riscv_xlen == 64
  bgez t0, 1f
#else
  bltz t0, 1f
#endif
2:
  li a0, 1
  sw a0, tohost, t0
  j 2b
1:


#if __RVZICSR == 1
  # set mtvt of CLIC mode
  la t0, 1f
  csrw mtvec, t0
  la t0, vector_table
  # csrw mtvt, t0
  csrw 0x307, t0
1:
  # initialize trap vector
  la t0, trap_entry
  csrw mtvec, t0
#endif


  # initialize global pointer
.option push
.option norelax
  la gp, __global_pointer$
.option pop


  la  tp, _end + 63
  and tp, tp, -64


#if __RVZICSR == 1
  # get core id
  csrr a0, mhartid
#else
  li a0, 0
#endif
  # for now, assume only 1 core
  li a1, 1
1:bgeu a0, a1, 1b

  # give each core 16KB of stack + TLS
#if __RV32E == 0
#define STKSHIFT 14
#else
  # give each core 2KB of stack + TLS
#define STKSHIFT 11
#endif
  add sp, a0, 1
  sll sp, sp, STKSHIFT
  add sp, sp, tp
  sll a2, a0, STKSHIFT
  add tp, tp, a2


  # clear BSS
  la x6, _bss_start
  la x7, _bss_end
  bge x6, x7, clear_bss
clear_bss:
  sw x0, 0(x6)
  addi x6, x6, 4
  ble x6,x7, clear_bss
clear_bss_end:
  li  x6,0
  li  x7,0

  j _init


.align 6
.weak trap_entry
trap_entry:
  addi sp, sp, -272

  SREG x1, 1*REGBYTES(sp)
  SREG x2, 2*REGBYTES(sp)
  SREG x3, 3*REGBYTES(sp)
  SREG x4, 4*REGBYTES(sp)
  SREG x5, 5*REGBYTES(sp)
  SREG x6, 6*REGBYTES(sp)
  SREG x7, 7*REGBYTES(sp)
  SREG x8, 8*REGBYTES(sp)
  SREG x9, 9*REGBYTES(sp)
  SREG x10, 10*REGBYTES(sp)
  SREG x11, 11*REGBYTES(sp)
  SREG x12, 12*REGBYTES(sp)
  SREG x13, 13*REGBYTES(sp)
  SREG x14, 14*REGBYTES(sp)
  SREG x15, 15*REGBYTES(sp)
#if __RV32E == 0
  SREG x16, 16*REGBYTES(sp)
  SREG x17, 17*REGBYTES(sp)
  SREG x18, 18*REGBYTES(sp)
  SREG x19, 19*REGBYTES(sp)
  SREG x20, 20*REGBYTES(sp)
  SREG x21, 21*REGBYTES(sp)
  SREG x22, 22*REGBYTES(sp)
  SREG x23, 23*REGBYTES(sp)
  SREG x24, 24*REGBYTES(sp)
  SREG x25, 25*REGBYTES(sp)
  SREG x26, 26*REGBYTES(sp)
  SREG x27, 27*REGBYTES(sp)
  SREG x28, 28*REGBYTES(sp)
  SREG x29, 29*REGBYTES(sp)
  SREG x30, 30*REGBYTES(sp)
  SREG x31, 31*REGBYTES(sp)
#endif

#if __RVZICSR == 1
  csrr a0, mcause
  csrr a1, mepc
#endif
  mv a2, sp
  jal handle_trap
#if __RVZICSR == 1
  csrw mepc, a0
  # Remain in M-mode after eret
  li t0, MSTATUS_MPP
  csrs mstatus, t0
#endif

  LREG x1, 1*REGBYTES(sp)
  LREG x2, 2*REGBYTES(sp)
  LREG x3, 3*REGBYTES(sp)
  LREG x4, 4*REGBYTES(sp)
  LREG x5, 5*REGBYTES(sp)
  LREG x6, 6*REGBYTES(sp)
  LREG x7, 7*REGBYTES(sp)
  LREG x8, 8*REGBYTES(sp)
  LREG x9, 9*REGBYTES(sp)
  LREG x10, 10*REGBYTES(sp)
  LREG x11, 11*REGBYTES(sp)
  LREG x12, 12*REGBYTES(sp)
  LREG x13, 13*REGBYTES(sp)
  LREG x14, 14*REGBYTES(sp)
  LREG x15, 15*REGBYTES(sp)
#if __RV32E == 0
  LREG x16, 16*REGBYTES(sp)
  LREG x17, 17*REGBYTES(sp)
  LREG x18, 18*REGBYTES(sp)
  LREG x19, 19*REGBYTES(sp)
  LREG x20, 20*REGBYTES(sp)
  LREG x21, 21*REGBYTES(sp)
  LREG x22, 22*REGBYTES(sp)
  LREG x23, 23*REGBYTES(sp)
  LREG x24, 24*REGBYTES(sp)
  LREG x25, 25*REGBYTES(sp)
  LREG x26, 26*REGBYTES(sp)
  LREG x27, 27*REGBYTES(sp)
  LREG x28, 28*REGBYTES(sp)
  LREG x29, 29*REGBYTES(sp)
  LREG x30, 30*REGBYTES(sp)
  LREG x31, 31*REGBYTES(sp)
#endif

  addi sp, sp, 272
  mret


// int16 is used in CLIC non-shv test
// int17 is used in CLIC shv test
.align 6
.weak int16_handle
int16_handle:
1:
    j 1b
.align 6
.weak int17_handle
int17_handle:
1:
    j 1b

.global __dummy
__dummy:
    j __dummy

.section .data
.align 6
vector_table:
    .rept 16
    .long __dummy
    .endr
    .long int16_handle
    .long int17_handle


.section ".tohost","aw",@progbits
.align 6
.globl tohost
tohost: .dword 0
.align 6
.globl fromhost
fromhost: .dword 0
.align 6
.globl hwinfo
hwinfo: .dword 0
