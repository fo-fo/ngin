.include "ngin/ngin.inc"

; From asset importer:
.include "sprites.inc"
.include "palettes.inc"

.segment "CODE"

ngin_entryPoint start
.proc start
    ngin_Debug_uploadDebugPalette
    jsr uploadPalette
    jsr renderSprites

    ngin_Ppu_pollVBlank
    ngin_ShadowOam_upload
    ngin_mov8 ppu::mask, #( ppu::mask::kShowSprites | \
                            ppu::mask::kShowSpritesLeft )

    jmp *
.endproc

.proc uploadPalette
    ngin_Ppu_pollVBlank

    ngin_Ppu_setAddress #ppu::spritePalette+1
    ngin_copyMemoryToPort #ppu::data, #sprite_pal+1, #3

    rts
.endproc

.proc renderSprites
    ngin_ShadowOam_startFrame

    ngin_SpriteRenderer_render #sprite, \
        #ngin_immVector2_16 ngin_SpriteRenderer_kTopLeftX+256/2-32, \
                            ngin_SpriteRenderer_kTopLeftY+240/2-32

    ngin_SpriteRenderer_render #sprite_H, \
        #ngin_immVector2_16 ngin_SpriteRenderer_kTopLeftX+256/2+32, \
                            ngin_SpriteRenderer_kTopLeftY+240/2-32

    ngin_SpriteRenderer_render #sprite_V, \
        #ngin_immVector2_16 ngin_SpriteRenderer_kTopLeftX+256/2-32, \
                            ngin_SpriteRenderer_kTopLeftY+240/2+32

    ngin_SpriteRenderer_render #sprite_HV, \
        #ngin_immVector2_16 ngin_SpriteRenderer_kTopLeftX+256/2+32, \
                            ngin_SpriteRenderer_kTopLeftY+240/2+32

    ngin_ShadowOam_endFrame

    rts
.endproc
