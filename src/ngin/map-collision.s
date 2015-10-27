.include "ngin/map-collision.inc"
.include "ngin/lua/lua.inc"

ngin_Lua_require "map-collision.lua"

.segment "NGIN_BSS"

; Arguments
__ngin_MapCollision_lineSegmentEjectHorizontal_x:               .word 0
__ngin_MapCollision_lineSegmentEjectHorizontal_y0:              .word 0
__ngin_MapCollision_lineSegmentEjectHorizontal_length:          .byte 0
__ngin_MapCollision_lineSegmentEjectHorizontal_deltaX:          .byte 0
__ngin_MapCollision_lineSegmentEjectHorizontal_flags:           .byte 0
; Return values
ngin_MapCollision_lineSegmentEjectHorizontal_ejectedX:          .word 0
ngin_MapCollision_lineSegmentEjectHorizontal_scannedAttributes: .byte 0

; Reuse the memory for the vertical cases.
__ngin_MapCollision_lineSegmentEjectVertical_y := \
    __ngin_MapCollision_lineSegmentEjectHorizontal_x
__ngin_MapCollision_lineSegmentEjectVertical_x0 := \
    __ngin_MapCollision_lineSegmentEjectHorizontal_y0
__ngin_MapCollision_lineSegmentEjectVertical_length := \
    __ngin_MapCollision_lineSegmentEjectHorizontal_length
__ngin_MapCollision_lineSegmentEjectVertical_deltaY := \
    __ngin_MapCollision_lineSegmentEjectHorizontal_deltaX
__ngin_MapCollision_lineSegmentEjectVertical_flags := \
    __ngin_MapCollision_lineSegmentEjectHorizontal_flags
ngin_MapCollision_lineSegmentEjectVertical_ejectedY := \
    ngin_MapCollision_lineSegmentEjectHorizontal_ejectedX
ngin_MapCollision_lineSegmentEjectVertical_scannedAttributes := \
    ngin_MapCollision_lineSegmentEjectHorizontal_scannedAttributes

; Reuse memory for the overlapping versions.
__ngin_MapCollision_lineSegmentOverlapHorizontal_x := \
    __ngin_MapCollision_lineSegmentEjectHorizontal_x
__ngin_MapCollision_lineSegmentOverlapHorizontal_y0 := \
    __ngin_MapCollision_lineSegmentEjectHorizontal_y0
__ngin_MapCollision_lineSegmentOverlapHorizontal_length := \
    __ngin_MapCollision_lineSegmentEjectHorizontal_length
ngin_MapCollision_lineSegmentOverlapHorizontal_scannedAttributes := \
    ngin_MapCollision_lineSegmentEjectHorizontal_scannedAttributes

__ngin_MapCollision_lineSegmentOverlapVertical_y := \
    __ngin_MapCollision_lineSegmentEjectHorizontal_x
__ngin_MapCollision_lineSegmentOverlapVertical_x0 := \
    __ngin_MapCollision_lineSegmentEjectHorizontal_y0
__ngin_MapCollision_lineSegmentOverlapVertical_length := \
    __ngin_MapCollision_lineSegmentEjectHorizontal_length
ngin_MapCollision_lineSegmentOverlapVertical_scannedAttributes := \
    ngin_MapCollision_lineSegmentEjectHorizontal_scannedAttributes

.segment "NGIN_CODE"

.proc __ngin_MapCollision_lineSegmentEjectHorizontal
    ngin_Lua_string "ngin.MapCollision.lineSegmentEjectHorizontal()"

    rts
.endproc

.proc __ngin_MapCollision_lineSegmentEjectVertical
    ngin_Lua_string "ngin.MapCollision.lineSegmentEjectVertical()"

    rts
.endproc

.proc __ngin_MapCollision_lineSegmentOverlapHorizontal
    ngin_Lua_string "ngin.MapCollision.lineSegmentOverlapHorizontal()"

    rts
.endproc

.proc __ngin_MapCollision_lineSegmentOverlapVertical
    ngin_Lua_string "ngin.MapCollision.lineSegmentOverlapVertical()"

    rts
.endproc
