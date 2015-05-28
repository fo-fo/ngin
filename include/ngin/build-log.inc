.if .not .defined( NGIN_BUILD_LOG_INC_INCLUDED )
NGIN_BUILD_LOG_INC_INCLUDED = 1

.include "ngin/core.inc"

.macro __ngin_BuildLog_string string
    ; \todo Charmaps will mess things up here. .strat() can't be used to bypass
    ;       because it applies the charmap also.
    .byte string
.endmacro

.macro __ngin_BuildLog_newLine
    ; Use Windows newline for compatibility.
    .byte ngin_Ascii::kCr, ngin_Ascii::kLf
.endmacro

.macro ngin_BuildLog_string string
    ngin_pushSeg "BUILD_LOG"
    __ngin_BuildLog_string {string}
    ngin_popSeg
.endmacro

.macro ngin_BuildLog_newLine
    ngin_pushSeg "BUILD_LOG"
    __ngin_BuildLog_newLine
    ngin_popSeg
.endmacro

.macro ngin_BuildLog_decimalInteger integer
    ngin_pushSeg "BUILD_LOG"
    __ngin_decimalInteger {integer}
    ngin_popSeg
.endmacro

.endif
