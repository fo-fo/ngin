.include "object-player.inc"
.include "ngin/ngin.inc"
.include "assets/sprites/sprites.inc"

; -----------------------------------------------------------------------------

.segment "CODE"

ngin_Object_define object_Player
    .proc construct
        ngin_log debug, "object_Player.construct()"

        ngin_mov32 { ngin_Object_this position, x }, \
                     ngin_Object_constructorParameter position

        ; \todo Initialize velocity/fractional position.

        ngin_SpriteAnimator_initialize { ngin_Object_this animationState, x }, \
                                         #animation_player

        rts
    .endproc

    .proc update
        ; \todo Move, check for collisions

        jsr render

        rts
    .endproc

    .proc render
        ldx ngin_Object_current

        ; \todo Use a temporary
        ngin_bss spritePosition: .tag ngin_Vector2_16
        ngin_Camera_worldToSpritePosition { ngin_Object_this position, x }, \
                                            spritePosition

        ldx ngin_Object_current

        ngin_SpriteRenderer_render \
            { ngin_Object_this animationState + \
              ngin_SpriteAnimator_State::spriteDefinition, x }, \
              spritePosition

        ldx ngin_Object_current

        ngin_SpriteAnimator_update { ngin_Object_this animationState, x }

        rts
    .endproc
ngin_Object_endDefine
