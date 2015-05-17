.include "ngin/debug.inc"
.include "ngin/ppu.inc"
.include "ngin/memory.inc"

.segment "NGIN_CODE"

.proc __ngin_Debug_uploadDebugPalette
    ngin_pushSeg "NGIN_RODATA"
    .proc palette
        .byte $0F, $06, $16, $26
        .byte $0F, $09, $19, $29
        .byte $0F, $02, $12, $22
        .byte $0F, $04, $14, $24

        .byte $0F, $07, $17, $27
        .byte $0F, $0B, $1B, $2B
        .byte $0F, $03, $13, $23
        .byte $0F, $05, $15, $25
    .endproc
    ngin_popSeg

    ; Avoid palette artifacts by polling for vblank.
    ngin_Ppu_pollVBlank

    ngin_Ppu_setAddress #ppu::backgroundPalette
    ngin_copyMemoryToPort #ppu::data, #palette, #.sizeof( palette )

    rts
.endproc
