.include "object-player.inc"
.include "object-ball.inc"
.include "common.inc"
.include "assets/sprites/sprites.inc"

; -----------------------------------------------------------------------------

; All are inclusive:
kBoundingBox = ngin_immBoundingBox8 -6, -30, 6, 0 ; LTRB

; 8.8 fixed point (pixels/frame)
ngin_fixedPointQ8 kHorizontalMoveVelocity, "1.5"
ngin_fixedPointQ8 kJumpVelocity, "3.985"

kAllowJumpInAir         = ngin_Bool::kFalse

; -----------------------------------------------------------------------------

.enum Player_Animation
    ; \note Has to match the order in Player_State.
    kStandL
    kStandR
    kRunL
    kRunR
    kAttackL
    kAttackR
.endenum

.define animations \
    animation_player_stand_H,          \
    animation_player_stand,            \
    animation_player_run_H,            \
    animation_player_run,              \
    animation_player_attack_H,         \
    animation_player_attack

.segment "RODATA"
animationsLo: .lobytes animations
animationsHi: .hibytes animations

.segment "BSS"
player_boundingBox:             .tag ngin_BoundingBox16
player_boundingBoxPrevBottom:   .word 0 ; Bottom coordinate from previous frame
; Object ID that the player is standing on (ngin_Object_kInvalidId if not
; standing on anything)
player_standingOnObject:        .byte 0

; -----------------------------------------------------------------------------

.segment "CODE"

ngin_bss player_id: .byte 0

ngin_Object_define object_Player
    .proc onConstruct
        ngin_log debug, "object_Player.construct()"

        stx player_id

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
                                         #animation_player_stand

        ngin_mov8 { ngin_Object_this status, x }, \
                   #Player_Status::kDirection

        ngin_mov8 { ngin_Object_this state, x }, #Player_State::kStand
        ngin_mov8 { ngin_Object_this currentAnimation, x }, \
                   #Player_Animation::kStandL

        ngin_mov8 player_standingOnObject, #ngin_Object_kInvalidId

        rts
    .endproc

    .proc onRender
        ngin_alloc spritePosition, 0, .sizeof( ngin_Vector2_16 )
        ngin_Camera_worldToSpritePosition { ngin_Object_this position, x }, \
                                            spritePosition

        ldx ngin_Object_current

        ngin_SpriteRenderer_render \
            { ngin_Object_this animationState + \
              ngin_SpriteAnimator_State::metasprite, x }, \
              spritePosition

        ngin_free spritePosition

        ldx ngin_Object_current

        ngin_SpriteAnimator_update { ngin_Object_this animationState, x }

        rts
    .endproc

    .proc onUpdate
        ; Empty -- handled in onManualUpdate instead.
        rts
    .endproc

    .proc onManualUpdate
        ; For testing, this can be used to spawn the player multiple times:
        ; ngin_ObjectSpawner_resetSpawn { ngin_Object_this spawnIndex, x }

        ngin_jsrRts move
    .endproc

    ; comp is "x_" or "y_". fracComp is "fracX" or "fracY".
    .macro collisionResponse comp, fracComp
        ; If we're moving down, we're grounded if a collision occurred.
        ; Only do the check for vertical collisions.
        .if .xmatch( {comp}, {y_} )
            lda ngin_Object_this velocity+ngin_Vector2_8_8::comp+1, x
            bmi notMovingDown
                ; Moving down.
                lda ngin_Object_this status, x
                ora #Player_Status::kGrounded
                sta ngin_Object_this status, x
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
        movement_template y_, x_, fracY, intY, intX, \
            ngin_signExtend8 ngin_BoundingBox8_immTop    kBoundingBox, \
            ngin_signExtend8 ngin_BoundingBox8_immBottom kBoundingBox, \
            ngin_signExtend8 ngin_BoundingBox8_immLeft   kBoundingBox, \
            ngin_signExtend8 ngin_BoundingBox8_immRight  kBoundingBox, \
            ngin_MapCollision_lineSegmentEjectVertical, \
            ngin_MapCollision_lineSegmentEjectVertical_ejectedY, \
            collisionResponse
    .endproc

    .proc moveHorizontal
        movement_template x_, y_, fracX, intX, intY, \
            ngin_signExtend8 ngin_BoundingBox8_immLeft   kBoundingBox, \
            ngin_signExtend8 ngin_BoundingBox8_immRight  kBoundingBox, \
            ngin_signExtend8 ngin_BoundingBox8_immTop    kBoundingBox, \
            ngin_signExtend8 ngin_BoundingBox8_immBottom kBoundingBox, \
            ngin_MapCollision_lineSegmentEjectHorizontal, \
            ngin_MapCollision_lineSegmentEjectHorizontal_ejectedX, \
            collisionResponse
    .endproc

    .proc handleControls
        ; \todo Read controllers in a centralized place once per frame?
        ngin_Controller_read1
        ngin_alloc controller, 0, .byte
        sta controller

        ; Default to 0.
        ngin_mov16 { ngin_Object_this velocity+ngin_Vector2_8_8::x_, x }, #0

        ; Default state to stand.
        ngin_mov8 { ngin_Object_this state, x }, #Player_State::kStand

        lda controller
        and #ngin_Controller::kLeft
        ngin_branchIfZero notLeft
            ngin_mov16 { ngin_Object_this velocity+ngin_Vector2_8_8::x_, x }, \
                #ngin_signed16 -kHorizontalMoveVelocity

            ngin_mov8 { ngin_Object_this state, x }, #Player_State::kRun

            ; \todo Macro for bit clear, set, flip, test
            lda ngin_Object_this status, x
            and #.lobyte( ~Player_Status::kDirection )
            sta ngin_Object_this status, x
        notLeft:

        lda controller
        and #ngin_Controller::kRight
        ngin_branchIfZero notRight
            ngin_mov16 { ngin_Object_this velocity+ngin_Vector2_8_8::x_, x }, \
                #ngin_signed16 kHorizontalMoveVelocity

            ngin_mov8 { ngin_Object_this state, x }, #Player_State::kRun

            lda ngin_Object_this status, x
            ora #Player_Status::kDirection
            sta ngin_Object_this status, x
        notRight:

        ; If option is false, only allow jumping if grounded.
        .if .not ::kAllowJumpInAir
            lda ngin_Object_this status, x
            and #Player_Status::kGrounded
            ngin_branchIfZero notGrounded
        .endif
        ; \todo Trigger on edge ("not pressed -> pressed" transition)
        lda controller
        and #ngin_Controller::kA
        ngin_branchIfZero notA
            ngin_mov16 { ngin_Object_this velocity+ngin_Vector2_8_8::y_, x }, \
                #ngin_signed16 -kJumpVelocity
            ; Release from platform.
            ngin_mov8 player_standingOnObject, #ngin_Object_kInvalidId
        notA:
        notGrounded:

        ; Handle attack.
        lda controller
        and #ngin_Controller::kB
        ngin_branchIfZero notB
            ngin_mov8 { ngin_Object_this state, x }, \
                       #Player_State::kAttack
        notB:

        ngin_free controller

        rts
    .endproc

    .proc reloadAnimation
        ngin_alloc newAnimation,    0, .byte
        ngin_alloc newAnimationPtr,  , .word

        ldx ngin_Object_current

        ; Calculate the new animation based on state and direction.
        ; Take the state, multiply by 2, and add the direction to get an
        ; index in the Player_Animation enum.
        lda ngin_Object_this status, x
        and #Player_Status::kDirection
        .assert Player_Status::kDirection = %10, error
        lsr
        sta newAnimation
        lda ngin_Object_this state, x
        asl
        ora newAnimation
        sta newAnimation

        ; If animation changed, reinitialize.
        cmp ngin_Object_this currentAnimation, x
        beq didntChange
            ; Changed.
            ; ngin_log debug, "animation changed to %d", a
            sta ngin_Object_this currentAnimation, x
            tay
            lda animationsLo, y
            sta newAnimationPtr+0
            lda animationsHi, y
            sta newAnimationPtr+1
            ngin_SpriteAnimator_initialize \
                { ngin_Object_this animationState, x }, newAnimationPtr
        didntChange:

        ngin_free newAnimation, newAnimationPtr

        rts
    .endproc

    .proc calculateBoundingBox
        ; \todo This might be doing some redundant work that could be avoided
        ;       if it was combined with movement_template.
        ; \note Macro includes an RTS.
        calculateBoundingBox_template \
            player_boundingBox, \
            { ngin_Object_this position, x }, #kBoundingBox
    .endproc

    .proc move
        ngin_add16 { ngin_Object_this velocity+ngin_Vector2_8_8::y_, x }, \
                     #kGravity

        jsr handleControls
        jsr reloadAnimation

        ; Default "grounded" to 0. moveVertical will set to 1 if grounded.
        ; \note Since the grounded state is checked in handleControls,
        ;       it is delayed by one frame.
        lda ngin_Object_this status, x
        and #.lobyte( ~Player_Status::kGrounded )
        sta ngin_Object_this status, x

        ; Check if player is standing on an object.
        ldy player_standingOnObject
        cpy #ngin_Object_kInvalidId
        beq notStanding
            ; Standing on something.
            ; \note Assuming here that it's a ball, or something with an
            ;       equivalent data layout. (Should standardize the order of
            ;       position/velocity/etc data for such objects?)
            .define ballThis( elem ) ngin_Object_other object_Ball, {elem}

            ; Force Y velocity from deltaY (Y displacement) of the ball.
            ngin_mov8 \
                { ngin_Object_this velocity+ngin_Vector2_8_8::intY, x }, \
                { ballThis         deltaY, y }
            ngin_mov8 \
                { ngin_Object_this velocity+ngin_Vector2_8_8::fracY, x }, \
                #0
            ; Clear the fractional part.
            ngin_mov8 { ngin_Object_this position+ngin_Vector2_16_8::fracY, x }, #0
            .undefine ballThis

            ; Always grounded when on platform.
            lda ngin_Object_this status, x
            ora #Player_Status::kGrounded
            sta ngin_Object_this status, x
        notStanding:

        jsr moveHorizontal
        jsr moveVertical

        ngin_mov16 player_boundingBoxPrevBottom, \
                   player_boundingBox + ngin_BoundingBox16::bottom
        jsr calculateBoundingBox

        ngin_DebugDraw_printf "Player X: %X", { 24 : ngin_Object_this position+ngin_Vector2_16_8::x_, x }
        ngin_DebugDraw_printf "Player Y: %X", { 24 : ngin_Object_this position+ngin_Vector2_16_8::y_, x }

        rts
    .endproc
ngin_Object_endDefine
