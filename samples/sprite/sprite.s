.include "ngin/ngin.inc"

ngin_entryPoint start
.proc start
    jsr uploadPalette
    jsr renderSprites

    ngin_pollVBlank
    ngin_mov8 ppu::oam::dma, #.hibyte( ngin_shadowOam )
    ngin_mov8 ppu::mask, #( ppu::mask::kShowSprites | \
                            ppu::mask::kShowSpritesLeft )

    jmp *
.endproc

.proc uploadPalette
    ngin_pollVBlank

    ngin_setPpuAddress #ppu::spritePalette

    ; \todo Symbolic constants for color hues? (separate hue and brightness)
    ngin_mov8 ppu::data, #$F
    lda #$2B
    .repeat 3
        sta ppu::data
    .endrepeat

    ngin_mov8 ppu::data, #$F
    lda #$38
    .repeat 3
        sta ppu::data
    .endrepeat

    rts
.endproc

.proc renderSprites
    ngin_ShadowOam_startFrame

    ngin_SpriteRenderer_render #spriteDefinition, \
                               #ngin_immediateVector2_16 0, 0
    ngin_SpriteRenderer_render #spriteDefinition, \
                               #ngin_immediateVector2_16 -65, 50

    ngin_ShadowOam_endFrame

    rts
.endproc

; -----------------------------------------------------------------------------

.segment "RODATA"

spriteDefinition:
    ; \note Sprite coordinate origin is close to the center of the screen
    ;       because of the adjustments.

    .byte ngin_kSpriteRendererAttribute|%000_000_00 ; Attributes
    .byte ngin_kSpriteRendererAdjustX+0             ; X
    .byte ngin_kSpriteRendererAdjustY+0             ; Y
    .byte 1                                         ; Tile

    .byte ngin_kSpriteRendererAttribute|%000_000_01 ; Attributes
    .byte ngin_kSpriteRendererAdjustX+0             ; X
    .byte ngin_kSpriteRendererAdjustY+8             ; Y
    .byte 1                                         ; Tile

    .byte ngin_kSpriteRendererAttribute|%000_000_00 ; Attributes
    .byte ngin_kSpriteRendererAdjustX+8             ; X
    .byte ngin_kSpriteRendererAdjustY+8             ; Y
    .byte 1                                         ; Tile

    .byte ngin_kSpriteRendererAttribute|%000_000_01 ; Attributes
    .byte ngin_kSpriteRendererAdjustX+8             ; X
    .byte ngin_kSpriteRendererAdjustY+0             ; Y
    .byte 1                                         ; Tile

    .byte ngin_kSpriteDefinitionTerminator

; -----------------------------------------------------------------------------

.segment "CHR_ROM"

.repeat 16
    .byte 0
.endrepeat

.repeat 16
    .byte $FF
.endrepeat
