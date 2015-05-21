.include "ngin/camera.inc"
.include "ngin/map-scroller.inc"
.include "ngin/core.inc"
.include "ngin/arithmetic.inc"
.include "ngin/branch.inc"
.include "ngin/ppu-buffer.inc"
.include "ngin/object-spawner.inc"

.segment "NGIN_BSS"

; We don't need a separate variable for passing the position, since
; initializeView would copy it to "position" anyways on entry.
__ngin_Camera_initializeView_position   := ngin_Camera_position

__ngin_Camera_move_amountX:             .byte 0
__ngin_Camera_move_amountY:             .byte 0

; Camera position in world space
ngin_Camera_position:                   .tag ngin_Vector2_16

.segment "NGIN_CODE"

.proc __ngin_Camera_initializeView
    __ngin_bss scrollCounter:  .byte 0

    ; \note __ngin_Camera_initializeView_position is an alias for "position",
    ;       so no need to copy.

    ; \todo Assert that position is within a valid range(?)
    ; \todo Assert that rendering is disabled.
    ; \todo Make sure this whole thing works correctly if the position isn't
    ;       aligned to tiles.

    kScreenWidth        = 256
    kScrollPerUpload    = 8

    ; \note Camera_move cannot be used for initialization, because the width
    ;       of the spawn view and the map scroller view may differ.

    ; Initialize the object spawner position to kScreenWidth+kSlackX. Then
    ; scroll the spawner left kScreenWidth+2*kSlackX pixels, which will align
    ; it properly with the map scroller (at -kSlackX).
    ; Use ngin_Camera_position as a temporary.
    ; \todo Put result directly to parameter area of ObjectSpawner_setPosition.
    ; Scroll in 8 pixel increments, although it's not strictly necessary
    ; for object spawner.
    ngin_add16 ngin_Camera_position + ngin_Vector2_16::x_, \
               #ngin_signedWord kScreenWidth + ngin_ObjectSpawner_kViewSlackX
    ngin_add16 ngin_Camera_position + ngin_Vector2_16::y_, \
               #ngin_signedWord -ngin_ObjectSpawner_kViewSlackY
    ngin_ObjectSpawner_setPosition ngin_Camera_position
    kSpawnerScrollAmountTotal = kScreenWidth + 2*ngin_ObjectSpawner_kViewSlackX
    .assert kSpawnerScrollAmountTotal .mod kScrollPerUpload = 0, error
    lda #kSpawnerScrollAmountTotal / kScrollPerUpload
    sta scrollCounter
    spawnLoop:
        ngin_ObjectSpawner_scrollHorizontal #ngin_signedByte -kScrollPerUpload
        dec scrollCounter
    ngin_branchIfNotZero spawnLoop

    ; Adjust the position so that it's one screenful to the right from the
    ; desired position. As the desired view is scrolled in later, the position
    ; will get adjusted to the correct value.
    ; Note that ngin_Camera_position was already wrecked for the object
    ; spawner before, so need to take that into account.
    ngin_add16 ngin_Camera_position + ngin_Vector2_16::x_, \
               #ngin_signedWord -ngin_ObjectSpawner_kViewSlackX
    ngin_add16 ngin_Camera_position + ngin_Vector2_16::y_, \
               #ngin_signedWord ngin_ObjectSpawner_kViewSlackY
    ; Set the map scroll position based on the adjusted position.
    ngin_MapScroller_setPosition   ngin_Camera_position
    ; Scroll the view in by scrolling 256 pixels to the left.
    lda #kScreenWidth / kScrollPerUpload
    sta scrollCounter
    mapLoop:
        ngin_PpuBuffer_startFrame
        ngin_MapScroller_scrollHorizontal #ngin_signedByte -kScrollPerUpload
        ; \todo Runtime assert that A (scrolled amount) is kScrollPerUpload.
        ngin_PpuBuffer_endFrame
        ngin_PpuBuffer_upload
        dec scrollCounter
    ngin_branchIfNotZero mapLoop

    ; Finally, adjust the position once more so that it actually points at
    ; the current position. This actually adjusts the position to the value
    ; it had at function entry, so it's a bit lame (but needed, because it's
    ; used as a temporary currently.)
    ngin_add16 ngin_Camera_position + ngin_Vector2_16::x_, \
               #ngin_signedWord -kScreenWidth

    rts
.endproc

.proc __ngin_Camera_move
    ; The functions return how much was actually scrolled (after clamping to
    ; map boundaries).
    ngin_MapScroller_scrollHorizontal __ngin_Camera_move_amountX
    sta __ngin_Camera_move_amountX
    ngin_MapScroller_scrollVertical   __ngin_Camera_move_amountY
    sta __ngin_Camera_move_amountY

    ; Notify ObjectSpawner of the movement.
    ; \todo It's semi-bad that we're force pulling the ObjectSpawner dependency
    ;       in. It'll also pull in Object module in turn, which is fairly big.
    ngin_ObjectSpawner_scrollHorizontal __ngin_Camera_move_amountX
    ngin_ObjectSpawner_scrollVertical   __ngin_Camera_move_amountY

    ; Apply scroll amounts to camera position. Need to sign extend the 8-bit
    ; scroll amounts.
    ngin_add16_8s ngin_Camera_position + ngin_Vector2_16::x_, \
                  __ngin_Camera_move_amountX
    ngin_add16_8s ngin_Camera_position + ngin_Vector2_16::y_, \
                  __ngin_Camera_move_amountY

    rts
.endproc
