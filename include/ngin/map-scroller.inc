.if .not .defined( NGIN_MAP_SCROLLER_INC_INCLUDED )
NGIN_MAP_SCROLLER_INC_INCLUDED = 1

.include "ngin/core.inc"

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

.endif
