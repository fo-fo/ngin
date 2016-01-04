.if .not .defined( NGIN_SAMPLE_PLATFORMER_OBJECT_PLAYER_INC_INCLUDED )
NGIN_SAMPLE_PLATFORMER_OBJECT_PLAYER_INC_INCLUDED = 1

.include "ngin/ngin.inc"

.global player_id ; .byte
.global player_standingOnObject ; .byte
.global player_boundingBox ; ngin_BoundingBox16
.global player_boundingBoxPrevBottom ; .word

; Bitflags
.enum Player_Status
    kGrounded   = 1 << 0
    kDirection  = 1 << 1
.endenum

.enum Player_State
    kStand
    kRun
    kAttack
.endenum

ngin_Object_declare object_Player
    ; 16.8 fixed point position
    position            .tag ngin_Vector2_16_8

    ; 8.8 fixed point velocity
    velocity            .tag ngin_Vector2_8_8

    animationState      .tag ngin_SpriteAnimator_State

    spawnIndex          .byte

    status              .byte ; Player_Status

    state               .byte ; Player_State

    currentAnimation    .byte
ngin_Object_endDeclare

.endif
