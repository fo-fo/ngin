.include "ngin/map-collision.inc"
.include "ngin/lua/lua.inc"

ngin_Lua_require "map-collision.lua"

.segment "NGIN_BSS"

; Arguments
__ngin_MapCollision_lineSegmentEjectHorizontal_x:       .word 0
__ngin_MapCollision_lineSegmentEjectHorizontal_y0:      .word 0
__ngin_MapCollision_lineSegmentEjectHorizontal_length:  .byte 0
__ngin_MapCollision_lineSegmentEjectHorizontal_deltaX:  .byte 0
; Return values
ngin_MapCollision_lineSegmentEjectHorizontal_ejectedX:  .word 0

; Reuse the memory for the vertical cases.
__ngin_MapCollision_lineSegmentEjectVertical_y := \
    __ngin_MapCollision_lineSegmentEjectHorizontal_x
__ngin_MapCollision_lineSegmentEjectVertical_x0 := \
    __ngin_MapCollision_lineSegmentEjectHorizontal_y0
__ngin_MapCollision_lineSegmentEjectVertical_length := \
    __ngin_MapCollision_lineSegmentEjectHorizontal_length
__ngin_MapCollision_lineSegmentEjectVertical_deltaY := \
    __ngin_MapCollision_lineSegmentEjectHorizontal_deltaX
ngin_MapCollision_lineSegmentEjectVertical_ejectedY := \
    ngin_MapCollision_lineSegmentEjectHorizontal_ejectedX

.segment "NGIN_CODE"

.proc __ngin_MapCollision_lineSegmentEjectHorizontal
    ngin_Lua_string "ngin.MapCollision.lineSegmentEjectHorizontal()"

    rts
.endproc

.proc __ngin_MapCollision_lineSegmentEjectVertical
    ngin_Lua_string "ngin.MapCollision.lineSegmentEjectVertical()"

    rts
.endproc
