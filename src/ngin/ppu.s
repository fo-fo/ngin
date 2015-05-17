.include "ngin/ppu.inc"

.segment "NGIN_CODE"

.proc __ngin_Ppu_pollVBlank
    bit ppu::status

    loop:
        bit ppu::status
    bpl loop

    rts
.endproc
