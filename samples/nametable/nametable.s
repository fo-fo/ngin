.include "ngin/ngin.inc"

.segment "RODATA"

ngin_scoped palette,   .incbin "data/startropics.pal"
ngin_scoped nametable, .incbin "data/startropics.nam"

; -----------------------------------------------------------------------------

.segment "CODE"

ngin_entryPoint start
.proc start
    jsr uploadPalette
    jsr uploadNametable

    ngin_Ppu_pollVBlank
    ngin_mov8 ppu::scroll, #0
    ngin_mov8 ppu::scroll, #0
    ngin_mov8 ppu::ctrl, #0
    ngin_mov8 ppu::mask, #ppu::mask::kShowBackground

    jmp *
.endproc

.proc uploadPalette
    ngin_Ppu_pollVBlank

    ngin_Ppu_setAddress #ppu::backgroundPalette
    ngin_copyMemoryToPort #ppu::data, #palette, #.sizeof( palette )

    rts
.endproc

.proc uploadNametable
    ngin_Ppu_setAddress #ppu::nametable0
    ngin_copyMemoryToPort #ppu::data, #nametable, #.sizeof( nametable )

    rts
.endproc

; -----------------------------------------------------------------------------

.segment "CHR_ROM"

    .incbin "data/startropics.chr"
