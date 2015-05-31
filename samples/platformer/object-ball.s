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
        ; \todo Use a temporary
        ngin_bss spritePosition: .tag ngin_Vector2_16
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

        ; Reset the spawn bit so that it can be respawned.
        ngin_ObjectSpawner_resetSpawn { ngin_Object_this spawnIndex, x }

        ngin_Object_free x
        rts
    .endproc

    .proc onUpdate
        jsr move

        rts
    .endproc

    .macro collisionResponse y_, fracY
        ; Invert velocity on collision.
        ngin_sub16 { ngin_Object_this velocity+ngin_Vector2_8_8::fracY, x }, \
                     #0, \
                   { ngin_Object_this velocity+ngin_Vector2_8_8::fracY, x }

        ; Also clear the subpixel part of position.
        ngin_mov8 { ngin_Object_this position+ngin_Vector2_16_8::fracY, x }, \
                    #0
    .endmacro

    .proc moveVertical
        movement_template y_, x_, fracY, intY, intX, kBoundingBoxTop, \
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
