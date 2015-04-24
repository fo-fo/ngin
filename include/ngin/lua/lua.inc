.if .not .defined( NGIN_LUA_INC_INCLUDED )
NGIN_LUA_INC_INCLUDED = 1

.include "ndx/ndxdebug.inc"

; This can be passed to ngin_Lua_string (and other macros) to make sure that
; the Lua code is associated with a unique address in the program.
ngin_Lua_kUniqueAddress = 1

.macro ngin_Lua_string string, uniqueAddress
    ndxLuaExecStr {string}, {uniqueAddress}
.endmacro

.macro ngin_Lua_file filename, uniqueAddress
    ndxLuaExecFile {filename}, {uniqueAddress}
.endmacro

.macro ngin_Lua_require filename
    ; Use an empty segment that is placed at the reset handler to include
    ; all of the required Lua files.
    .pushseg
    .segment "NGIN_LUA_REQUIRE"
        ; \todo Would be better to use something akin to Lua's require() here,
        ;       so that double inclusion could be avoided. Should be doable
        ;       by modifying NDX's string execution to include the current
        ;       source file in the search path, and then using ngin_Lua_string
        ;       here to require() the file.
        ngin_Lua_file {filename}
    .popseg
.endmacro

.endif
