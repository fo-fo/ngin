.include "ngin/map-scroller.inc"
.include "ngin/lua/lua.inc"

ngin_Lua_require "map-scroller.lua"

.segment "NGIN_BSS"

__ngin_MapScroller_scrollHorizontal_amount: .byte 0
__ngin_MapScroller_scrollVertical_amount:   .byte 0

.segment "NGIN_CODE"

.proc __ngin_MapScroller_scrollHorizontal
    ngin_Lua_string "ngin.MapScroller.scrollHorizontal()"

    rts
.endproc

.proc __ngin_MapScroller_scrollVertical
    ngin_Lua_string "ngin.MapScroller.scrollVertical()"

    rts
.endproc
