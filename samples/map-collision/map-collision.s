.include "ngin/ngin.inc"

.include "assets/maps.inc"

; -----------------------------------------------------------------------------

.segment "RODATA"

.proc metasprite
    ngin_SpriteRenderer_metasprite
        .repeat 9, i
            ngin_SpriteRenderer_sprite 8*(i .mod 3), 8*(i / 3), \
                                       objectTilesFirstIndex+i, \
                                       %000_000_01
        .endrepeat
    ngin_SpriteRenderer_endMetasprite
.endproc

kBoundingBoxWidth  = 20
kBoundingBoxHeight = 20

; -----------------------------------------------------------------------------

ngin_bss position:          .tag ngin_Vector2_16
ngin_bss spritePosition:    .tag ngin_Vector2_16
ngin_bss controller:        .byte 0

; -----------------------------------------------------------------------------

.segment "CODE"

ngin_entryPoint start
.proc start
    jsr uploadPalette
    jsr uploadNametable

    ngin_MapData_load #maps_collisionTest
    ngin_Camera_initializeView #maps_collisionTest::markers::camera

    ngin_mov32 position, #maps_collisionTest::markers::player

    ; Enable NMI so that we can use ngin_Nmi_waitVBlank.
    ngin_mov8 ppu::ctrl, #ppu::ctrl::kGenerateVblankNmi

    loop:
        jsr update
        ngin_Nmi_waitVBlank
        ngin_ShadowOam_upload
        ngin_PpuBuffer_upload
        ngin_MapScroller_ppuRegisters
        stx ppu::scroll
        sty ppu::scroll
        ora #ppu::ctrl::kGenerateVblankNmi
        sta ppu::ctrl
        ngin_mov8 ppu::mask, #( ppu::mask::kShowBackground     | \
                                ppu::mask::kShowBackgroundLeft | \
                                ppu::mask::kShowSprites        | \
                                ppu::mask::kShowSpritesLeft )
    jmp loop
.endproc

.proc update
    ngin_PpuBuffer_startFrame

    jsr readControllers
    jsr moveObjects
    jsr renderSprites

    ngin_PpuBuffer_endFrame

    rts
.endproc

.proc moveObjectHorizontal
    ngin_bss deltaX: .byte 0
    ; X coordinate adjusted with the relative bounding box of the object.
    ngin_bss boundX: .word 0
    kMovementAmount = 3

    lda controller
    and #ngin_Controller::kLeft | ngin_Controller::kRight
    ngin_branchIfNotZero leftOrRight
        ; Neither
        rts
    leftOrRight:

    ngin_mov8 deltaX, #0

    lda controller
    and #ngin_Controller::kLeft
    ngin_branchIfZero notLeft
        ngin_mov8 deltaX, #ngin_signedByte -kMovementAmount
        ; No adjustment needed when moving left.
        ngin_mov16 boundX, position + ngin_Vector2_16::x_
    notLeft:

    lda controller
    and #ngin_Controller::kRight
    ngin_branchIfZero notRight
        ngin_mov8 deltaX, #ngin_signedByte kMovementAmount
        ; Adjust when moving right.
        ngin_add16 boundX, \
                   position + ngin_Vector2_16::x_, \
                   #kBoundingBoxWidth-1
    notRight:

    ngin_MapCollision_lineSegmentEjectHorizontal \
        boundX, position + ngin_Vector2_16::y_, #kBoundingBoxHeight, deltaX

    ; Read the return value, and re-adjust based on the direction of movement.
    ; Need to adjust only if moving right in this case.
    lda deltaX
    bmi movingLeft
        ; Moving right
        ngin_add16 position + ngin_Vector2_16::x_, \
                   ngin_MapCollision_lineSegmentEjectHorizontal_ejectedX, \
                   #ngin_signedWord -(kBoundingBoxWidth-1)
        jmp doneMovingRight
    movingLeft:
        ; Moving left
        ngin_mov16 position + ngin_Vector2_16::x_, \
                   ngin_MapCollision_lineSegmentEjectHorizontal_ejectedX
    doneMovingRight:

    ngin_Camera_move deltaX, #0

    rts
.endproc

; Copy-pasta from moveObjectHorizontal with slight modifications.
; Should be combined, but can't bother for now.
.proc moveObjectVertical
    ngin_bss deltaY: .byte 0
    ngin_bss boundY: .word 0
    kMovementAmount = 3

    lda controller
    and #ngin_Controller::kUp | ngin_Controller::kDown
    ngin_branchIfNotZero upOrDown
        ; Neither
        rts
    upOrDown:

    ngin_mov8 deltaY, #0

    lda controller
    and #ngin_Controller::kUp
    ngin_branchIfZero notUp
        ngin_mov8 deltaY, #ngin_signedByte -kMovementAmount
        ; No adjustment needed when moving up.
        ngin_mov16 boundY, position + ngin_Vector2_16::y_
    notUp:

    lda controller
    and #ngin_Controller::kDown
    ngin_branchIfZero notDown
        ngin_mov8 deltaY, #ngin_signedByte kMovementAmount
        ; Adjust when moving down.
        ngin_add16 boundY, \
                   position + ngin_Vector2_16::y_, \
                   #kBoundingBoxHeight-1
    notDown:

    ngin_MapCollision_lineSegmentEjectVertical \
        boundY, position + ngin_Vector2_16::x_, #kBoundingBoxWidth, deltaY

    lda deltaY
    bmi movingUp
        ; Moving down
        ngin_add16 position + ngin_Vector2_16::y_, \
                   ngin_MapCollision_lineSegmentEjectVertical_ejectedY, \
                   #ngin_signedWord -(kBoundingBoxHeight-1)
        jmp doneMovingDown
    movingUp:
        ; Moving up
        ngin_mov16 position + ngin_Vector2_16::y_, \
                   ngin_MapCollision_lineSegmentEjectVertical_ejectedY
    doneMovingDown:

    ngin_Camera_move #0, deltaY

    rts
.endproc

.proc moveObjects
    jsr moveObjectHorizontal
    jsr moveObjectVertical

    rts
.endproc

.proc readControllers
    ngin_Controller_read1
    sta controller

    rts
.endproc

.proc renderSprites
    ngin_ShadowOam_startFrame

    ; Adjust the object coordinate for sprite rendering.
    ; Slightly inefficient, since could output directly to the parameter area
    ; of ngin_SpriteRenderer_render.
    ngin_Camera_worldToSpritePosition position, spritePosition

    ngin_SpriteRenderer_render #metasprite, spritePosition

    ngin_ShadowOam_endFrame

    rts
.endproc

.proc uploadPalette
    ngin_Ppu_pollVBlank

    ; Set all palettes to black.
    ngin_Ppu_setAddress #ppu::backgroundPalette
    ngin_fillPort #ppu::data, #$F, #32

    ngin_pushSeg "RODATA"
    .proc palette
        .byte $0F, $06, $16, $26
        .byte $0F, $09, $19, $29
        .byte $0F, $02, $12, $22
        .byte $0F, $04, $14, $24
    .endproc
    ngin_popSeg

    ngin_Ppu_setAddress #ppu::backgroundPalette
    ngin_copyMemoryToPort #ppu::data, #palette, #.sizeof( palette )
    ngin_copyMemoryToPort #ppu::data, #palette, #.sizeof( palette )

    rts
.endproc

.proc uploadNametable
    ngin_Ppu_setAddress #ppu::nametable0
    ngin_fillPort #ppu::data, #0, #4*1024

    rts
.endproc

; -----------------------------------------------------------------------------

.segment "CHR_ROM"

objectTilesFirstIndex = .lobyte( */ppu::kBytesPer8x8Tile )
    ngin_tile "####################    " \
              "####################    " \
              "####################    " \
              "####################    " \
              "####            ####    " \
              "####            ####    " \
              "####            ####    " \
              "####            ####    " \
              "####            ####    " \
              "####            ####    " \
              "####            ####    " \
              "####            ####    " \
              "####            ####    " \
              "####            ####    " \
              "####            ####    " \
              "####            ####    " \
              "####################    " \
              "####################    " \
              "####################    " \
              "####################    " \
              "                        " \
              "                        " \
              "                        " \
              "                        "
