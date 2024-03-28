
  .section .text.init
  .globl _prog_start
_prog_start:
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

    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop

    # li sp, 0x009F000
    # allocate stack. refer to riscv-tests/benchmarks/common
    la  tp, _end + 63
    and tp, tp, -64
    # give each core 16KB of stack + TLS
    #define STKSHIFT 14
    csrr a0, mhartid
    add sp, a0, 1
    sll sp, sp, 14
    add sp, sp, tp
    sll a2, a0, 14
    add tp, tp, a2

    la t0, irq_enter
    andi t0, t0, 0xfffffffd
    csrw mtvec, t0

    la t0, vector_table
    csrw mtvt, t0


    call main

    slli a0, a0, 0x1
    ori a0, a0, 0x1

    la t0, tohost
    sw a0, 0(t0)

    ecall

loop:
    j loop



.align 6
.weak irq_enter
irq_enter:
  
    #.insn r 0x2b,0,0x0,x1,x30,x0

    addi sp, sp, -16*4
    sw ra, 0*4(sp)
    sw a0, 1*4(sp)
    sw a1, 2*4(sp)
    sw a2, 3*4(sp)
    sw a3, 4*4(sp)
    sw a4, 5*4(sp)
    sw a5, 6*4(sp)
    sw a6, 7*4(sp)
    sw a7, 8*4(sp)
    sw t0, 9*4(sp)
    sw t1, 10*4(sp)
    sw t2, 11*4(sp)
    sw t3, 12*4(sp)
    sw t4, 13*4(sp)
    sw t5, 14*4(sp)
    sw t6, 15*4(sp)

    csrrsi a0, mnxti, 0x1    # Get highest current interrupt, but disable MIE
    beqz a0, exit            # Check if original interrupt vanished.
service_loop:             
    lw a1, (a0)              # Indirect into handler vector table for function pointer.
    #csrrsi x0, mstatus, 0x0 # Ensure interrupts enabled.
    jalr a1                  # Call C ABI Routine, a0 has interrupt ID encoded.
                             # Routine must clear down interrupt in CLIC.
    csrrsi a0, mnxti, 0x1    # Claim any pending interrupt at level > mcause.pil
    bnez a0, service_loop    # Loop to service any interrupt.

    #.insn r 0x2b,0,0x40,x1,x30,x0
    lw ra, 0*4(sp)
    lw a0, 1*4(sp)
    lw a1, 2*4(sp)
    lw a2, 3*4(sp)
    lw a3, 4*4(sp)
    lw a4, 5*4(sp)
    lw a5, 6*4(sp)
    lw a6, 7*4(sp)
    lw a7, 8*4(sp)
    lw t0, 9*4(sp)
    lw t1, 10*4(sp)
    lw t2, 11*4(sp)
    lw t3, 12*4(sp)
    lw t4, 13*4(sp)
    lw t5, 14*4(sp)
    lw t6, 15*4(sp)
 exit:   
    addi sp, sp, 16*4

    mret

# .align 6
# trap_handler:
# 
#     addi sp, sp, -48
# 
#     # save context
#     .insn r 0x2b,0,0x0,x1,x30,x0
# 
#     csrr a0, mcause
#     sw a0, 12(sp)
#     csrr a1, mepc
#     sw a1, 8(sp)
#     csrr a2, mstatus
#     sw a2, 4(sp)
# 
#     andi t1, t0, 0xfff 
#     srli t0, t0, 0x1b
#     andi t0, t0, 0x10
#     add t0, t0, t1
#     slli t0, t0, 0x2
#     la t1, vector_table 
#     add t0, t0, t1
#     lw t1, 0(t0)
# 
#     //handle with the exception or non vector int
#     jalr t1
#     //recovery the cpu field
#     lw t2, 4(sp)
#     csrw mstatus, t2
#     lw t1, 8(sp)
#     csrw mepc, t1
#     lw t0, 12(sp)
#     csrw mcause, t0
# 
#     # restore context
#     .insn r 0x2b,0,0x40,x1,x30,x0
# 
#     mret


.weak handle_trap
handle_trap:
1:
    j 1b



  
.weak int16_handle
int16_handle:
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


.section ".tohost","aw",@progbits
.align 6
.globl tohost
tohost: .dword 0
