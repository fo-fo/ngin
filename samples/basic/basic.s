.include "ngin/ngin.inc"

.if .defined( DEBUG )
    .byte "Is debug build"
.else
    .byte "Is NOT debug build"
.endif

ngin_entryPoint start
.proc start
    lda #0

    inf:
        eor #ppu::mask::kGrayscaleOn
        sta ppu::mask
    jmp inf
.endproc
