.include "reset-private.inc"
.include "ngin/ppu.inc"
.include "ngin/lua/lua.inc"
.include "ngin/branch.inc"

; \todo The order in which ngin_Lua_requires are processed is not defined,
;       could be a problem.
; \todo Add a macro to ndxdebug.inc to execute a Lua file that is embedded
;       into the debug information at compile time. Note that require()
;       might be problematic for embedded code.
ngin_Lua_require "lua/reset.lua"

kRamSize  = 2*1024
kPageSize = 256

.segment "NGIN_RESET_PROLOGUE"
.proc __ngin_reset
    ; \todo Proper reset code
    lda #0
    sta ppu::ctrl
    sta ppu::mask

    ; Acknowledge APU frame IRQ and disable further IRQs.
    lda #%0100_0000
    sta $4017

    ; Initialize stack pointer.
    ldx #$FF
    txs

    ; Clear the RAM.
    ; \note Can't use ngin_fillMemory here (at least to clear whole memory
    ;       without multiple calls), because it needs the stack to return.
    ; \todo At least for debug mode, it might make sense to only clear the
    ;       part of RAM that is used for BSS. That way the rest of the memory
    ;       could still generate uninitialized memory access diagnostics.
    lda #0
    sta 0
    sta 1
    ldx #kRamSize / kPageSize
    ; Start from the second byte, because we're using the first two bytes
    ; as a pointer.
    ldy #2
    clearAll:
        clearPage:
            sta ( 0 ), y
            iny
        ngin_branchIfNotZero clearPage
        inc 1
        dex
    ngin_branchIfNotZero clearAll
    ; Finally, clear the pointer hibyte.
    sta 1

    ; Fall through to NGIN_MAPPER_INIT segment. Commented out so that a
    ; warning is given if it's not defined by the mapper file.
    ; .segment "NGIN_MAPPER_INIT"
    ; -------------------------------------------------------------------------
    ; Fall through to NGIN_RESET_CONSTRUCTORS segment.
    ; Make sure the segment exists.
    .segment "NGIN_RESET_CONSTRUCTORS"
    ; -------------------------------------------------------------------------
    ; Execution continues from NGIN_RESET_CONSTRUCTORS segment to this segment.
    .segment "NGIN_RESET_EPILOGUE"

    ; __ngin_start is defined in the user application with the ngin_entryPoint
    ; macro.
    .import __ngin_start
    jmp __ngin_start
.endproc

; Force the NGIN_CODE segment to exist, even if it's empty.
.segment "NGIN_CODE"
