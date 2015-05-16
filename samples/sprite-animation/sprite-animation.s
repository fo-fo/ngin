.include "ngin/ngin.inc"

; From asset importer:
.include "sprites.inc"

ngin_bss animationState: .tag ngin_SpriteAnimator_State

.segment "CODE"

ngin_entryPoint start
.proc start
    ngin_Debug_uploadDebugPalette

    ; Enable NMI so that we can use ngin_waitVBlank.
    ngin_mov8 ppu::ctrl, #ppu::ctrl::kGenerateVblankNmi

    ngin_SpriteAnimator_initialize animationState, #animation_ryu

    loop:
        ngin_ShadowOam_startFrame

        ngin_SpriteRenderer_render \
            animationState + ngin_SpriteAnimator_State::metasprite, \
            #ngin_immediateVector2_16 ngin_SpriteRenderer_kTopLeftX+256/2, \
                                      ngin_SpriteRenderer_kTopLeftY+240/2

        ngin_SpriteAnimator_update animationState

        ngin_ShadowOam_endFrame

        ngin_waitVBlank
        ngin_mov8 ppu::oam::dma, #.hibyte( ngin_ShadowOam_buffer )
        ngin_mov8 ppu::mask, #( ppu::mask::kShowSprites | \
                                ppu::mask::kShowSpritesLeft )
    jmp loop
.endproc
