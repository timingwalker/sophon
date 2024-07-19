.align 6
.global irq_enter
irq_enter:
    # .insn r 0x2b,0,0x0,x1,x30,x0
    .insn r 0x2b,0,0x0,x0,x1,x30

    csrrsi a0, mnxti, 0x1    # Get highest current interrupt, but disable MIE
    beqz a0, exit            # Check if original interrupt vanished.
service_loop:             
    lw a1, (a0)              # Indirect into handler vector table for function pointer.
    #csrrsi x0, mstatus, 0x0 # Ensure interrupts enabled.
    jalr a1                  # Call C ABI Routine, a0 has interrupt ID encoded.
                             # Routine must clear down interrupt in CLIC.
    csrrsi a0, mnxti, 0x1    # Claim any pending interrupt at level > mcause.pil
    bnez a0, service_loop    # Loop to service any interrupt.

    # .insn r 0x2b,0,0x40,x1,x30,x0
     .insn r 0x2b,0,0x40,x0,x1,x30
 exit:   
    mret
