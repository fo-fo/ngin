.if .not .defined( NGIN_MAP_SCROLLER_INC_INCLUDED )
NGIN_MAP_SCROLLER_INC_INCLUDED = 1

.include "ngin/core.inc"

; How many pixels (max) can be scrolled per each call to the scroll functions
ngin_MapScroller_kMaxScrollPerCall = 8

; Sets the scroll position counters of the MapScroller based on the specified
; coordinates (in world space).
.global __ngin_MapScroller_setPosition
.global __ngin_MapScroller_setPosition_position
.macro ngin_MapScroller_setPosition position
    __ngin_requireParameter {position}, "position"

    ngin_mov32 __ngin_MapScroller_setPosition_position, {position}

    jsr __ngin_MapScroller_setPosition
.endmacro

.global __ngin_MapScroller_scrollHorizontal
.global __ngin_MapScroller_scrollHorizontal_amount
.macro ngin_MapScroller_scrollHorizontal amount
    __ngin_requireParameter {amount}, "amount"

    ngin_mov8 __ngin_MapScroller_scrollHorizontal_amount, {amount}

    jsr __ngin_MapScroller_scrollHorizontal
.endmacro

.global __ngin_MapScroller_scrollVertical
.global __ngin_MapScroller_scrollVertical_amount
.macro ngin_MapScroller_scrollVertical amount
    __ngin_requireParameter {amount}, "amount"

    ngin_mov8 __ngin_MapScroller_scrollVertical_amount, {amount}

    jsr __ngin_MapScroller_scrollVertical
.endmacro

; Retrieves the PPU scroll register values (ppu::ctrl, ppu::scroll) needed to
; display the map based on the current map position.
.global __ngin_MapScroller_ppuRegisters
.macro ngin_MapScroller_ppuRegisters
    ; \todo Verify that no parameters were passed.

    jsr __ngin_MapScroller_ppuRegisters
.endmacro

.endif
