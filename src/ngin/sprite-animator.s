.include "ngin/sprite-animator.inc"
.include "ngin/sprite-renderer.inc"
.include "ngin/branch.inc"

.segment "NGIN_ZEROPAGE" : zeropage

__ngin_SpriteAnimator_update_state:   .tag ngin_SpriteAnimator_State

__ngin_SpriteAnimator_callEventCallback_metasprite = \
    __ngin_SpriteAnimator_update_state + ngin_SpriteAnimator_State::metasprite

; \todo Use a temporary
__ngin_SpriteAnimator_initialize_ptr: .word 0
__ngin_SpriteAnimator_callback_ptr = __ngin_SpriteAnimator_initialize_ptr

.segment "NGIN_CODE"

.proc __ngin_SpriteAnimator_update
    state := __ngin_SpriteAnimator_update_state

    ; -------------------------------------------------------------------------
    ; \note This function has to preserve X and Y. See the macro.
    ; -------------------------------------------------------------------------

    ; Decrease the amount of delay left, and when 0, grab the next frame.
    ; \todo This decrease could be moved into the macro to avoid the copy,
    ;       since most of the time will be spent waiting for the delay to
    ;       elapse (\note DEC doesn't work in all addressing modes)
    dec state + ngin_SpriteAnimator_State::delayLeft
    ngin_branchIfZero nextFrame
        rts
    nextFrame:

    ; Preserve X and Y.
    tya
    pha
    txa
    pha

    ; Fetch the next frame by following the link in the current frame.
    ldy #ngin_SpriteRenderer_Header::next
    lda ( state + ngin_SpriteAnimator_State::metasprite ), y
    ; Store on stack for now, because "metasprite" can't be modified before
    ; the next byte is read from there.
    pha
    iny
    lda ( state + ngin_SpriteAnimator_State::metasprite ), y
    sta state + ngin_SpriteAnimator_State::metasprite + 1
    pla
    sta state + ngin_SpriteAnimator_State::metasprite + 0

    ; Now read the delay from the *new* metasprite.
    ldy #ngin_SpriteRenderer_Header::delay
    lda ( state + ngin_SpriteAnimator_State::metasprite ), y
    sta state + ngin_SpriteAnimator_State::delayLeft

    jsr __ngin_SpriteAnimator_callEventCallback

    ; Restore X and Y.
    pla
    tax
    pla
    tay

    rts
.endproc

.proc __ngin_SpriteAnimator_callEventCallback
    metasprite := __ngin_SpriteAnimator_callEventCallback_metasprite
    ; Must be the same as the metasprite member in update_state, because
    ; this is also called from __ngin_SpriteAnimator_update.
    .assert metasprite = __ngin_SpriteAnimator_update_state + \
            ngin_SpriteAnimator_State::metasprite, error

    ; Read callback from the metasprite and call it.
    ldy #ngin_SpriteRenderer_Header::eventCallback
    lda ( metasprite ), y
    sta __ngin_SpriteAnimator_callback_ptr + 0
    iny
    lda ( metasprite ), y
    sta __ngin_SpriteAnimator_callback_ptr + 1

    ; JSR+RTS
    jmp ( __ngin_SpriteAnimator_callback_ptr )
.endproc
