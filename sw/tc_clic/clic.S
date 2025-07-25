#include "encoding.h"

.align 6
.global trap_entry
trap_entry:
    addi sp, sp, -16*4
    sw ra, 0*4(sp)
    sw a0, 1*4(sp)
    sw a1, 2*4(sp)
    sw a2, 3*4(sp)
    sw a3, 4*4(sp)
    sw a4, 5*4(sp)
    sw a5, 6*4(sp)
    sw t0, 9*4(sp)
    sw t1, 10*4(sp)
    sw t2, 11*4(sp)
#if __RV32E == 0
    sw a6, 7*4(sp)
    sw a7, 8*4(sp)
    sw t3, 12*4(sp)
    sw t4, 13*4(sp)
    sw t5, 14*4(sp)
    sw t6, 15*4(sp)
#endif

    #csrrsi a0, mnxti, 0x1    # Get highest current interrupt, but disable MIE
    csrrsi a0, 0x345, 0x1    # Get highest current interrupt, but disable MIE
    beqz a0, exit            # Check if original interrupt vanished.
service_loop:             
    lw a1, (a0)              # Indirect into handler vector table for function pointer.
    #csrrsi x0, mstatus, 0x0 # Ensure interrupts enabled.
    jalr a1                  # Call C ABI Routine, a0 has interrupt ID encoded.
                             # Routine must clear down interrupt in CLIC.
    #csrrsi a0, mnxti, 0x1    # Claim any pending interrupt at level > mcause.pil
    csrrsi a0, 0x345, 0x1    # Claim any pending interrupt at level > mcause.pil
    bnez a0, service_loop    # Loop to service any interrupt.

    lw ra, 0*4(sp)
    lw a0, 1*4(sp)
    lw a1, 2*4(sp)
    lw a2, 3*4(sp)
    lw a3, 4*4(sp)
    lw a4, 5*4(sp)
    lw a5, 6*4(sp)
    lw t0, 9*4(sp)
    lw t1, 10*4(sp)
    lw t2, 11*4(sp)
#if __RV32E == 0
    lw a6, 7*4(sp)
    lw a7, 8*4(sp)
    lw t3, 12*4(sp)
    lw t4, 13*4(sp)
    lw t5, 14*4(sp)
    lw t6, 15*4(sp)
#endif
 exit:   
    addi sp, sp, 16*4

    mret




.align 6
.global trap_entry_snapreg
trap_entry_snapreg:
    # .insn r 0x2b,0,0x0,x1,x30,x0
#if __RV32E == 0
    .insn r 0x2b,1,0x0,x0,x1,x30
    #snapreg_save(x0,x1,x30)
#else
    .insn r 0x2b,1,0x0,x0,x1,x15
#endif

    #csrrsi a0, mnxti, 0x1    # Get highest current interrupt, but disable MIE
    csrrsi a0, 0x345, 0x1    # Get highest current interrupt, but disable MIE
    beqz a0, exit2           # Check if original interrupt vanished.
service_loop2:             
    lw a1, (a0)              # Indirect into handler vector table for function pointer.
    #csrrsi x0, mstatus, 0x0 # Ensure interrupts enabled.
    jalr a1                  # Call C ABI Routine, a0 has interrupt ID encoded.
                             # Routine must clear down interrupt in CLIC.
    #csrrsi a0, mnxti, 0x1    # Claim any pending interrupt at level > mcause.pil
    csrrsi a0, 0x345, 0x1    # Claim any pending interrupt at level > mcause.pil
    bnez a0, service_loop2   # Loop to service any interrupt.

    # .insn r 0x2b,0,0x40,x1,x30,x0
#if __RV32E == 0
    .insn r 0x2b,1,0x40,x0,x1,x30
    #snapreg_recover(x0,x1,x30)
#else
     .insn r 0x2b,1,0x40,x0,x1,x15
#endif
 exit2:   
    mret

