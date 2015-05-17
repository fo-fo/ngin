.include "ngin/ngin.inc"
.include "assets/maps/maps.inc"

.segment "CODE"

ngin_entryPoint start
.proc start
    ngin_Debug_uploadDebugPalette

    ngin_MapData_load #maps_level1
    ngin_Camera_initializeView #maps_level1::markers::topLeft

    ; Enable NMI so that we can use ngin_waitVBlank.
    ngin_mov8 ppu::ctrl, #ppu::ctrl::kGenerateVblankNmi

    loop:
        jsr update

        ngin_waitVBlank
        ngin_ShadowOam_upload
        ngin_PpuBuffer_upload
        ngin_MapScroller_ppuRegisters
        stx ppu::scroll
        sty ppu::scroll
        ora #( ppu::ctrl::kGenerateVblankNmi | \
               ppu::ctrl::kSpriteSize8x16 )
        sta ppu::ctrl
        ngin_mov8 ppu::mask, #( ppu::mask::kShowBackground     | \
                                ppu::mask::kShowBackgroundLeft | \
                                ppu::mask::kShowSprites        | \
                                ppu::mask::kShowSpritesLeft )
    jmp loop
.endproc

.proc update
    ngin_ShadowOam_startFrame
    ngin_PpuBuffer_startFrame

    ngin_Object_updateAll

    ngin_PpuBuffer_endFrame
    ngin_ShadowOam_endFrame

    rts
.endproc
