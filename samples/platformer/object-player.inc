.if .not .defined( NGIN_SAMPLE_PLATFORMER_OBJECT_PLAYER_INC_INCLUDED )
NGIN_SAMPLE_PLATFORMER_OBJECT_PLAYER_INC_INCLUDED = 1

.include "ngin/ngin.inc"

.global playerId

ngin_Object_declare object_Player
    ; 16.8 fixed point position
    position        .tag ngin_Vector2_16_8

    ; 8.8 fixed point velocity
    velocity        .tag ngin_Vector2_8_8

    animationState  .tag ngin_SpriteAnimator_State

    spawnIndex      .byte

    ; True, if player is standing on ground
    ; \todo Don't waste a full byte on this.
    grounded        .byte
ngin_Object_endDeclare

.endif
