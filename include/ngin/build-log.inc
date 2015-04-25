.if .not .defined( NGIN_BUILD_LOG_INC_INCLUDED )
NGIN_BUILD_LOG_INC_INCLUDED = 1

.include "ngin/core.inc"
.include "ngin/ascii.inc"

.macro ngin_BuildLog_string string
    ; \todo Charmaps will mess things up here. .strat() can't be used to bypass
    ;       because it applies the charmap also.
    .byte string
.endmacro

.macro ngin_BuildLog_newLine
    ; Use Windows newline for compatibility.
    .byte ngin_Ascii::kCr, ngin_Ascii::kLf
.endmacro

.macro ngin_BuildLog_decimalInteger integer
    .local divider
    divider .set 100000000
    .local value
    value = integer

    ; \note .charmap isn't a problem here, because string/character literals
    ;       are not used.

    .repeat 9, i
        ; Output the corresponding digit, or a space if the digit and all the
        ; more significant digits are zeroes. Unless we're outputting the least
        ; significant digit, which is always displayed (so that 0 is displayed).
        .byte .lobyte( __ngin_choice \
            (value/divider) <> 0 .or divider = 1, \
            (value/divider) .mod 10 + ngin_Ascii::kZero, \
            ngin_Ascii::kSpace )
        divider .set divider/10
    .endrepeat
.endmacro

.endif
