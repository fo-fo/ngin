.if .not .defined( NGIN_SPRITE_ANIMATOR_INC_INCLUDED )
NGIN_SPRITE_ANIMATOR_INC_INCLUDED = 1

.include "ngin/core.inc"
.include "ngin/alloc.inc"

.struct ngin_SpriteAnimator_State
    ; Delay left in the current animation frame
    delayLeft           .byte

    ; Pointer to the current metasprite
    metasprite          .addr
.endstruct

; \note metasprite_ is used as the name to avoid conflicts with the
;       struct member in ngin_SpriteAnimator_State.
.global   __ngin_SpriteAnimator_callEventCallback
.globalzp __ngin_SpriteAnimator_callEventCallback_metasprite
.macro ngin_SpriteAnimator_initialize state, metasprite_
    __ngin_requireParameter {state},       "state"
    __ngin_requireParameter {metasprite_}, "metasprite_"

    __ngin_getOperandStride {state}, __ngin_SpriteAnimator_strideState

    .if .match( .left( 1, {metasprite_} ), # )
        .local metaspriteStripped
        metaspriteStripped = .right( .tcount( {metasprite_} ) - 1, \
                                              {metasprite_} )

        ; Copy the delay from the metasprite to the animation state.
        ; \note "state" is not allowed to be an immediate
        ngin_mov8 { ngin_SpriteAnimator_State::delayLeft * \
                    __ngin_SpriteAnimator_strideState + state }, \
                  { ngin_SpriteRenderer_Header::delay + metaspriteStripped }
    .else
        ; "metasprite_" is a pointer to a metasprite. Need to do an indirect
        ; fetch to get the delay. Because metasprite_ may not be in zeropage,
        ; need to use a temporary variable.
        __ngin_alloc ptr, 0, .word
        ngin_mov16 ptr, {metasprite_}
        ldy #ngin_SpriteRenderer_Header::delay
        lda ( ptr ), y
        __ngin_free ptr
        sta ngin_SpriteAnimator_State::delayLeft * \
                __ngin_SpriteAnimator_strideState + state
    .endif

    ; Copy the metasprite pointer to the state data.
    ngin_mov16 { ngin_SpriteAnimator_State::metasprite * \
                 __ngin_SpriteAnimator_strideState + state }, metasprite_

    ; Call the event callback for the first frame.
    ngin_mov16 __ngin_SpriteAnimator_callEventCallback_metasprite, metasprite_
    jsr __ngin_SpriteAnimator_callEventCallback

    ; \todo Special-case a delay of 0 for "no delay" (currently delay of 256),
    ;       could be useful for chaining of events(?)
.endmacro

.global   __ngin_SpriteAnimator_update
.globalzp __ngin_SpriteAnimator_update_state
.macro ngin_SpriteAnimator_update state
    __ngin_requireParameter {state}, "state"

    ; We copy the state in by value, since it's fairly small (3 bytes currently).
    ; This simplifies the update code tremendously, and makes the interface
    ; easier to use e.g. from object handlers.
    ; This also means that "state" can't be an immediate, because we need to
    ; copy the result back when we leave.
    .assert .sizeof( ngin_SpriteAnimator_State ) = 3, error
    ngin_mov24 __ngin_SpriteAnimator_update_state, {state}

    ; \note Since "state" may be X/Y relative, update() needs to make sure that
    ;       X/Y stay unmodified so that the results can be copied back on exit.
    ; \todo Runtime asserts to make sure X and Y stay unmodified.
    jsr __ngin_SpriteAnimator_update

    ngin_mov24 {state}, __ngin_SpriteAnimator_update_state
.endmacro

.endif
