.include "ngin/ngin.inc"

.segment "RODATA"

.proc palette
    .incbin "data/startropics.pal"
.endproc

.proc nametable
    .incbin "data/startropics.nam"
.endproc

; -----------------------------------------------------------------------------

ngin_entryPoint start
.proc start
    jsr uploadPalette
    jsr uploadNametable

    ngin_pollVBlank
    ngin_mov8 ppu::scroll, #0
    ngin_mov8 ppu::scroll, #0
    ngin_mov8 ppu::ctrl, #0
    ngin_mov8 ppu::mask, #ppu::mask::kShowBackground

    jmp *
.endproc

.proc uploadPalette
    ngin_pollVBlank

    ngin_setPpuAddress #ppu::backgroundPalette
    ngin_copyMemoryToPort #ppu::data, #palette, #.sizeof( palette )

    rts
.endproc

.proc uploadNametable
    ngin_setPpuAddress #ppu::nametable0
    ngin_copyMemoryToPort #ppu::data, #nametable, #.sizeof( nametable )

    rts
.endproc

; -----------------------------------------------------------------------------

.segment "CHR_ROM"

    .incbin "data/startropics.chr"
