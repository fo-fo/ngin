.include "object-ball.inc"
.include "common.inc"
.include "assets/sprites/sprites.inc"
.include "object-player.inc"

; -----------------------------------------------------------------------------

; All are inclusive:
kBoundingBox = ngin_immBoundingBox8 -8, -9, 8, 0 ; LTRB

; -----------------------------------------------------------------------------

.segment "CODE"

ngin_bss ball_boundingBox:  .tag ngin_BoundingBox16
ngin_bss ball_boundingBoxPrevTop: .word 0 ; Top coordinate from previous frame

ngin_Object_define object_Ball
    .proc onConstruct
        ngin_log debug, "object_Ball.construct()"

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
                                         #animation_ball_stand

        rts
    .endproc

    .proc onRender
        ngin_alloc spritePosition, 0, .sizeof( ngin_Vector2_16 )
        ngin_Camera_worldToSpritePosition { ngin_Object_this position, x }, \
                                            spritePosition

        ldx ngin_Object_current

        ; Check how far the object is from the screen. ($8000, $8000) is roughly
        ; at the center of the screen, so $7F00..$8100 is offset roughly half
        ; a screen in both directions.
        lda spritePosition+ngin_Vector2_16::x_+1
        cmp #.hibyte( ngin_SpriteRenderer_kOriginX - 256 )
        ngin_branchIfLess deactivate
        cmp #.hibyte( ngin_SpriteRenderer_kOriginX + 256 )
        ngin_branchIfGreaterOrEqual deactivate
        lda spritePosition+ngin_Vector2_16::y_+1
        cmp #.hibyte( ngin_SpriteRenderer_kOriginY - 256 )
        ngin_branchIfLess deactivate
        cmp #.hibyte( ngin_SpriteRenderer_kOriginY + 256 )
        ngin_branchIfGreaterOrEqual deactivate

    dontDeactivate:

        ngin_SpriteRenderer_render \
            { ngin_Object_this animationState + \
              ngin_SpriteAnimator_State::metasprite, x }, \
              spritePosition

        ngin_free spritePosition

        ldx ngin_Object_current

        ngin_SpriteAnimator_update { ngin_Object_this animationState, x }

        rts

    deactivate:
        ; If the spawn point is still within the active spawn view area,
        ; (carry is set), don't deactivate. For example, if a bouncing ball
        ; is spawned, but then (temporarily) bounces down so that it would
        ; be deactivated under normal conditions, this check makes sure that
        ; it stays active. Otherwise the object would disappear, and wouldn't
        ; reappear when moving the camrea further down, because the spawn point
        ; would already be in view.
        ngin_ObjectSpawner_inView { ngin_Object_this spawnIndex, x }
        bcs dontDeactivate

        ; \todo Should NOT allow onUpdate to be called anymore after this
        ;       point. Can be done e.g. by combining onRender and onUpdate
        ;       back again. ;) But no major harm should come from onUpdate
        ;       operating on the freed object, as long as onUpdate doesn't
        ;       try to allocate a new object.
        ngin_log debug, "deactivating object_Ball"

        ngin_free spritePosition

        ; Reset the spawn bit so that it can be respawned.
        ngin_ObjectSpawner_resetSpawn { ngin_Object_this spawnIndex, x }

        ngin_Object_free x
        rts
    .endproc

    .proc onUpdate
        ; Have to calculate bounding box before checking for object collisions.
        ; Make a copy because it's about to be updated.
        ngin_mov16 ball_boundingBoxPrevTop, \
                   { ngin_Object_this boundingBoxTop, x }
        jsr calculateBoundingBox
        ngin_mov16 { ngin_Object_this boundingBoxTop, x }, \
                   ball_boundingBox + ngin_BoundingBox16::top

        ; Check ball-player collisions before moving, so that player's
        ; coordinate is in sync with ours (if ball is moved before checking,
        ; the displacement would not be applied to player until player's update).
        jsr checkObjectCollisions

        jsr move

        rts
    .endproc

    .proc invertVelocity
        ngin_sub16 { ngin_Object_this velocity+ngin_Vector2_8_8::fracY, x }, \
            #0, { ngin_Object_this velocity+ngin_Vector2_8_8::fracY, x }
        rts
    .endproc

    .macro collisionResponse y_, fracY
        ; Invert velocity on collision.
        jsr invertVelocity

        ; Also clear the subpixel part of position.
        ngin_mov8 { ngin_Object_this position+ngin_Vector2_16_8::fracY, x }, \
                    #0
    .endmacro

    .macro beforeMovement
        ngin_alloc yBeforeMovementLo, 0, .byte
        ; Save old position. Even though the integer part is 16-bit, it's
        ; enough to save the lower 8 bits since we're only interested in the
        ; difference (which will be calculated later, and should always fit in
        ; 8 bits).
        ngin_mov8 \
            yBeforeMovementLo, \
            { ngin_Object_this position+ngin_Vector2_16_8::intY+0, x }
    .endmacro

    .macro afterMovement
        ; Calculate how much the object actually moved. Difference should fit
        ; in 8 bits, so don't need to calculate the hibyte.
        ; \note Simply using velocity won't suffice, because if the object
        ;       is ejected from map, the effective movement amount might be less
        ;       than the velocity.
        lda ngin_Object_this position+ngin_Vector2_16_8::intY+0, x
        sec
        sbc yBeforeMovementLo
        sta ngin_Object_this deltaY, x
        ngin_free yBeforeMovementLo
    .endmacro

    .proc moveVertical
        movement_template y_, x_, fracY, intY, intX, \
            ngin_signExtend8 ngin_BoundingBox8_immTop    kBoundingBox, \
            ngin_signExtend8 ngin_BoundingBox8_immBottom kBoundingBox, \
            ngin_signExtend8 ngin_BoundingBox8_immLeft   kBoundingBox, \
            ngin_signExtend8 ngin_BoundingBox8_immRight  kBoundingBox, \
            ngin_MapCollision_lineSegmentEjectVertical, \
            ngin_MapCollision_lineSegmentEjectVertical_ejectedY, \
            collisionResponse, beforeMovement, afterMovement
    .endproc

    .proc calculateBoundingBox
        ; \todo This might be doing some redundant work that could be avoided
        ;       if it was combined with movement_template.
        ; \note Macro includes an RTS.
        calculateBoundingBox_template \
            ball_boundingBox, \
            { ngin_Object_this position, x }, #kBoundingBox
    .endproc

    .proc move
        ngin_add16 { ngin_Object_this velocity+ngin_Vector2_8_8::y_, x }, \
                     #kGravity

        jsr moveVertical

        rts
    .endproc

    .proc checkObjectCollisions
        ; Check for collisions against the player.
        ; \note Player is updated before all other objects, so
        ;       player_boundingBox is up-to-date here.

        ; Check for rect-rect collision.
        ngin_Collision_rectOverlap \
            ball_boundingBox   + ngin_BoundingBox16::leftTop,      \
            ball_boundingBox   + ngin_BoundingBox16::rightBottom,  \
            player_boundingBox + ngin_BoundingBox16::leftTop,      \
            player_boundingBox + ngin_BoundingBox16::rightBottom

        bcc noCollision
            ; Got player-ball collision.

            ; Check if player came from the top, i.e. the bottom of player's
            ; bounding box must have been above the top of the ball's bounding
            ; box.
            ngin_cmp16 player_boundingBoxPrevBottom, ball_boundingBoxPrevTop
            beq fromAbove
            ngin_branchIfGreaterOrEqual notFromAbove
                fromAbove:

                .define playerThis( elem ) ngin_Object_other object_Player, {elem}
                ldy player_id

                ; Set player's fractional position to 0. Set Y position to
                ; slightly inside the platform.
                ngin_mov8 \
                    { playerThis position+ngin_Vector2_16_8::fracY, y }, \
                    #0
                ngin_add16 \
                    { playerThis position+ngin_Vector2_16_8::intY, y }, \
                    ball_boundingBox + ngin_BoundingBox16::top, \
                    #1

                ; Set displacement to 0.
                ngin_mov8 { ngin_Object_this deltaY, x }, #0
                .undefine playerThis

                ; Store object ID.
                stx player_standingOnObject
            notFromAbove:

            jmp doneCollision
        noCollision:
            ; No collision, release the player if it was standing on us.
            cpx player_standingOnObject
            bne notStandingOnPlayer
                ngin_mov8 player_standingOnObject, #ngin_Object_kInvalidId
            notStandingOnPlayer:
        doneCollision:

        rts
    .endproc
ngin_Object_endDefine
