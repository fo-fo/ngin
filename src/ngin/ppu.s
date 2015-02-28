.include "ngin/ppu.inc"

.proc __ngin_pollVBlank
    bit ppu::status

    loop:
        bit ppu::status
    bpl loop

    rts
.endproc
