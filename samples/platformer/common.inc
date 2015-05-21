.if .not .defined( NGIN_SAMPLE_PLATFORMER_COMMON_INC_INCLUDED )
NGIN_SAMPLE_PLATFORMER_COMMON_INC_INCLUDED = 1

; 8.8 fixed point acceleration (256 = 1 pixel/frame)
kGravity = 32

; Generalized routine for moving the object horizontally/vertically.
; This is based on the Y movement, but can also be used for X movement.
; \todo Provide something like this in the engine.
.macro movement_template y_, x_, fracY_, intY_, boundingBoxYTop, \
        boundingBoxYBottom, boundingBoxXLeft, boundingBoxXRight, \
        collisionRoutine, collisionRoutineReturnValue, collisionResponse

    ; \todo Use temporaries!
    ngin_bss delta:  .byte 0
    ngin_bss boundY: .word 0
    ngin_bss boundX: .word 0

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
        ngin_add16 boundY, \
                 { ngin_Object_this position+ngin_Vector2_16::y_, x }, \
                   #ngin_signedWord boundingBoxYBottom
        jmp doneMovingDown
    .local movingUp
    movingUp:
        ; Moving up.
        ngin_add16 boundY, \
                 { ngin_Object_this position+ngin_Vector2_16::y_, x }, \
                   #ngin_signedWord boundingBoxYTop
    .local doneMovingDown
    doneMovingDown:

    .local boundingBoxWidth
    boundingBoxWidth = (boundingBoxXRight) - (boundingBoxXLeft) + 1

    ; Need to calculate the left side of the bounding box, because
    ; the collision routine takes the width.
    ngin_add16 boundX, \
             { ngin_Object_this position+ngin_Vector2_16::x_, x }, \
               #ngin_signedWord boundingBoxXLeft

    collisionRoutine boundY, \
                     boundX, \
                     #boundingBoxWidth, \
                     delta

    ; collisionRoutine most definitely has trashed X.
    ldx ngin_Object_current

    ; Check carry to see whether a collision occurred.
    bcc noCollision
        collisionResponse y_, fracY_
    .local noCollision
    noCollision:

    ; Read the return value, re-adjust with the bounding box extents, set as
    ; new position.
    bit delta
    bmi movingUp2
        ; Moving down.
        ngin_add16 { ngin_Object_this position+ngin_Vector2_16::y_, x }, \
                     collisionRoutineReturnValue, \
                     #ngin_signedWord -(boundingBoxYBottom)
        jmp doneMovingDown2
    .local movingUp2
    movingUp2:
        ; Moving up.
        ngin_add16 { ngin_Object_this position+ngin_Vector2_16::y_, x }, \
                     collisionRoutineReturnValue, \
                     #ngin_signedWord -(boundingBoxYTop)
    .local doneMovingDown2
    doneMovingDown2:

    rts
.endmacro

.endif
