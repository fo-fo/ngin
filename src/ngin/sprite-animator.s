.include "ngin/sprite-animator.inc"
.include "ngin/sprite-renderer.inc"
.include "ngin/branch.inc"
.include "ngin/alloc.inc"

.segment "NGIN_CODE"

.proc __ngin_SpriteAnimator_update
    __ngin_alloc state, 0, .sizeof( ngin_SpriteAnimator_State )
    ::__ngin_SpriteAnimator_update_state := state

    ; -------------------------------------------------------------------------
    ; \note This function has to preserve X and Y. See the macro.
    ; -------------------------------------------------------------------------

    ; Decrease the amount of delay left, and when 0, grab the next frame.
    ; \todo This decrease could be moved into the macro to avoid the copy,
    ;       since most of the time will be spent waiting for the delay to
    ;       elapse (\note DEC doesn't work in all addressing modes)
    dec state + ngin_SpriteAnimator_State::delayLeft
    ngin_branchIfZero nextFrame
        __ngin_free state
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

    ngin_mov16 __ngin_SpriteAnimator_callEventCallback_metasprite, \
               state + ngin_SpriteAnimator_State::metasprite
    jsr __ngin_SpriteAnimator_callEventCallback

    ; Restore X and Y.
    pla
    tax
    pla
    tay

    __ngin_free state

    rts
.endproc

.proc __ngin_SpriteAnimator_callEventCallback
    ; Need a non-zero base because this can be called from
    ; Camera_initializeView, which also needs some temporary variables.
    __ngin_alloc metasprite, 9, .word
    ::__ngin_SpriteAnimator_callEventCallback_metasprite := metasprite
    __ngin_alloc callbackPtr, , .word

    ; Read callback from the metasprite and call it.
    ldy #ngin_SpriteRenderer_Header::eventCallback
    lda ( metasprite ), y
    sta callbackPtr + 0
    iny
    lda ( metasprite ), y
    sta callbackPtr + 1

    __ngin_free metasprite, callbackPtr

    ; JSR+RTS
    jmp ( callbackPtr )
.endproc
