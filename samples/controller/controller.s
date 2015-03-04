.include "ngin/ngin.inc"

.segment "RODATA"

.proc spriteDefinitionLit
    .byte ngin_kSpriteRendererAttribute|%000_000_00 ; Attributes
    .byte ngin_kSpriteRendererAdjustX+0             ; X
    .byte ngin_kSpriteRendererAdjustY+0             ; Y
    .byte 1                                         ; Tile

    .byte ngin_kSpriteDefinitionTerminator
.endproc

.proc spriteDefinitionDim
    .byte ngin_kSpriteRendererAttribute|%000_000_00 ; Attributes
    .byte ngin_kSpriteRendererAdjustX+0             ; X
    .byte ngin_kSpriteRendererAdjustY+0             ; Y
    .byte 2                                         ; Tile

    .byte ngin_kSpriteDefinitionTerminator
.endproc

.segment "BSS"

controllers: .res 2

; -----------------------------------------------------------------------------

.segment "CODE"

ngin_entryPoint start
.proc start
    jsr uploadPalette

    loop:
        jsr readControllers
        jsr renderSprites

        ngin_pollVBlank
        ngin_mov8 ppu::oam::dma, #.hibyte( ngin_shadowOam )
        ngin_mov8 ppu::mask, #( ppu::mask::kShowSprites | \
                                ppu::mask::kShowSpritesLeft )
    jmp loop
.endproc

.proc uploadPalette
    ngin_pollVBlank

    ; Set all palettes to black.
    ngin_setPpuAddress #ppu::backgroundPalette
    ngin_fillPort #ppu::data, #$F, #32

    ; Set some sprite colors.
    ngin_setPpuAddress #ppu::spritePalette+2
    ngin_mov8 ppu::data, #$10
    ngin_mov8 ppu::data, #$30

    rts
.endproc

.proc readControllers
    ngin_Controller_read1
    sta controllers+0
    ngin_Controller_read2
    sta controllers+1

    rts
.endproc

.proc renderSprites
    ngin_ShadowOam_startFrame

    ; Draw 8 sprites for each bit of each controller in a bloaty manner.
    ; Don't do anything like this in actual games. :)
    .repeat 2, controller
        .repeat 8, i
        .scope
            x_ .set ::ngin_kSpriteRendererTopLeftX + 128 + 12*(i-4)
            y_ .set ::ngin_kSpriteRendererTopLeftY + 120 + 12*(controller-1)

            lda controllers+controller
            and #1 << i
            ngin_branchIfZero bitNotSet
                ngin_SpriteRenderer_render #spriteDefinitionLit, \
                                           #ngin_immediateVector2_16 x_, y_
                jmp next
            bitNotSet:
                ngin_SpriteRenderer_render #spriteDefinitionDim, \
                                           #ngin_immediateVector2_16 x_, y_
            next:
        .endscope
        .endrepeat
    .endrepeat

    ngin_ShadowOam_endFrame

    rts
.endproc

; -----------------------------------------------------------------------------

.segment "CHR_ROM"

.repeat 16
    .byte 0
.endrepeat

.repeat 16
    .byte $FF
.endrepeat

.repeat 8
    .byte $00
.endrepeat
.repeat 8
    .byte $FF
.endrepeat
