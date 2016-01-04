.if .not .defined( NGIN_SAMPLE_PLATFORMER_OBJECT_BALL_INC_INCLUDED )
NGIN_SAMPLE_PLATFORMER_OBJECT_BALL_INC_INCLUDED = 1

.include "ngin/ngin.inc"

ngin_Object_declare object_Ball
    ; 16.8 fixed point position
    position        .tag ngin_Vector2_16_8

    ; 8.8 fixed point velocity
    velocity        .tag ngin_Vector2_8_8

    animationState  .tag ngin_SpriteAnimator_State

    spawnIndex      .byte

    ; Keep track so that we can know it on the next frame.
    boundingBoxTop  .word

    ; Effective movement delta (used by player if standing on this ball)
    ; Only Y movement is handled currently.
    deltaY          .byte
ngin_Object_endDeclare

.endif
