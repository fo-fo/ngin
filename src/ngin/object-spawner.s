.include "ngin/object-spawner.inc"
.include "ngin/lua/lua.inc"

ngin_Lua_require "object-spawner.lua"

.segment "NGIN_BSS"

__ngin_ObjectSpawner_setPosition_position:      .tag ngin_Vector2_16
__ngin_ObjectSpawner_scrollHorizontal_amount:   .byte 0
__ngin_ObjectSpawner_scrollVertical_amount:     .byte 0

.segment "NGIN_CODE"

.proc __ngin_ObjectSpawner_setPosition
    ngin_Lua_string "ngin.ObjectSpawner.setPosition()"

    rts
.endproc

.proc __ngin_ObjectSpawner_scrollHorizontal
    ngin_Lua_string "ngin.ObjectSpawner.scrollHorizontal()"

    rts
.endproc

.proc __ngin_ObjectSpawner_scrollVertical
    ngin_Lua_string "ngin.ObjectSpawner.scrollVertical()"

    rts
.endproc
