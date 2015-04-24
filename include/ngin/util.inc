.if .not .defined( NGIN_UTIL_INC_INCLUDED )
NGIN_UTIL_INC_INCLUDED = 1

; Characters that are used to define tiles with ngin_tile
.define __ngin_tileChars " .:#"

.macro __ngin_tilePixelRow tileString, mask, offset
    .local byteValue
    byteValue .set 0
    .repeat 8, j
        .local bitValue
        bitValue .set 0
        .repeat .strlen( __ngin_tileChars ), k
            .if .strat( tileString, j+offset ) = .strat( __ngin_tileChars, k )
                bitValue .set !!( k & mask )
            .endif
        .endrepeat
        byteValue .set (byteValue << 1) | bitValue
    .endrepeat
    .byte byteValue
.endmacro

.macro __ngin_tileBitPlane strings, mask, i, j, numColumns
    .repeat 8, k
        .define __ngin_tileString .mid( 8*j+k, 1, {strings} )
        ; Every string must have the same length.
        .assert .strlen( __ngin_tileString ) = numColumns, error
        __ngin_tilePixelRow {__ngin_tileString}, mask, 8*i
        .undefine __ngin_tileString
    .endrepeat
.endmacro

; This macro can be used to define a tile directly in code with a string.
.macro ngin_tile strings
    .local numLines
    numLines = .tcount( {strings} )
    .assert numLines .mod 8 = 0, error

    .local numColumns
    numColumns = .strlen( .mid( 0, 1, {strings} ) )
    .assert numColumns .mod 8 = 0, error

    .local numTilesY
    numTilesY = numLines/8
    .local numTilesX
    numTilesX = numColumns/8

    .repeat numTilesY, j
        .repeat numTilesX, i
            __ngin_tileBitPlane {strings}, %01, i, j, numColumns
            __ngin_tileBitPlane {strings}, %10, i, j, numColumns
        .endrepeat
    .endrepeat
.endmacro

.endif
