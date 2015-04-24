.if .not .defined( NGIN_MAP_COLLISION_INC_INCLUDED )
NGIN_MAP_COLLISION_INC_INCLUDED = 1

.include "ngin/core.inc"

; Checks for a collision of a vertical line segment against solid tiles in the
; map (in horizontal movement). Returns ejected X coordinate.
; x:        Current X coordinate
; y0:       Y coordinate of the first point of the line segment
; length:   Length of the line segment in downwards direction (exclusive; 0 is
;           an empty line segment)
; deltaX:   Horizontal movement amount (added to X)
; Return values:
; ejectedX: The ejected X coordinate (16-bit)
.global __ngin_MapCollision_lineSegmentEjectHorizontal
.global __ngin_MapCollision_lineSegmentEjectHorizontal_x
.global __ngin_MapCollision_lineSegmentEjectHorizontal_y0
.global __ngin_MapCollision_lineSegmentEjectHorizontal_length
.global __ngin_MapCollision_lineSegmentEjectHorizontal_deltaX
.global ngin_MapCollision_lineSegmentEjectHorizontal_ejectedX
.macro ngin_MapCollision_lineSegmentEjectHorizontal x_, y0, length, deltaX
    __ngin_requireParameter {x_},     "x_"
    __ngin_requireParameter {y0},     "y0"
    __ngin_requireParameter {length}, "length"
    __ngin_requireParameter {deltaX}, "deltaX"

    ngin_mov16 __ngin_MapCollision_lineSegmentEjectHorizontal_x,      {x_}
    ngin_mov16 __ngin_MapCollision_lineSegmentEjectHorizontal_y0,     {y0}
    ngin_mov8  __ngin_MapCollision_lineSegmentEjectHorizontal_length, {length}
    ngin_mov8  __ngin_MapCollision_lineSegmentEjectHorizontal_deltaX, {deltaX}

    jsr __ngin_MapCollision_lineSegmentEjectHorizontal
.endmacro

; Same as ngin_MapCollision_lineSegmentEjectHorizontal, but used for vertical
; movement.
.global __ngin_MapCollision_lineSegmentEjectVertical
.global __ngin_MapCollision_lineSegmentEjectVertical_y
.global __ngin_MapCollision_lineSegmentEjectVertical_x0
.global __ngin_MapCollision_lineSegmentEjectVertical_length
.global __ngin_MapCollision_lineSegmentEjectVertical_deltaY
.global ngin_MapCollision_lineSegmentEjectVertical_ejectedY
.macro ngin_MapCollision_lineSegmentEjectVertical y_, x0, length, deltaY
    __ngin_requireParameter {y_},     "y_"
    __ngin_requireParameter {x0},     "x0"
    __ngin_requireParameter {length}, "length"
    __ngin_requireParameter {deltaY}, "deltaY"

    ngin_mov16 __ngin_MapCollision_lineSegmentEjectVertical_y,      {y_}
    ngin_mov16 __ngin_MapCollision_lineSegmentEjectVertical_x0,     {x0}
    ngin_mov8  __ngin_MapCollision_lineSegmentEjectVertical_length, {length}
    ngin_mov8  __ngin_MapCollision_lineSegmentEjectVertical_deltaY, {deltaY}

    jsr __ngin_MapCollision_lineSegmentEjectVertical
.endmacro

.endif
