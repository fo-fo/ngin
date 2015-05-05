.if .not .defined( NGIN_CAMERA_INC_INCLUDED )
NGIN_CAMERA_INC_INCLUDED = 1

.include "ngin/core.inc"
.include "ngin/arithmetic.inc"

.global __ngin_Camera_initializeView
.global __ngin_Camera_initializeView_position
.macro ngin_Camera_initializeView position
    __ngin_requireParameter {position}, "position"

    ngin_mov32 __ngin_Camera_initializeView_position, {position}

    jsr __ngin_Camera_initializeView
.endmacro

.global __ngin_Camera_move
.global __ngin_Camera_move_amountX
.global __ngin_Camera_move_amountY
.macro ngin_Camera_move amountX, amountY
    __ngin_requireParameter {amountX}, "amountX"
    __ngin_requireParameter {amountY}, "amountY"

    ngin_mov8 __ngin_Camera_move_amountX, {amountX}
    ngin_mov8 __ngin_Camera_move_amountY, {amountY}

    jsr __ngin_Camera_move
.endmacro

.global __ngin_Camera_position
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
    ngin_sub16 \
        { ngin_Vector2_16::x_ * __ngin_Camera_strideSpritePosition + spritePosition }, \
        { ngin_Vector2_16::x_ * __ngin_Camera_strideWorldPosition  + worldPosition }, \
        { ngin_Vector2_16::x_                                      + __ngin_Camera_position }
    ngin_sub16 \
        { ngin_Vector2_16::y_ * __ngin_Camera_strideSpritePosition + spritePosition }, \
        { ngin_Vector2_16::y_ * __ngin_Camera_strideWorldPosition  + worldPosition }, \
        { ngin_Vector2_16::y_                                      + __ngin_Camera_position }

    ngin_add16 \
        { ngin_Vector2_16::x_ * __ngin_Camera_strideSpritePosition + spritePosition }, \
        #ngin_SpriteRenderer_kTopLeftX
    ngin_add16 \
        { ngin_Vector2_16::y_ * __ngin_Camera_strideSpritePosition + spritePosition }, \
        #ngin_SpriteRenderer_kTopLeftY
.endmacro

.endif
