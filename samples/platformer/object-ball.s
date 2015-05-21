.include "object-ball.inc"
.include "common.inc"
.include "assets/sprites/sprites.inc"

; -----------------------------------------------------------------------------

; All are inclusive:
kBoundingBoxTop    = -30
kBoundingBoxBottom = 0
kBoundingBoxLeft   = -8
kBoundingBoxRight  = 8

; -----------------------------------------------------------------------------

.segment "CODE"

ngin_bss playerId: .byte 0

ngin_Object_define object_Ball
    .proc onConstruct
        ngin_log debug, "object_Ball.construct()"

        ; Initialize position from constructor parameters. Initialize fractional
        ; position to 0.
        ngin_mov32 { ngin_Object_this position, x }, \
                     ngin_Object_constructorParameter position
        ngin_mov16 { ngin_Object_this fracPosition, x }, #0

        ; Initialize velocity to 0.
        ngin_mov32 { ngin_Object_this velocity, x }, #0

        ; Initialize animation.
        ngin_SpriteAnimator_initialize { ngin_Object_this animationState, x }, \
                                         #animation_ball

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
        jsr move

        rts
    .endproc

    .macro collisionResponse y_, fracY_
        ; Invert velocity on collision.
        ngin_sub16 { ngin_Object_this velocity+ngin_Vector2_8_8::fracY_, x }, \
                     #0, \
                   { ngin_Object_this velocity+ngin_Vector2_8_8::fracY_, x }

        ; Also clear the subpixel part of position.
        ngin_mov8 { ngin_Object_this fracPosition+ngin_Vector2_8::y_, x }, \
                    #0
    .endmacro

    .proc moveVertical
        movement_template y_, x_, fracY_, intY_, kBoundingBoxTop, \
                          kBoundingBoxBottom, kBoundingBoxLeft, kBoundingBoxRight, \
                          ngin_MapCollision_lineSegmentEjectVertical, \
                          ngin_MapCollision_lineSegmentEjectVertical_ejectedY, \
                          collisionResponse
    .endproc

    .proc move
        ngin_add16 { ngin_Object_this velocity+ngin_Vector2_8_8::y_, x }, \
                     #kGravity

        jsr moveVertical

        rts
    .endproc
ngin_Object_endDefine
