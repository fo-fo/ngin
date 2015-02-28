.include "ngin/ngin.inc"

.if .defined( DEBUG )
    .byte "Is debug build"
.else
    .byte "Is NOT debug build"
.endif

ngin_entryPoint start
.proc start
    lda #ppu::mask::kEmphasizeBlue

    loop:
        ldx #15
        wait:
            ngin_pollVBlank
            dex
        ngin_branchIfNotZero wait

        eor #ppu::mask::kGrayscale
        sta ppu::mask
    jmp loop
.endproc
