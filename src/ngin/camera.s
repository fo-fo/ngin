.include "ngin/camera.inc"
.include "ngin/map-scroller.inc"
.include "ngin/core.inc"
.include "ngin/arithmetic.inc"
.include "ngin/branch.inc"
.include "ngin/ppu-buffer.inc"
.include "ngin/object-spawner.inc"
.include "ngin/map-data.inc"

.segment "NGIN_BSS"

__ngin_Camera_initializeView_position:  .tag ngin_Vector2_16

; 8.8 fixed point
__ngin_Camera_move_amountX:             .tag ngin_FixedPoint8_8
__ngin_Camera_move_amountY:             .tag ngin_FixedPoint8_8

; Camera position in world space
ngin_Camera_position:                   .tag ngin_Vector2_16_8

.segment "NGIN_CODE"

.proc __ngin_Camera_initializeView
    ; \todo Assert that position is within a valid range(?)
    ; \todo Assert that rendering is disabled.
    ; \todo Make sure this whole thing works correctly if the position isn't
    ;       aligned to tiles.

    kScreenWidth        = 256
    kScrollPerUpload    = 8

    ; \note Camera_move cannot be used for initialization, because the width
    ;       of the spawn view and the map scroller view may differ.

    ; \todo Use a temporary.
    __ngin_bss position: .tag ngin_Vector2_16
    __ngin_bss scrollCounter: .byte 0

    ; Initialize the object spawner position to kScreenWidth+kSlackX. Then
    ; scroll the spawner left kScreenWidth+2*kSlackX pixels, which will align
    ; it properly with the map scroller (at -kSlackX).
    ; \todo Put result directly to parameter area of ObjectSpawner_setPosition.
    ; Scroll in 8 pixel increments, although it's not strictly necessary
    ; for object spawner.
    ngin_add16 position + ngin_Vector2_16::x_, \
               __ngin_Camera_initializeView_position + ngin_Vector2_16::x_, \
               #ngin_signed16 kScreenWidth + ngin_ObjectSpawner_kViewSlackX
    ngin_add16 position + ngin_Vector2_16::y_, \
               __ngin_Camera_initializeView_position + ngin_Vector2_16::y_, \
               #ngin_signed16 -ngin_ObjectSpawner_kViewSlackY

    ngin_ObjectSpawner_setPosition position

    kSpawnerScrollAmountTotal = kScreenWidth + 2*ngin_ObjectSpawner_kViewSlackX
    .assert kSpawnerScrollAmountTotal .mod kScrollPerUpload = 0, error
    lda #kSpawnerScrollAmountTotal / kScrollPerUpload
    sta scrollCounter
    spawnLoop:
        ngin_ObjectSpawner_scrollHorizontal #ngin_signed8 -kScrollPerUpload
        dec scrollCounter
    ngin_branchIfNotZero spawnLoop

    ; Adjust the position so that it's one screenful to the right from the
    ; desired position. As the desired view is scrolled in later, the position
    ; will get adjusted to the correct value.
    ; Note that "position" was already modified for the object spawner before,
    ; so need to take that into account.
    ngin_add16 position + ngin_Vector2_16::x_, \
               #ngin_signed16 -ngin_ObjectSpawner_kViewSlackX
    ngin_add16 position + ngin_Vector2_16::y_, \
               #ngin_signed16 ngin_ObjectSpawner_kViewSlackY

    ; Set the map scroll position based on the adjusted position.
    ngin_MapScroller_setPosition position

    ; Scroll the view in by scrolling 256 pixels to the left.
    lda #kScreenWidth / kScrollPerUpload
    sta scrollCounter
    mapLoop:
        ngin_PpuBuffer_startFrame
        ngin_MapScroller_scrollHorizontal #ngin_signed8 -kScrollPerUpload
        ngin_assert .sprintf( "ngin.signed8( REG.A ) == %d", -kScrollPerUpload )
        ngin_PpuBuffer_endFrame
        ngin_PpuBuffer_upload
        dec scrollCounter
    ngin_branchIfNotZero mapLoop

    ; Set ngin_Camera_position from __ngin_Camera_initializeView_position.
    ; The first one has 16-bit, the latter one 24-bit components.

    ngin_mov16 ngin_Camera_position+ngin_Vector2_16_8::intX, \
               __ngin_Camera_initializeView_position+ngin_Vector2_16::x_
    ngin_mov16 ngin_Camera_position+ngin_Vector2_16_8::intY, \
               __ngin_Camera_initializeView_position+ngin_Vector2_16::y_

    ; Set the fractional part of ngin_Camera_position.
    ngin_mov8 ngin_Camera_position+ngin_Vector2_16_8::fracX, #0
    ngin_mov8 ngin_Camera_position+ngin_Vector2_16_8::fracY, #0

    rts
.endproc

; \todo Use temporaries.
__ngin_bss leftEdge:            .tag ngin_FixedPoint16_8
__ngin_bss rightEdge:           .tag ngin_FixedPoint16_8
__ngin_bss newCameraPosition:   .tag ngin_FixedPoint16_8
__ngin_bss newCameraPositionHi: .tag ngin_FixedPoint16_8
__ngin_bss oldCameraPositionHi: .tag ngin_FixedPoint16_8
__ngin_bss scrollAmount:        .byte 0

.macro __ngin_Camera_move_clampToIndirectBoundary boundary, lobyte, branch
    ; This is equivalent to ngin_cmp24, but it doesn't support indirect
    ; addressing, so have to do it manually.
    ; Compare each byte, starting from the hibyte. If not equal, flags
    ; hold the 24-bit comparison result.
    ldy #(boundary)+1
    ngin_cmp8 newCameraPosition+2, { ( ngin_MapData_header ), y }
    bne hibyteNotEqual
    dey
    ngin_cmp8 newCameraPosition+1, { ( ngin_MapData_header ), y }
    bne hibyteNotEqual
    ngin_cmp8 newCameraPosition+0, {lobyte}
    .local hibyteNotEqual
    hibyteNotEqual:
    branch noClamp
        ; newCameraPosition < "boundary" => clamp
        ldy #(boundary)+1
        ngin_mov8 newCameraPosition+2, { ( ngin_MapData_header ), y }
        dey
        ngin_mov8 newCameraPosition+1, { ( ngin_MapData_header ), y }
        ngin_mov8 newCameraPosition+0, {lobyte}
    .local noClamp
    noClamp:
.endmacro

.macro __ngin_Camera_move_template fracX, moveAmountX, x_, mapScrollHorizontal, \
        objectSpawnerScrollHorizontal

    ; \todo Some redundant calculations going on here.
    ; \todo Only need to calculate max if moving right, only need the min
    ;       if moving left.

    ; Calculate the minimum and maximum values for camera position based on
    ; the current camera position and the maximum amount of pixels that the
    ; MapScroller module can scroll per frame.

    ; Right side: ceil(cameraPos - 0.5) + kMaxScrollPerFrame + 0.5
    ngin_sub24 rightEdge, ngin_Camera_position + ngin_Vector2_16_8::x_, \
               #ngin_immFixedPoint16_8 0, 128 ; -0.5
    ngin_add24 rightEdge, #ngin_immFixedPoint16_8 0, 255 ; Ceil
    ngin_mov8  rightEdge+0, #0 ; Ceil (cont.)
    ngin_add16 rightEdge+1, #ngin_MapScroller_kMaxScrollPerCall
    ; -1 to make the right side inclusive (default: exclusive)
    ngin_add24 rightEdge, #ngin_immFixedPoint16_8 0, 128-1 ; +0.5

    ; Left side: floor(cameraPos - 0.5) - kMaxScrollPerFrame + 0.5
    ngin_sub24 leftEdge, ngin_Camera_position + ngin_Vector2_16_8::x_, \
               #ngin_immFixedPoint16_8 0, 128 ; -0.5
    ngin_mov8  leftEdge+0, #0 ; Floor
    ngin_sub16 leftEdge+1, #ngin_MapScroller_kMaxScrollPerCall
    ; \todo The floor and this are redundant, since they will always simply
    ;       force the lobyte to 128. Same goes for ceil() above.
    ngin_add24 leftEdge, #ngin_immFixedPoint16_8 0, 128 ; +0.5

    ; -------------------------------------------------------------------------

    ; Calculate the new candidate camera position by adding the movement amount.
    ; The amount needs to be sign-extended. ngin_add24_16s can't handle more
    ; than two arguments right now, so move the data first.
    ; \todo Sign-extension not needed if we handle the positive/negative
    ;       cases in separate paths.
    ngin_mov24 newCameraPosition, ngin_Camera_position + ngin_Vector2_16_8::x_
    ngin_add24_16s newCameraPosition, moveAmountX

    ; -------------------------------------------------------------------------

    ; Clamp the new camera position to the left and right maximum.

    ngin_cmp24 newCameraPosition, rightEdge
    ngin_branchIfLess lessThanRightEdge
        ; newCameraPosition >= rightEdge, clamp
        ; (the equality comparison is not necessary, but doesn't hurt)
        ngin_mov24 newCameraPosition, rightEdge
    .local lessThanRightEdge
    lessThanRightEdge:

    ngin_cmp24 newCameraPosition, leftEdge
    ngin_branchIfGreaterOrEqual greaterOrEqualToLeftEdge
        ; newCameraPosition < leftEdge, clamp
        ngin_mov24 newCameraPosition, leftEdge
    .local greaterOrEqualToLeftEdge
    greaterOrEqualToLeftEdge:

    ; -------------------------------------------------------------------------

    ; Clamp to map boundaries coming from the map data.

    ; Use a scope to avoid duplicate symbols boundaryLeft/boundaryRight.
    .scope
        ; Pick different struct members depending on movement direction.
        .if .xmatch( x_, y_ )
            boundaryLeft  = ngin_MapData_Header::boundaryTop
            boundaryRight = ngin_MapData_Header::boundaryBottom
        .else
            boundaryLeft  = ngin_MapData_Header::boundaryLeft
            boundaryRight = ngin_MapData_Header::boundaryRight
        .endif

        ; Constant 0 is used for the lowbyte at the left edge, and constant 255
        ; at the right edge. The reason for 255 is that it's the maximum
        ; subpixel offset within a pixel, and the boundary is inclusive.
        __ngin_Camera_move_clampToIndirectBoundary \
            boundaryLeft,  #0,   ngin_branchIfGreaterOrEqual
        __ngin_Camera_move_clampToIndirectBoundary \
            boundaryRight, #255, ngin_branchIfLess
    .endscope
    ; -------------------------------------------------------------------------

    ; Calculate how much the map should be scrolled.
    ngin_sub24 newCameraPositionHi, newCameraPosition, \
               #ngin_immFixedPoint16_8 0, 128 ; -0.5
    ngin_sub24 oldCameraPositionHi, ngin_Camera_position + \
               ngin_Vector2_16_8::x_, #ngin_immFixedPoint16_8 0, 128 ; -0.5
    ; Result always fits in a byte, so no reason to calculate hibyte.
    ; \todo Could skip much of the above calculation for the same reason.
    sec
    ngin_sbc8 newCameraPositionHi+1, oldCameraPositionHi+1
    sta scrollAmount

    ; -------------------------------------------------------------------------

    ; Apply the new camera position. Call MapScroller and ObjectSpawner.

    ngin_mov24 ngin_Camera_position + ngin_Vector2_16_8::x_, newCameraPosition

    mapScrollHorizontal scrollAmount
    objectSpawnerScrollHorizontal scrollAmount
.endmacro

.proc __ngin_Camera_move
    __ngin_Camera_move_template fracX, __ngin_Camera_move_amountX, x_, \
        ngin_MapScroller_scrollHorizontal, ngin_ObjectSpawner_scrollHorizontal

    __ngin_Camera_move_template fracY, __ngin_Camera_move_amountY, y_, \
        ngin_MapScroller_scrollVertical, ngin_ObjectSpawner_scrollVertical

    rts
.endproc
