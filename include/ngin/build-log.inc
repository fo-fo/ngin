.if .not .defined( NGIN_BUILD_LOG_INC_INCLUDED )
NGIN_BUILD_LOG_INC_INCLUDED = 1

.include "ngin/core.inc"

.macro ngin_BuildLog_string string
    .byte string
.endmacro

.macro ngin_BuildLog_newLine
    ; Use Windows newline for compatibility.
    .byte 13, 10
.endmacro

.macro ngin_BuildLog_decimalInteger integer
    .local divider
    divider .set 100000000
    .local value
    value = integer
    .repeat 9, i
        ; Output the corresponding digit, or a space if the digit and all the
        ; more significant digits are zeroes. Unless we're outputting the least
        ; significant digit, which is always displayed (so that 0 is displayed).
        .byte .lobyte( __ngin_choice \
            (value/divider) <> 0 .or divider = 1, \
            (value/divider) .mod 10 + '0', \
            ' ' )
        divider .set divider/10
    .endrepeat
.endmacro

.endif
