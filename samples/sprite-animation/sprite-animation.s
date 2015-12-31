; This sample demonstrates how to import and display a sprite animation.
; It also shows how to trigger an animation frame callback at a specific
; frame.

.include "ngin/ngin.inc"

; From asset importer:
.include "sprites.inc"

ngin_bss animationState: .tag ngin_SpriteAnimator_State
ngin_bss counter: .byte 0

.segment "CODE"

ngin_entryPoint start
.proc start
    ngin_Debug_uploadDebugPalette

    ; Enable NMI so that we can use ngin_Nmi_waitVBlank.
    ngin_mov8 ppu::ctrl, #ppu::ctrl::kGenerateVblankNmi

    ngin_SpriteAnimator_initialize animationState, #animation_ryu

    loop:
        ngin_ShadowOam_startFrame

        ngin_SpriteRenderer_render \
            animationState + ngin_SpriteAnimator_State::metasprite, \
            #ngin_immVector2_16 ngin_SpriteRenderer_kTopLeftX+256/2, \
                                ngin_SpriteRenderer_kTopLeftY+240/2

        ngin_ShadowOam_endFrame

        ngin_Nmi_waitVBlank
        ngin_ShadowOam_upload
        jsr updatePalette
        ngin_mov8 ppu::mask, #( ppu::mask::kShowSprites | \
                                ppu::mask::kShowSpritesLeft )

        ngin_SpriteAnimator_update animationState
    jmp loop
.endproc

.proc updatePalette
    ngin_Ppu_setAddress #ppu::backgroundPalette
    lda counter
    and #%111
    ngin_asl 2
    sta ppu::data
    rts
.endproc

; This callback is called when the sprite animation reaches frame 1 (0-based).
; It's defined in CMakeLists.txt with ngin_spriteAssetEvent()
.export onFrame1
.proc onFrame1
    inc counter
    rts
.endproc
