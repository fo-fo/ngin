.include "ngin/ngin.inc"
.include "map-attributes.inc"
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

ngin_bss position:              .tag ngin_Vector2_16_8
ngin_bss spritePosition:        .tag ngin_Vector2_16
ngin_bss controller:            .byte 0

; Non-zero, if overlapping a special tile (MapAttributes::kSpecial)
ngin_bss overlappingSpecial:    .byte 0
ngin_bss frameCount:            .byte 0

ngin_bss prevScannedAttributes: .byte 0


; -----------------------------------------------------------------------------

.segment "CODE"

ngin_entryPoint start
.proc start
    jsr uploadPalette
    jsr uploadNametable

    ngin_MapData_load #maps_collisionTest
    ngin_Camera_initializeView #maps_collisionTest::markers::camera

    ngin_mov16 position+ngin_Vector2_16_8::intX, \
              #ngin_Vector2_16_immX maps_collisionTest::markers::player
    ngin_mov16 position+ngin_Vector2_16_8::intY, \
              #ngin_Vector2_16_immY maps_collisionTest::markers::player
    ngin_mov8 position+ngin_Vector2_16_8::fracX, #0
    ngin_mov8 position+ngin_Vector2_16_8::fracY, #0

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

; Generic movement code template. Variable naming based on the vertical case.
.macro moveObjectGeneric_template kUp, kDown, intY, kBoundingBoxHeight, \
        kBoundingBoxWidth, intX, collisionEject, collisionOverlap, \
        collisionEject_scannedAttributes, collisionEject_ejectedY, \
        collisionOverlap_scannedAttributes, axis
    ngin_bss deltaY: .word 0
    ngin_bss boundY: .word 0
    kMovementAmount = 3

    lda controller
    and #ngin_Controller::kUp | ngin_Controller::kDown
    ngin_branchIfNotZero upOrDown
        ; Neither
        rts
    upOrDown:

    ngin_mov16 deltaY, #0

    .scope
        lda controller
        and #ngin_Controller::kUp
        ngin_branchIfZero notUp
            ngin_mov16 deltaY, #ngin_immFixedPoint8_8 ngin_signed8 -kMovementAmount, 0
            ; No adjustment needed when moving up.
            ngin_mov16 boundY, position + ngin_Vector2_16_8::intY
        notUp:

        lda controller
        and #ngin_Controller::kDown
        ngin_branchIfZero notDown
            ngin_mov16 deltaY, #ngin_immFixedPoint8_8 ngin_signed8 kMovementAmount, 0
            ; Adjust when moving down.
            ngin_add16 boundY, \
                       position + ngin_Vector2_16_8::intY, \
                       #kBoundingBoxHeight-1
        notDown:
    .endscope

    ; Do an ejecting collision test.
    collisionEject \
        boundY, position + ngin_Vector2_16_8::intX, #kBoundingBoxWidth, 1+deltaY

    ; Carry is 1 if collided with a solid. If 0, didn't collide, and the
    ; "scannedAttributes" return value is complete. If did collide, no need
    ; to check for special tiles, because it's not possible that the object
    ; would have moved into a new tile because of limited movement speed.
    bcs gotCollision
        ; Check whether the "special" flag is set in the collided tiles.
        lda collisionEject_scannedAttributes
        and #MapAttributes::kSpecial
        ngin_branchIfZero notSpecial
            ngin_mov8 overlappingSpecial, #ngin_Bool::kTrue
            ngin_jsrRts adjustPositionAndMoveCamera
        notSpecial:
    gotCollision:

    ; Got ejected, or didn't overlap a special tile. Need to check if the
    ; trailing edge exited a special tile.

    ; If we're not overlapping a special tile, we can exit right out (don't have
    ; to check whether the trailing edge exits an overlap.)
    lda overlappingSpecial
    ngin_branchIfZero adjustPositionAndMoveCamera

    ; Calculate the trailing edge in boundY based on the unmodified position.
    jsr calculateTrailingEdge

    ; Adjust the position, ejectedY from lineSegmentEjectVertical is
    ; still valid.
    jsr adjustPositionAndMoveCamera

    ; Do an overlapping collision check to find out which tiles the trailing
    ; edge overlapped before moving.
    collisionOverlap \
        boundY, position + ngin_Vector2_16_8::intX, #kBoundingBoxWidth

    ; If the trailing edge doesn't overlap a special tile (unmodified position),
    ; then it can't leave such tile either, so no further checking is necessary.
    lda collisionOverlap_scannedAttributes
    and #MapAttributes::kSpecial
    ngin_branchIfZero oldNotOverSpecial
        ; Old edge is over the special tile.
        ; Do another check based on the modified position.
        ; \todo Would be enough to modify just the boundY parameter.
        jsr calculateTrailingEdge
        collisionOverlap \
            boundY, position + ngin_Vector2_16_8::intX, #kBoundingBoxWidth

        ; If this one is NOT over the special tile, then the object cannot be
        ; overlapping anymore.
        lda collisionOverlap_scannedAttributes
        and #MapAttributes::kSpecial
        ngin_branchIfNotZero newOverSpecial
            ; At last we know that the object has exited a special tile.
            ngin_mov8 overlappingSpecial, #ngin_Bool::kFalse
        newOverSpecial:
    oldNotOverSpecial:

    rts

    .proc adjustPositionAndMoveCamera
        ; Adjust position based on the ejected coordinate.
        lda 1+deltaY
        bmi movingUp
            ; Moving down
            ngin_add16 position + ngin_Vector2_16_8::intY, \
                       collisionEject_ejectedY, \
                       #ngin_signed16 -(kBoundingBoxHeight-1)
            jmp doneMovingDown
        movingUp:
            ; Moving up
            ngin_mov16 position + ngin_Vector2_16_8::intY, \
                       collisionEject_ejectedY
        doneMovingDown:

        .if axis = 0
            ngin_Camera_move deltaY, #0
        .else
            ngin_Camera_move #0, deltaY
        .endif

        rts
    .endproc

    .proc calculateTrailingEdge
        lda controller
        and #ngin_Controller::kUp
        ngin_branchIfZero notUp
            ngin_add16 boundY, \
                       position + ngin_Vector2_16_8::intY, \
                       #kBoundingBoxHeight-1
        notUp:

        lda controller
        and #ngin_Controller::kDown
        ngin_branchIfZero notDown
            ngin_mov16 boundY, position + ngin_Vector2_16_8::intY
        notDown:

        rts
    .endproc
.endmacro

.proc moveObjectHorizontal
    moveObjectGeneric_template kLeft, kRight, intX, kBoundingBoxWidth, \
        kBoundingBoxHeight, intY, ngin_MapCollision_lineSegmentEjectHorizontal, \
        ngin_MapCollision_lineSegmentOverlapHorizontal, \
        ngin_MapCollision_lineSegmentEjectHorizontal_scannedAttributes, \
        ngin_MapCollision_lineSegmentEjectHorizontal_ejectedX, \
        ngin_MapCollision_lineSegmentOverlapVertical_scannedAttributes, \
        0
.endproc

.proc moveObjectVertical
    moveObjectGeneric_template kUp, kDown, intY, kBoundingBoxHeight, \
        kBoundingBoxWidth, intX, ngin_MapCollision_lineSegmentEjectVertical, \
        ngin_MapCollision_lineSegmentOverlapVertical, \
        ngin_MapCollision_lineSegmentEjectVertical_scannedAttributes, \
        ngin_MapCollision_lineSegmentEjectVertical_ejectedY, \
        ngin_MapCollision_lineSegmentOverlapVertical_scannedAttributes, \
        1
.endproc

.proc doPointCheck
    ; Do an overlapping point collision check, just for testing.
    ngin_MapCollision_pointOverlap \
        position + ngin_Vector2_16_8::intX \
      , position + ngin_Vector2_16_8::intY

    ; Display the scanned attributes, if they changed
    lda ngin_MapCollision_pointOverlap_scannedAttributes
    cmp prevScannedAttributes
    beq didntChange
        ; Changed, print it.
        ngin_log debug, "pointOverlap_scannedAttributes: $%02X", a
        sta prevScannedAttributes
    didntChange:

    rts
.endproc

.proc moveObjects
    jsr moveObjectHorizontal
    jsr moveObjectVertical
    jsr doPointCheck

    rts
.endproc

.proc readControllers
    ngin_Controller_read1
    sta controller

    rts
.endproc

.proc renderSprites
    ngin_ShadowOam_startFrame

    ; Skip on every 2nd frame to indicate overlap with a special tile.
    inc frameCount
    lda overlappingSpecial
    ngin_branchIfZero noSkip
        lda frameCount
        and #1
        ngin_branchIfZero skip
    noSkip:

    ; Adjust the object coordinate for sprite rendering.
    ; Slightly inefficient, since could output directly to the parameter area
    ; of ngin_SpriteRenderer_render.
    ngin_Camera_worldToSpritePosition position, spritePosition

    ngin_SpriteRenderer_render #metasprite, spritePosition

skip:
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

.segment "GRAPHICS"

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
