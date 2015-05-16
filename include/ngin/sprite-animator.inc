.if .not .defined( NGIN_SPRITE_ANIMATOR_INC_INCLUDED )
NGIN_SPRITE_ANIMATOR_INC_INCLUDED = 1

.include "ngin/core.inc"

.struct ngin_SpriteAnimator_State
    ; Delay left in the current animation frame
    delayLeft           .byte

    ; Pointer to the current sprite definition
    spriteDefinition    .addr
.endstruct

; \note spriteDefinition_ is used as the name to avoid conflicts with the
;       struct member in ngin_SpriteAnimator_State.
.macro ngin_SpriteAnimator_initialize state, spriteDefinition_
    __ngin_requireParameter {state},             "state"
    __ngin_requireParameter {spriteDefinition_}, "spriteDefinition_"

    __ngin_getOperandStride {state}, __ngin_SpriteAnimator_strideState

    ; Currently spriteDefinition_ is required to be an immediate since fetching
    ; the sprite definition pointer from memory would complicate things a bit.
    ; \todo Allow non-immediates.
    __ngin_requireImmediate {spriteDefinition_}, "spriteDefinition_"

    .local spriteDefinitionStripped
    spriteDefinitionStripped = .right( .tcount( {spriteDefinition_} ) - 1, \
                                                {spriteDefinition_} )

    ; Copy the delay from the sprite definition to the animation state.
    ; \note "state" is not allowed to be an immediate
    ngin_mov8 { ngin_SpriteAnimator_State::delayLeft * \
                __ngin_SpriteAnimator_strideState + state }, \
              { ngin_SpriteRenderer_Header::delay + spriteDefinitionStripped }

    ; Copy the sprite definition pointer to the state data.
    ngin_mov16 { ngin_SpriteAnimator_State::spriteDefinition * \
                 __ngin_SpriteAnimator_strideState + state }, \
                #spriteDefinitionStripped
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
