.include "ngin/ngin.inc"

.segment "RODATA"

.proc metaspriteLit
    ngin_SpriteRenderer_metasprite
        ngin_SpriteRenderer_sprite 0, 0, whiteTile, %000_000_00
    ngin_SpriteRenderer_endMetasprite
.endproc

.proc metaspriteDim
    ngin_SpriteRenderer_metasprite
        ngin_SpriteRenderer_sprite 0, 0, grayTile, %000_000_00
    ngin_SpriteRenderer_endMetasprite
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

        ngin_Ppu_pollVBlank
        ngin_ShadowOam_upload
        ngin_mov8 ppu::mask, #( ppu::mask::kShowSprites | \
                                ppu::mask::kShowSpritesLeft )
    jmp loop
.endproc

.proc uploadPalette
    ngin_Ppu_pollVBlank

    ; Set all palettes to black.
    ngin_Ppu_setAddress #ppu::backgroundPalette
    ngin_fillPort #ppu::data, #$F, #32

    ; Set some sprite colors.
    ngin_Ppu_setAddress #ppu::spritePalette+2
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
            x_ .set ::ngin_SpriteRenderer_kTopLeftX + 128 + 12*(i-4)
            y_ .set ::ngin_SpriteRenderer_kTopLeftY + 120 + 12*(controller-1)

            lda controllers+controller
            and #1 << i
            ngin_branchIfZero bitNotSet
                ngin_SpriteRenderer_render #metaspriteLit, \
                                           #ngin_immVector2_16 x_, y_
                jmp next
            bitNotSet:
                ngin_SpriteRenderer_render #metaspriteDim, \
                                           #ngin_immVector2_16 x_, y_
            next:
        .endscope
        .endrepeat
    .endrepeat

    ngin_ShadowOam_endFrame

    rts
.endproc

; -----------------------------------------------------------------------------

.segment "GRAPHICS"

blackTile = .lobyte( */ppu::kBytesPer8x8Tile )
    ngin_tile "        " \
              "        " \
              "        " \
              "        " \
              "        " \
              "        " \
              "        " \
              "        "

whiteTile = .lobyte( */ppu::kBytesPer8x8Tile )
    ngin_tile "########" \
              "########" \
              "########" \
              "########" \
              "########" \
              "########" \
              "########" \
              "########"

grayTile = .lobyte( */ppu::kBytesPer8x8Tile )
    ngin_tile "::::::::" \
              "::::::::" \
              "::::::::" \
              "::::::::" \
              "::::::::" \
              "::::::::" \
              "::::::::" \
              "::::::::"
