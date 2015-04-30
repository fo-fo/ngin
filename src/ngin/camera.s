.include "ngin/camera.inc"
.include "ngin/map-scroller.inc"
.include "ngin/core.inc"
.include "ngin/arithmetic.inc"
.include "ngin/branch.inc"
.include "ngin/ppu-buffer.inc"

.segment "NGIN_BSS"

; We don't need a separate variable for passing the position, since
; initializeView would copy it to "position" anyways on entry.
__ngin_Camera_initializeView_position   := __ngin_Camera_position

__ngin_Camera_move_amountX:             .byte 0
__ngin_Camera_move_amountY:             .byte 0

; Camera position in world space
__ngin_Camera_position:                 .tag ngin_Vector2_16

.segment "NGIN_CODE"

.proc __ngin_Camera_initializeView
    __ngin_bss scrollCounter:  .byte 0

    ; \note __ngin_Camera_initializeView_position is an alias for "position",
    ;       so no need to copy.

    ; \todo Assert that position is within a valid range(?)
    ; \todo Assert that rendering is disabled.
    ; \todo Make sure this whole thing works correctly if the position isn't
    ;       aligned to tiles.

    ; Adjust the position so that it's one screenful to the left from the
    ; desired position. As the desired view is scrolled in later, the position
    ; will get adjusted to the correct value.
    ; \todo This value MUST match kViewWidth from the map-scroller Lua --
    ;       use a common symbolic constant for both.
    kScreenWidth = 256-8
    ngin_add16 __ngin_Camera_position + ngin_Vector2_16::x_, \
               #ngin_signedWord -kScreenWidth

    ; Set the map scroll position based on the adjusted position.
    ngin_MapScroller_setPosition __ngin_Camera_position

    ; Scroll the view in by scrolling 256 pixels to the right.
    kScrollPerUpload = 8
    lda #kScreenWidth / kScrollPerUpload
    sta scrollCounter
    loop:
        ngin_PpuBuffer_startFrame
        ngin_Camera_move #ngin_signedByte kScrollPerUpload, #0
        ; \todo Runtime assert that A (scrolled amount) is kScrollPerUpload.
        ngin_PpuBuffer_endFrame
        ngin_PpuBuffer_upload
        dec scrollCounter
    ngin_branchIfNotZero loop

    rts
.endproc

.proc __ngin_Camera_move
    ; The functions return how much was actually scrolled (after clamping to
    ; map boundaries).
    ngin_MapScroller_scrollHorizontal __ngin_Camera_move_amountX
    sta __ngin_Camera_move_amountX
    ngin_MapScroller_scrollVertical   __ngin_Camera_move_amountY
    sta __ngin_Camera_move_amountY

    ; Apply scroll amounts to camera position. Need to sign extend the 8-bit
    ; scroll amounts.
    ngin_add16_8s __ngin_Camera_position + ngin_Vector2_16::x_, \
                  __ngin_Camera_move_amountX
    ngin_add16_8s __ngin_Camera_position + ngin_Vector2_16::y_, \
                  __ngin_Camera_move_amountY

    ; \todo Notify ObjectSpawner of the movement (when it's done)

    rts
.endproc
