.include "reset.inc"
.include "ngin/ppu.inc"

.segment "NGIN_CODE"

.proc __ngin_reset
    ; \todo Proper reset code
    lda #0
    sta ppu::ctrl
    sta ppu::mask

    ; __ngin_start is defined in the user application with the ngin_entryPoint
    ; macro.
    .import __ngin_start
    jmp __ngin_start
.endproc
