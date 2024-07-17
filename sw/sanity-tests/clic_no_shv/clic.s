.align 6
.global irq_enter
irq_enter:
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
