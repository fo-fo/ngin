.if .not .defined( NGIN_CAMERA_INC_INCLUDED )
NGIN_CAMERA_INC_INCLUDED = 1

.include "ngin/core.inc"
.include "ngin/arithmetic.inc"

; Camera position in world space
; Type: ngin_Vector2_16_8
.global ngin_Camera_position

.global   __ngin_Camera_initializeView
.globalzp __ngin_Camera_initializeView_position
.macro ngin_Camera_initializeView position
    __ngin_requireParameter {position}, "position"

    ngin_mov32 __ngin_Camera_initializeView_position, {position}

    jsr __ngin_Camera_initializeView
.endmacro

.global   __ngin_Camera_move
.globalzp __ngin_Camera_move_amountX
.globalzp __ngin_Camera_move_amountY
.macro ngin_Camera_move amountX, amountY
    __ngin_requireParameter {amountX}, "amountX"
    __ngin_requireParameter {amountY}, "amountY"

    ; 8.8 fixed point
    ngin_mov16 __ngin_Camera_move_amountX, {amountX}
    ngin_mov16 __ngin_Camera_move_amountY, {amountY}

    jsr __ngin_Camera_move
.endmacro

.macro __ngin_Camera_worldToSpritePosition_template comp, worldPosition, \
        spritePosition

    ; Subtract camera position (16.8 fixed point) from world position
    ; (16.8 fixed point), return a 16-bit result (LSB discarded).

    lda ~~( ngin_Vector2_16_8::comp + 0) * __ngin_Camera_strideWorldPosition + \
        worldPosition
    sec
    sbc ngin_Camera_position + ngin_Vector2_16_8::comp+0
    ; \note LSB discarded.

    .repeat 2, i
        lda ~~( ngin_Vector2_16_8::comp + i + 1 ) \
            * __ngin_Camera_strideWorldPosition + worldPosition
        sbc ngin_Camera_position + ngin_Vector2_16_8::comp+i+1
        sta ~~( ngin_Vector2_16::comp + i + 0 ) * \
            __ngin_Camera_strideSpritePosition + spritePosition
    .endrepeat
.endmacro

; Converts 16.8 fixed point coordinates from world to sprite (view) space.
; The result is ngin_Vector2_16.
.macro ngin_Camera_worldToSpritePosition worldPosition, spritePosition
    ; Convert world position to sprite position:
    ;   1) adjust the camera position to (0, 0) by subtracting $8000
    ;   2) adjust the world position to (0, 0) by subtracting $8000
    ;   3) subtract camera position from world position to get the sprite
    ;      position relative to the top left corner of the camera
    ;   4) add ngin_SpriteRenderer_kTopLeftX/Y to the result to bring the
    ;      result to the coordinate space of SpriteRenderer
    ; \note Some of the subtractions of $8000 cancel each other out.

    ; \todo In real world scenarios it would probably be better to calculate
    ;       the 16-bit displacement once based on camera position of the current
    ;       frame, and use it for all objects after that. It could probably
    ;       be done in ngin_Camera_move, since we don't expect that to be called
    ;       multiple times per frame.

    __ngin_getOperandStride {worldPosition},  __ngin_Camera_strideWorldPosition
    __ngin_getOperandStride {spritePosition}, __ngin_Camera_strideSpritePosition

    ; \todo This function doesn't work with immediate arguments right now,
    ;       because X/Y offset is always added (fortunately it at least
    ;       generates an error)

    __ngin_Camera_worldToSpritePosition_template \
        x_, {worldPosition}, {spritePosition}
    __ngin_Camera_worldToSpritePosition_template \
        y_, {worldPosition}, {spritePosition}

    ; \todo Could round here by using a 24-bit intermediate result.
    ngin_add16 \
        { ngin_Vector2_16::x_ * __ngin_Camera_strideSpritePosition + spritePosition }, \
        #ngin_SpriteRenderer_kTopLeftX
    ngin_add16 \
        { ngin_Vector2_16::y_ * __ngin_Camera_strideSpritePosition + spritePosition }, \
        #ngin_SpriteRenderer_kTopLeftY
.endmacro

.endif
