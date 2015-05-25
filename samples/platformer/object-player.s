.include "object-player.inc"
.include "common.inc"
.include "assets/sprites/sprites.inc"

; -----------------------------------------------------------------------------

; All are inclusive:
kBoundingBoxTop    = -30
kBoundingBoxBottom = 0
kBoundingBoxLeft   = -8
kBoundingBoxRight  = 8

; 8.8 fixed point
kHorizontalMoveVelocity = 256+128
kJumpVelocity           = 1000

kAllowJumpInAir         = ngin_Bool::kFalse

; -----------------------------------------------------------------------------

.segment "CODE"

ngin_bss playerId: .byte 0

ngin_Object_define object_Player
    .proc onConstruct
        ngin_log debug, "object_Player.construct()"

        stx playerId

        ; Take note of the spawn index, because it can be used to reset the
        ; spawn flag later on if needed.
        ngin_mov8 { ngin_Object_this spawnIndex, x }, \
                    ngin_ObjectSpawner_spawnIndex

        ; Initialize position from constructor parameters. Have to set X and Y
        ; separately because the integer parts are not contiguous in memory.
        ngin_mov16 { ngin_Object_this position+ngin_Vector2_16_8::intX, x }, \
            ngin_Object_constructorParameter position+ngin_Vector2_16::x_
        ngin_mov16 { ngin_Object_this position+ngin_Vector2_16_8::intY, x }, \
            ngin_Object_constructorParameter position+ngin_Vector2_16::y_

        ; Set the fractional part to 0.
        ngin_mov8 { ngin_Object_this position+ngin_Vector2_16_8::fracX, x }, #0
        ngin_mov8 { ngin_Object_this position+ngin_Vector2_16_8::fracY, x }, #0

        ; Initialize velocity to 0.
        ngin_mov32 { ngin_Object_this velocity, x }, #0

        ; Initialize animation.
        ngin_SpriteAnimator_initialize { ngin_Object_this animationState, x }, \
                                         #animation_player

        rts
    .endproc

    .proc onRender
        ; \todo Use a temporary
        ngin_bss spritePosition: .tag ngin_Vector2_16
        ngin_Camera_worldToSpritePosition { ngin_Object_this position, x }, \
                                            spritePosition

        ldx ngin_Object_current

        ngin_SpriteRenderer_render \
            { ngin_Object_this animationState + \
              ngin_SpriteAnimator_State::metasprite, x }, \
              spritePosition

        ldx ngin_Object_current

        ngin_SpriteAnimator_update { ngin_Object_this animationState, x }

        rts
    .endproc

    .proc onUpdate
        ; For testing, this can be used to spawn the player multiple times:
        ; ngin_ObjectSpawner_resetSpawn { ngin_Object_this spawnIndex, x }

        jsr move

        rts
    .endproc

    ; comp is "x_" or "y_". fracComp is "fracX" or "fracY".
    .macro collisionResponse comp, fracComp
        ; If we're moving down, we're grounded if a collision occurred.
        ; Only do the check for vertical collisions.
        .if .xmatch( {comp}, {y_} )
            lda ngin_Object_this velocity+ngin_Vector2_8_8::comp+1, x
            bmi notMovingDown
                ; Moving down.
                ngin_mov8 { ngin_Object_this grounded, x }, #1
            .local notMovingDown
            notMovingDown:
        .endif

        ; Clear velocity on collision.
        ngin_mov16 { ngin_Object_this velocity+ngin_Vector2_8_8::comp, x }, #0

        ; Also clear the subpixel part of position.
        ngin_mov8 { ngin_Object_this position+ngin_Vector2_16_8::fracComp, x }, \
                    #0
    .endmacro

    .proc moveVertical
        movement_template y_, x_, fracY, intY, intX, kBoundingBoxTop, \
                          kBoundingBoxBottom, kBoundingBoxLeft, kBoundingBoxRight, \
                          ngin_MapCollision_lineSegmentEjectVertical, \
                          ngin_MapCollision_lineSegmentEjectVertical_ejectedY, \
                          collisionResponse
    .endproc

    .proc moveHorizontal
        movement_template x_, y_, fracX, intX, intY, kBoundingBoxLeft, \
                          kBoundingBoxRight, kBoundingBoxTop, kBoundingBoxBottom, \
                          ngin_MapCollision_lineSegmentEjectHorizontal, \
                          ngin_MapCollision_lineSegmentEjectHorizontal_ejectedX, \
                          collisionResponse
    .endproc

    .proc applyControlsToVelocity
        ; \todo Read controllers in a centralized place once per frame?
        ngin_Controller_read1
        ngin_bss controller: .byte 0
        sta controller

        ; Default to 0.
        ngin_mov16 { ngin_Object_this velocity+ngin_Vector2_8_8::x_, x }, #0

        lda controller
        and #ngin_Controller::kLeft
        ngin_branchIfZero notLeft
            ngin_mov16 { ngin_Object_this velocity+ngin_Vector2_8_8::x_, x }, \
                #ngin_signed16 -kHorizontalMoveVelocity
        notLeft:

        lda controller
        and #ngin_Controller::kRight
        ngin_branchIfZero notRight
            ngin_mov16 { ngin_Object_this velocity+ngin_Vector2_8_8::x_, x }, \
                #ngin_signed16 kHorizontalMoveVelocity
        notRight:

        ; If option is false, only allow jumping if grounded.
        .if .not ::kAllowJumpInAir
            lda ngin_Object_this grounded, x
            ngin_branchIfZero notGrounded
        .endif
        ; \todo Trigger on edge ("not pressed -> pressed" transition)
        lda controller
        and #ngin_Controller::kA
        ngin_branchIfZero notA
            ngin_mov16 { ngin_Object_this velocity+ngin_Vector2_8_8::y_, x }, \
                #ngin_signed16 -kJumpVelocity
        notA:
        notGrounded:

        rts
    .endproc

    .proc move
        ngin_add16 { ngin_Object_this velocity+ngin_Vector2_8_8::y_, x }, \
                     #kGravity

        jsr applyControlsToVelocity

        lda ngin_Object_this grounded, x

        ; Default to 0. moveVertical will set to 1 if grounded.
        ; \note Since the grounded state is checked in applyControlsToVelocity,
        ;       it is delayed by one frame.
        ngin_mov8 { ngin_Object_this grounded, x }, #0

        jsr moveHorizontal
        jsr moveVertical

        rts
    .endproc
ngin_Object_endDefine
