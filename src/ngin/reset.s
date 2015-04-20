.include "reset-private.inc"
.include "ngin/ppu.inc"
.include "ngin/lua/lua.inc"

; \todo The order in which ngin_Lua_requires are processed is not defined,
;       could be a problem.
; \todo Add a macro to ndxdebug.inc to execute a Lua file that is embedded
;       into the debug information at compile time. Note that require()
;       might be problematic for embedded code.
ngin_Lua_require "lua/reset.lua"

.segment "NGIN_RESET_CODE"

.proc __ngin_reset
    ; \todo Proper reset code
    lda #0
    sta ppu::ctrl
    sta ppu::mask

    ; __ngin_start is defined in the user application with the ngin_entryPoint
    ; macro.
    .import __ngin_start
    jmp __ngin_start
.endproc

; Force the NGIN_CODE segment to exist, even if it's empty.
.segment "NGIN_CODE"
