.if .not .defined( NGIN_UTIL_INC_INCLUDED )
NGIN_UTIL_INC_INCLUDED = 1

; Characters that are used to define tiles with ngin_tile
.define __ngin_tileChars " .:#"

.macro __ngin_tileBitPlane strings, mask
    .assert .tcount( {strings} ) = 8, error

    ; \todo Allow to specify multiple tiles at once, by having more than
    ;       8 characters on a line (any multiple of 8), and more than 8
    ;       lines.

    .repeat .tcount( {strings} ), i
        .define __ngin_tileString .mid( i, 1, {strings} )
        .assert .strlen( __ngin_tileString ) = 8, error
        .local byteValue
        byteValue .set 0
        .repeat .strlen( __ngin_tileString ), j
            .local bitValue
            bitValue .set 0
            .repeat .strlen( __ngin_tileChars ), k
                .if .strat( __ngin_tileString, j ) = \
                        .strat( __ngin_tileChars, k )
                    bitValue .set !!( k & mask )
                .endif
            .endrepeat
            byteValue .set (byteValue << 1) | bitValue
        .endrepeat
        .byte byteValue
        .undefine __ngin_tileString
    .endrepeat
.endmacro

; This macro can be used to define a tile directly in code with a string.
.macro ngin_tile strings
    __ngin_tileBitPlane {strings}, %01
    __ngin_tileBitPlane {strings}, %10
.endmacro

.endif
