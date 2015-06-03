.if .not .defined( NGIN_SAMPLE_PLATFORMER_COMMON_INC_INCLUDED )
NGIN_SAMPLE_PLATFORMER_COMMON_INC_INCLUDED = 1

; 8.8 fixed point acceleration (256 = 1 pixel/frame)
kGravity = 32

; Generalized routine for moving the object horizontally/vertically.
; This is based on the Y movement, but can also be used for X movement.
; \todo Provide something like this in the engine.
.macro movement_template y_, x_, fracY, intY, intX, boundingBoxYTop, \
        boundingBoxYBottom, boundingBoxXLeft, boundingBoxXRight, \
        collisionRoutine, collisionRoutineReturnValue, collisionResponse

    ; \todo Use temporaries!
    ngin_bss delta:         .byte 0
    ngin_bss boundY:        .word 0
    ngin_bss boundX:        .word 0
    ngin_bss newFracPos:    .byte 0

    ; Add the fractional part of velocity to the fractional part of
    ; position.
    clc
    ngin_adc8 { ngin_Object_this position+ngin_Vector2_16_8::fracY, x }, \
              { ngin_Object_this velocity+ngin_Vector2_8_8::fracY, x }

    ; Store the new fractional position, since it's needed later.
    sta newFracPos

    ; The movement delta is now the integer part of velocity, plus the
    ; carry possibly produced by the fractional add.
    lda ngin_Object_this velocity+ngin_Vector2_8_8::intY, x
    adc #0
    sta delta

    ; Calculate the side of the bounding box of the object.
    bmi movingUp
        ; Moving down.
        ngin_add16 boundY, \
                 { ngin_Object_this position+ngin_Vector2_16_8::intY, x }, \
                   #ngin_signed16 boundingBoxYBottom

        ; Add one more pixel to the bounding box if we're not aligned to the
        ; pixel grid. This way the collision will occur even if only a subpixel
        ; portion of the object's bounding box collides with the solid.
        ; \note boundY is the unmodified coordinate, so by increasing the delta
        ;       we're effectively extending the bounding box.
        lda newFracPos
        ngin_branchIfZero newFracPosZero
            ; newFracPos is not zero.
            inc delta
        .local newFracPosZero
        newFracPosZero:

        jmp doneMovingDown
    .local movingUp
    movingUp:
        ; Moving up.
        ngin_add16 boundY, \
                 { ngin_Object_this position+ngin_Vector2_16_8::intY, x }, \
                   #ngin_signed16 boundingBoxYTop
    .local doneMovingDown
    doneMovingDown:

    .local boundingBoxWidth
    boundingBoxWidth = (boundingBoxXRight) - (boundingBoxXLeft) + 1

    ; Need to calculate the left side of the bounding box, because
    ; the collision routine takes the width.
    ; \todo Should we account for subpixel positions here also?
    ngin_add16 boundX, \
             { ngin_Object_this position+ngin_Vector2_16_8::intX, x }, \
               #ngin_signed16 boundingBoxXLeft

    collisionRoutine boundY, \
                     boundX, \
                     #boundingBoxWidth, \
                     delta

    ; collisionRoutine most definitely has trashed X.
    ldx ngin_Object_current

    ; Check carry to see whether a collision occurred.
    bcc noCollision
        collisionResponse y_, fracY
        jmp doneCollision
    .local noCollision
    noCollision:
        ; No collision. If we added 1 to the bottom/right bounding box
        ; on routine call, we need to adjust for that now in the results.
        ; \note No need to adjust when a collision occurs, because the ejected
        ;       coordinate is always pixel grid aligned.
        bit delta
        bmi movingUp3
            lda newFracPos
            ngin_branchIfZero newFracPosZero2
                ; newFracPos is non-zero.
                ngin_sub16 collisionRoutineReturnValue, #1
            .local newFracPosZero2
            newFracPosZero2:
        .local movingUp3
        movingUp3:
    .local doneCollision
    doneCollision:

    ; Read the return value, re-adjust with the bounding box extents, set as
    ; new position.
    bit delta
    bmi movingUp2
        ; Moving down.
        ngin_add16 { ngin_Object_this position+ngin_Vector2_16_8::intY, x }, \
                     collisionRoutineReturnValue, \
                     #ngin_signed16 -(boundingBoxYBottom)
        jmp doneMovingDown2
    .local movingUp2
    movingUp2:
        ; Moving up.
        ngin_add16 { ngin_Object_this position+ngin_Vector2_16_8::intY, x }, \
                     collisionRoutineReturnValue, \
                     #ngin_signed16 -(boundingBoxYTop)
    .local doneMovingDown2
    doneMovingDown2:

    rts
.endmacro

; Macro for calculating the bounding box of an object based on its position
; and the the bounding box relative to position.
; position: ngin_Vector2_16_8 (could support Vector2_16 if intX/intY is added in
;                              it as an union)
; boundingBox: relative bounds (ngin_immBoundingBox8)
; destination: ngin_BoundingBox16
; \todo This should be moved into the engine in some form or another.
.macro calculateBoundingBox_template destination, position, boundingBox
    ; \todo Don't use an implementation detail. :) And if moved to engine, use
    ;       better namespacing.
    __ngin_getOperandStride {destination}, __strideDestination
    __ngin_getOperandStride {position}, __stridePosition

    ; "boundingBox" has to be an immediate currently. Probably it's never going
    ; to be a non-immediate.
    __ngin_requireImmediate {boundingBox}, "boundingBox"

    ; Strip the immediate "#".
    .local boundingBoxStripped
    boundingBoxStripped = .right( .tcount( {boundingBox} ) - 1, {boundingBox} )

    ; \note Currently subpixel position is ignored (= floor). Could round
    ;       as well, but slightly slower.

    ngin_add16 \
        { ngin_BoundingBox16::left * __strideDestination + destination }, \
        { ngin_Vector2_16_8::intX * __stridePosition + position }, \
        #ngin_signExtend8 ngin_BoundingBox8_immLeft boundingBoxStripped

    ngin_add16 \
        { ngin_BoundingBox16::top * __strideDestination + destination }, \
        { ngin_Vector2_16_8::intY * __stridePosition + position }, \
        #ngin_signExtend8 ngin_BoundingBox8_immTop boundingBoxStripped

    ngin_add16 \
        { ngin_BoundingBox16::right * __strideDestination + destination }, \
        { ngin_Vector2_16_8::intX * __stridePosition + position }, \
        #ngin_signExtend8 ngin_BoundingBox8_immRight boundingBoxStripped

    ngin_add16 \
        { ngin_BoundingBox16::bottom * __strideDestination + destination }, \
        { ngin_Vector2_16_8::intY * __stridePosition + position }, \
        #ngin_signExtend8 ngin_BoundingBox8_immBottom boundingBoxStripped

    rts
.endmacro

.endif
