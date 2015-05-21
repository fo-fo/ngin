.include "ngin/object-spawner.inc"
.include "ngin/lua/lua.inc"
.include "ngin/object.inc"

ngin_Lua_require "object-spawner.lua"

.segment "NGIN_BSS"

ngin_ObjectSpawner_spawnIndex:                  .byte 0

; For each map object index, a bit indicating whether the object has been
; spawned already.
; \todo This wastes memory if there are less than kMaxMapObjects objects in any
;       map that is in use. However, the size can't be easily modified at
;       compile time because .res needs a constant.
__ngin_ObjectSpawner_spawned:           .res ngin_bitFieldSize \
                                             ngin_ObjectSpawner_kMaxMapObjects

; Parameters:
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
