.include "object-ball.inc"
.include "ngin/ngin.inc"

; \todo Add another object type for testing!

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

kBoundingBoxWidth   = 20
kBoundingBoxHeight  = 20

; 8.8 fixed point acceleration (256 = 1 pixel/frame)
kGravity            = 32

; Maximum number of collisions before the object is destroyed
kMaxCollisions      = 64

; -----------------------------------------------------------------------------

.segment "CODE"

; Generalized routine for moving the object horizontally/vertically.
; This is based on the Y movement, but can also be used for X movement.
ngin_bss delta: .byte 0
ngin_bss bound: .word 0
.macro movement_template y_, x_, fracY_, intY_, boundingBoxY, boundingBoxX, \
        collisionRoutine, collisionRoutineReturnValue
    ; Add the fractional part of velocity to the fractional part of
    ; position.
    clc
    ngin_adc8 { ngin_Object_this fracPosition+ngin_Vector2_8::y_, x }, \
              { ngin_Object_this velocity+ngin_Vector2_8_8::fracY_, x }

    ; The movement delta is now the integer part of velocity, plus the
    ; carry possibly produced by the fractional add.
    lda ngin_Object_this velocity+ngin_Vector2_8_8::intY_, x
    adc #0
    sta delta

    ; Calculate the side of the bounding box of the object.
    bmi movingUp
        ; Moving down.
        ngin_add16   bound, \
                   { ngin_Object_this position+ngin_Vector2_16::y_, x }, \
                     #boundingBoxY
        jmp doneMovingDown
    .local movingUp
    movingUp:
        ngin_mov16 bound, \
                   { ngin_Object_this position+ngin_Vector2_16::y_, x }
    doneMovingDown:

    collisionRoutine bound, \
                     { ngin_Object_this position+ngin_Vector2_16::x_, x }, \
                       #boundingBoxX, \
                       delta

    ; ngin_MapCollision_lineSegmentEjectHorizontal most definitely has
    ; trashed X.
    ldx ngin_Object_current

    ; Check carry to see whether a collision occurred.
    bcc noCollision
        ; Increase number of collisions. If reached a limit, destroy the object.
        lda ngin_Object_this numCollisions, x
        ; We know carry is set, so take advantage of it.
        adc #0
        cmp #kMaxCollisions
        bne dontKill
            ; Kill it off.
            ngin_Object_free x
            ; Return from the object handler.
            pla
            pla
            rts
        .local dontKill
        dontKill:
        sta ngin_Object_this numCollisions, x

        ; Invert velocity on collision.
        ngin_sub16 { ngin_Object_this velocity+ngin_Vector2_8_8::fracY_, x }, \
                     #0, \
                   { ngin_Object_this velocity+ngin_Vector2_8_8::fracY_, x }

        ; Also clear the subpixel part of position.
        ngin_mov8 { ngin_Object_this fracPosition+ngin_Vector2_8::y_, x }, \
                    #0
    noCollision:

    ; Read the return value, re-adjust with the bounding box extents, set as
    ; new position.
    bit delta
    bmi movingUp2
        ; Moving down.
        ngin_add16 { ngin_Object_this position+ngin_Vector2_16::y_, x }, \
                     collisionRoutineReturnValue, \
                     #ngin_signedWord -(boundingBoxY)
        jmp doneMovingDown2
    .local movingUp2
    movingUp2:
        ngin_mov16 { ngin_Object_this position+ngin_Vector2_16::y_, x }, \
                     collisionRoutineReturnValue
    doneMovingDown2:

    rts
.endmacro

ngin_Object_define object_ball
    .proc moveVertical
        movement_template y_, x_, fracY_, intY_, kBoundingBoxHeight-1, \
                          kBoundingBoxWidth, \
                          ngin_MapCollision_lineSegmentEjectVertical, \
                          ngin_MapCollision_lineSegmentEjectVertical_ejectedY
    .endproc

    .proc moveHorizontal
        movement_template x_, y_, fracX_, intX_, kBoundingBoxWidth-1, \
                          kBoundingBoxHeight, \
                          ngin_MapCollision_lineSegmentEjectHorizontal, \
                          ngin_MapCollision_lineSegmentEjectHorizontal_ejectedX
    .endproc

    .proc construct
        ngin_log debug, "object_ball.construct()"

        ngin_mov32 { ngin_Object_this position, x }, \
                     ngin_Object_constructorParameter position

        ; Randomize velocity.
        ngin_Lfsr8_random
        sta ngin_Object_this velocity+ngin_Vector2_8_8::fracX_, x
        ngin_Lfsr8_random
        sta ngin_Object_this velocity+ngin_Vector2_8_8::fracY_, x
        ngin_Lfsr8_random
        and #1
        clc
        adc #1
        sta ngin_Object_this velocity+ngin_Vector2_8_8::intX_, x
        ngin_Lfsr8_random
        and #1
        clc
        adc #1
        sta ngin_Object_this velocity+ngin_Vector2_8_8::intY_, x

        ngin_mov8 { ngin_Object_this numCollisions, x }, #0

        rts
    .endproc

    .proc update
        ; \todo Provide a simple "interface" for moving an object, and applying
        ;       physics, and collisions(?)

        ; Apply gravity to velocity Y.
        ngin_add16 { ngin_Object_this velocity+ngin_Vector2_16::y_, x }, \
                     #kGravity

        ; Move the object horizontally/vertically and check for collisions.
        jsr moveVertical
        jsr moveHorizontal

        ; Render the sprite.
        ; \todo Might want to provide an overload of ngin_SpriteRender_render
        ;       that reads position directly from current object? The macro
        ;       could look up the position based on current object type.

        ; \todo Use temporary local variables for this.
        ngin_bss spritePosition: .tag ngin_Vector2_16
        ngin_Camera_worldToSpritePosition { ngin_Object_this position, x }, \
                                            spritePosition

        ; \note X may be trashed here.

        ngin_SpriteRenderer_render #metasprite, spritePosition

        ; \note X may be trashed here.

        rts
    .endproc
ngin_Object_endDefine

; -----------------------------------------------------------------------------

.segment "CHR_ROM"

objectTilesFirstIndex = .lobyte( */ppu::kBytesPer8x8Tile )
    ngin_tile " ##################     " \
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
              " ##################     " \
              "                        " \
              "                        " \
              "                        " \
              "                        "
