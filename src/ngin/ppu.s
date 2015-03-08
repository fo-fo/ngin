.include "ngin/ppu.inc"

.segment "NGIN_CODE"

.proc __ngin_pollVBlank
    bit ppu::status

    loop:
        bit ppu::status
    bpl loop

    rts
.endproc
