.include "ngin/sprite-animator.inc"
.include "ngin/sprite-renderer.inc"
.include "ngin/branch.inc"

.segment "NGIN_ZEROPAGE" : zeropage

__ngin_SpriteAnimator_update_state: .tag ngin_SpriteAnimator_State

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

    ; Preserve Y. Reuse delayLeft as temporary storage, since we know its state,
    ; and it will be overwritten later.
    preservedY := state + ngin_SpriteAnimator_State::delayLeft
    sty preservedY

    ; Fetch the next frame by following the link in the current frame.
    ldy #ngin_SpriteRenderer_Header::next
    lda ( state + ngin_SpriteAnimator_State::metasprite ), y
    ; Store in a temporary variable, because we can't modify "metasprite"
    ; before reading the next byte from there.
    pha
    iny
    lda ( state + ngin_SpriteAnimator_State::metasprite ), y
    sta state + ngin_SpriteAnimator_State::metasprite + 1
    pla
    sta state + ngin_SpriteAnimator_State::metasprite + 0

    ; Now read the delay from the *new* metasprite.
    ldy #ngin_SpriteRenderer_Header::delay
    lda ( state + ngin_SpriteAnimator_State::metasprite ), y
    ; Restore Y.
    ldy preservedY
    sta state + ngin_SpriteAnimator_State::delayLeft

    rts
.endproc
