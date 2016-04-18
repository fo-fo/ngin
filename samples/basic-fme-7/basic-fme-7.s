.include "ngin/ngin.inc"

.assert .defined( NGIN_MAPPER_FME_7 ), error, "FME-7 define not set"

ngin_bss chrBank: .byte 0

; -------------------------------------------------------------------------

.segment "CODE_3_8000" ; Just a random bank.

.proc bankedCode
    ngin_Debug_uploadDebugPalette

    cli ; Enable IRQs.

    ; Clear nametable.
    ngin_Ppu_setAddress #ppu::nametable0
    ngin_fillPort #ppu::data, #0, #32*30+64

    ngin_mov8 ppu::ctrl, #ppu::ctrl::kGenerateVblankNmi
    loop:
        ngin_Nmi_waitVBlank

        ; Set up IRQ.
        kIrqCount = 341*(21+120)/3
        ngin_Fme_7_write #ngin_Fme_7::kIrqCounterLo, #.lobyte( kIrqCount )
        ngin_Fme_7_write #ngin_Fme_7::kIrqCounterHi, #.hibyte( kIrqCount )
        ngin_Fme_7_write #ngin_Fme_7::kIrqControl, #( \
            ngin_Fme_7::irq::kEnabled | \
            ngin_Fme_7::irq::kCounterEnabled )

        ; Enable rendering.
        lda #0
        sta ppu::scroll
        sta ppu::scroll
        lda #( ppu::ctrl::kGenerateVblankNmi )
        sta ppu::ctrl
        ngin_mov8 ppu::mask, #( ppu::mask::kShowBackground     | \
                                ppu::mask::kShowBackgroundLeft )

        ; Switch to next CHR bank.
        ngin_mov8 ngin_Fme_7::command, #ngin_Fme_7::kChr0_0000
        lda chrBank
        ngin_lsr 2
        sta ngin_Fme_7::parameter

        inc chrBank
    jmp loop
.endproc

; -------------------------------------------------------------------------

; Put random crap in CHR banks.
.repeat 64, i
    .segment .sprintf( "GRAPHICS_%d_0000", i )
    .repeat 16
        .byte i
    .endrepeat
.endrepeat

; -------------------------------------------------------------------------

.segment "CODE"

ngin_entryPoint start
.proc start
    ; \todo Embed desired location of the code (e.g. 8000 or A000) in the
    ;       bank word? (3 bits is enough.)
    ngin_Fme_7_write #ngin_Fme_7::kPrg1_8000, #ngin_bank bankedCode

    jmp bankedCode
.endproc

ngin_irqHandler irq
.proc irq
    pha
    txa
    pha

    ; Set grayscale and some emphasis to indicate the IRQ.
    ngin_mov8 ppu::mask, #( ppu::mask::kShowBackground     | \
                            ppu::mask::kShowBackgroundLeft | \
                            ppu::mask::kGrayscale | \
                            ppu::mask::kEmphasizeBlue )

    ; Ack and disable IRQ and counting.
    ngin_Fme_7_write #ngin_Fme_7::kIrqControl, #0

    pla
    tax
    pla

    rti
.endproc
