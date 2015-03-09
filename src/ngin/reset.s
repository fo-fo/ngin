.include "reset.inc"
.include "ngin/ppu.inc"
.include "ngin/lua/lua.inc"

.segment "NGIN_CODE"

.proc __ngin_reset
    ; \todo Add a macro to ndxdebug.inc to execute a Lua file that is embedded
    ;       into the debug information at compile time.
    ngin_Lua_file "lua/reset.lua"

    ; \todo Proper reset code
    lda #0
    sta ppu::ctrl
    sta ppu::mask

    ; __ngin_start is defined in the user application with the ngin_entryPoint
    ; macro.
    .import __ngin_start
    jmp __ngin_start
.endproc
