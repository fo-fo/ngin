.include "ngin/ngin.inc"

.assert .defined( NGIN_MAPPER_FME_7 ), error, "FME-7 define not set"

; -------------------------------------------------------------------------

.segment "CODE_3" ; Just a random bank.

.proc bankedCode
    ngin_Debug_uploadDebugPalette

    ; Clear nametable.
    ngin_Ppu_setAddress #ppu::nametable0
    ngin_fillPort #ppu::data, #0, #32*30+64

    loop:
        ngin_Ppu_pollVBlank

        ; Enable rendering.
        lda #0
        sta ppu::scroll
        sta ppu::scroll
        sta ppu::ctrl
        ngin_mov8 ppu::mask, #( ppu::mask::kShowBackground     | \
                                ppu::mask::kShowBackgroundLeft )

        ; Switch to next CHR bank.
        
        lda #0 ; CHR Bank 0 ($0000)
        sta $8000 ; Command Register

        ngin_bss chrBank: .byte 0
        lda chrBank
        lsr
        lsr
        sta $A000 ; Parameter Register

        inc chrBank
    jmp loop
.endproc

; -------------------------------------------------------------------------

; Put random crap in CHR banks.
.repeat 64, i
    .segment .sprintf( "CHR_ROM_%d", i )
    .repeat 16
        .byte i
    .endrepeat
.endrepeat

; -------------------------------------------------------------------------

.segment "CODE"

ngin_entryPoint start
.proc start
    ; \todo Defines in Ngin for the FME-7 registers/etc.
    lda #$9 ; PRG Bank 1 ($8000)
    sta $8000 ; Command Register

    ; \todo Macro in Ngin to make it easier to get the bank byte?
    ; \todo Embed desired location of the code (e.g. 8000 or A000) in the
    ;       bank word? (3 bits is enough.)
    lda #.lobyte( .bank( bankedCode ) )
    sta $A000 ; Parameter Register

    jmp bankedCode
.endproc
