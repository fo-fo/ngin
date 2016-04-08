.include "ngin/log.inc"
.include "ngin/assert.inc"

; __ngin_defaultIrq is assigned to __ngin_irq from the linker configuration.
; This allows the user to override it with ngin_irqHandler macro.

.export __ngin_defaultIrq
.proc __ngin_defaultIrq
    ; This handler should never be reached (unless there are bugs in user
    ; code.)

    ; \todo Add an "error" logging level...
    ngin_log debug, "[ngin] ERROR: default IRQ handler reached"

    ngin_unreachable
    nop
    jmp *
.endproc
