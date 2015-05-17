.include "ngin/ngin.inc"

; From asset importer:
.include "sprites.inc"

.segment "CODE"

ngin_entryPoint start
.proc start
    ngin_Debug_uploadDebugPalette
    jsr renderSprites

    ngin_Ppu_pollVBlank
    ngin_ShadowOam_upload
    ngin_mov8 ppu::mask, #( ppu::mask::kShowSprites | \
                            ppu::mask::kShowSpritesLeft )

    jmp *
.endproc

.proc renderSprites
    ngin_ShadowOam_startFrame

    ngin_SpriteRenderer_render #sprite, \
        #ngin_immediateVector2_16 ngin_SpriteRenderer_kTopLeftX+256/2, \
                                  ngin_SpriteRenderer_kTopLeftY+240/2

    ngin_ShadowOam_endFrame

    rts
.endproc
