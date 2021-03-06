.if .not .defined( NGIN_CORE_INC_INCLUDED )
NGIN_CORE_INC_INCLUDED = 1

; Enable line continuation with backslash (unfortunately not a .feature)
.linecont +

; Needed by __ngin_decimalInteger.
.include "ngin/ascii.inc"

.macro ngin_entryPoint entrySymbol
    .export __ngin_start := entrySymbol
.endmacro

.macro ngin_irqHandler irqSymbol
    .export __ngin_irq := irqSymbol
.endmacro

.macro __ngin_requireParameter ident, identString
    .if .blank( {ident} )
        .error .sprintf( "parameter '%s' is required", identString )
    .endif
.endmacro

.macro __ngin_requireImmediate ident, identString
    .if .not .match( .left( 1, {ident} ), # )
        .error .sprintf( "parameter '%s' has to be an immediate", identString )
    .endif
.endmacro

.define __ngin_choice( condition, if, else ) \
    ((!!(condition)) * (if) + (!(condition)) * (else))

.enum ngin_Bool
    kFalse
    kTrue
.endenum

__ngin_mov8_baseCount .set 0

.macro ngin_mov8 to, from
    __ngin_requireParameter {to}, "to"
    __ngin_requireParameter {from}, "from"

    .local skipLoad
    skipLoad .set ngin_Bool::kFalse

    ; If "from" is an immediate value, we might be able to optimize out
    ; some redundant loads.
    ; \todo Make the optimization optional.
    .if .match( .left( 1, {from} ), # )
        .local fromStripped
        fromStripped = .right( .tcount( {from} ) - 1, {from} )
        ; Must know the value to be able to optimize.
        .if .const( fromStripped )
            ; If baseCount is non-zero, a previous ngin_mov8 has occurred.
            .if ::__ngin_mov8_baseCount <> 0
                ; Calculate offset to the end of previous ngin_mov8.
                .local offsetToPrevious
                offsetToPrevious = * - ::.ident( .sprintf( "__ngin_mov8_base%d", \
                                                     ::__ngin_mov8_baseCount-1 ) )

                ; If offsetToPrevious is 0, no other instructions have occurred
                ; between this and the previous instance.
                ; \note offsetToPrevious can be non-const in case the label
                ;       is in a different segment.
                .if .const( offsetToPrevious ) .and offsetToPrevious = 0
                    ; If the value matches the previous one, skip the load.
                    .if ::__ngin_mov8_previousValue = fromStripped
                        skipLoad .set ngin_Bool::kTrue
                    .endif
                .endif
            .endif
            ; Set a new base, and save the value that is known to be in A.
            ::.ident( .sprintf( "__ngin_mov8_base%d", ::__ngin_mov8_baseCount ) ) \
                := staEnd
            ::__ngin_mov8_baseCount .set ::__ngin_mov8_baseCount + 1
            ::__ngin_mov8_previousValue .set fromStripped
        .endif
    .endif

    .if .not skipLoad
        lda from
    .endif
    sta to
    .local staEnd
    staEnd:
.endmacro

; Special marker embedded into an expression as a multiplier to piggyback
; the stride information into the expression. "id" has to be an identifier
; in global scope.
__ngin_strideSpecifier = 0
.define __ngin_stride( id ) (::__ngin_strideSpecifier * ::id)

.macro __ngin_getOperandStride operand, stride
    ; Set the defaults.
    stride      .set 1

    ; See if the operand matches the special format used for stride specifiers.
    ; In case multiple stride specifiers are found, the last one is used.
    ; \todo Allow numeric values (instead of just an identifier) for the stride.
    ; \note The stride value has to be in the global scope and specified with
    ;       the global scope prefix.
    .repeat .tcount( {operand} ), i
        .if .xmatch( .mid( i, 5, {operand} ), {(::__ngin_strideSpecifier*::} )
            .if .match( .mid( i+5, 3, {operand} ), {id)+} )
                stride .set ::.mid( i+5, 1, {operand} )
            .endif
        .endif
    .endrepeat
.endmacro

.macro ngin_mov16 to, from
    __ngin_requireParameter {to}, "to"
    __ngin_requireParameter {from}, "from"

    __ngin_getOperandStride {to},   __ngin_mov16_strideTo
    __ngin_getOperandStride {from}, __ngin_mov16_strideFrom

    .if .match( .left( 1, {from} ), # )
        .local fromStripped
        fromStripped = .right( .tcount( {from} ) - 1, {from} )
        ngin_mov8 { 0*__ngin_mov16_strideTo+to }, #.lobyte( fromStripped )
        ngin_mov8 { 1*__ngin_mov16_strideTo+to }, #.hibyte( fromStripped )
    .else
        ngin_mov8 { 0*__ngin_mov16_strideTo+to }, \
                  { 0*__ngin_mov16_strideFrom+from }
        ngin_mov8 { 1*__ngin_mov16_strideTo+to }, \
                  { 1*__ngin_mov16_strideFrom+from }
    .endif
.endmacro

.macro ngin_mov24 to, from
    __ngin_requireParameter {to}, "to"
    __ngin_requireParameter {from}, "from"

    __ngin_getOperandStride {to},   __ngin_mov24_strideTo
    __ngin_getOperandStride {from}, __ngin_mov24_strideFrom

    .if .match( .left( 1, {from} ), # )
        .local fromStripped
        fromStripped = .right( .tcount( {from} ) - 1, {from} )
        ngin_mov16 { 0*__ngin_mov24_strideTo+to }, #.loword( fromStripped )
        ngin_mov8  { 2*__ngin_mov24_strideTo+to }, #.lobyte( .hiword( fromStripped ) )
    .else
        ngin_mov16 { 0*__ngin_mov24_strideTo+to }, \
                   { 0*__ngin_mov24_strideFrom+from }
        ngin_mov8  { 2*__ngin_mov24_strideTo+to }, \
                   { 2*__ngin_mov24_strideFrom+from }
    .endif
.endmacro

.macro ngin_mov32 to, from
    __ngin_requireParameter {to}, "to"
    __ngin_requireParameter {from}, "from"

    __ngin_getOperandStride {to},   __ngin_mov32_strideTo
    __ngin_getOperandStride {from}, __ngin_mov32_strideFrom

    .if .match( .left( 1, {from} ), # )
        .local fromStripped
        fromStripped = .right( .tcount( {from} ) - 1, {from} )
        ngin_mov16 { 0*__ngin_mov32_strideTo+to }, #.loword( fromStripped )
        ngin_mov16 { 2*__ngin_mov32_strideTo+to }, #.hiword( fromStripped )
    .else
        ngin_mov16 { 0*__ngin_mov32_strideTo+to }, \
                   { 0*__ngin_mov32_strideFrom+from }
        ngin_mov16 { 2*__ngin_mov32_strideTo+to }, \
                   { 2*__ngin_mov32_strideFrom+from }
    .endif
.endmacro

.struct ngin_Vector2_8
    x_ .byte
    y_ .byte
.endstruct

.struct ngin_Vector2_16
    x_ .word
    y_ .word
.endstruct

.struct ngin_FixedPoint8_8
    frac    .byte
    int     .byte
.endstruct

.struct ngin_FixedPoint16_8
    frac    .byte
    int     .word
.endstruct

; \todo Maybe better to have these as an union in Vector2_16.
.union ngin_Vector2_8_8
    .struct
        fracX   .byte
        intX    .byte
        fracY   .byte
        intY    .byte
    .endstruct
    .struct
        x_      .tag ngin_FixedPoint8_8
        y_      .tag ngin_FixedPoint8_8
    .endstruct
.endunion

.union ngin_Vector2_16_8
    .struct
        fracX   .byte
        intX    .word
        fracY   .byte
        intY    .word
    .endstruct
    .struct
        x_      .tag ngin_FixedPoint16_8
        y_      .tag ngin_FixedPoint16_8
    .endstruct
.endunion

.define ngin_immVector2_16( x_, y_ ) ( (.loword( y_ ) << 16) | \
                                        .loword( x_ ) )

.define ngin_Vector2_16_immX( vector ) .loword( vector )
.define ngin_Vector2_16_immY( vector ) .hiword( vector )

.union ngin_BoundingBox16
    .struct
        leftTop     .tag ngin_Vector2_16
        rightBottom .tag ngin_Vector2_16
    .endstruct
    .struct
        left        .word
        top         .word
        right       .word
        bottom      .word
    .endstruct
.endunion

.define ngin_immBoundingBox8( left, top, right, bottom ) \
    ( (.lobyte( left   ) << 24) | \
      (.lobyte( top    ) << 16) | \
      (.lobyte( right  ) <<  8) | \
       .lobyte( bottom ) )

.define ngin_BoundingBox8_immLeft( boundingBox ) \
    .hibyte( .hiword( boundingBox ) )

.define ngin_BoundingBox8_immTop( boundingBox ) \
    .lobyte( .hiword( boundingBox ) )

.define ngin_BoundingBox8_immRight( boundingBox ) \
    .hibyte( boundingBox )

.define ngin_BoundingBox8_immBottom( boundingBox ) \
    .lobyte( boundingBox )

; Sign extend an 8-bit number to a full 32-bit number by duplicating the MSB
; in the upper bits.
.define ngin_signExtend8( number ) \
    ( ( ( 0 - ( .lobyte( number ) >> 7 ) ) << 8 ) | .lobyte( number ) )

.struct __ngin_EmptyStruct
.endstruct

.define __ngin_isSigned8InRange( value ) \
    ( (value) >= -128 .and (value) <= 127 )

.define __ngin_isSigned16InRange( value ) \
    ( (value) >= -32768 .and (value) <= 32767 )

; Converts a signed value -128..127 to a corresponding unsigned byte in range
; 0..255. If the input value is out of range, causes a division by zero, which
; stops the compilation. Division by zero is used to stop the compilation so
; that it will work even if force_range feature is enabled. The intended usage
; is for constants in places which normally only accept unsigned bytes,
; e.g. lda #ngin_signed8 -66
.define ngin_signed8( value ) ( \
    __ngin_choice \
        __ngin_isSigned8InRange {value}, \
        .lobyte( value ), \
        1 / ( __ngin_isSigned8InRange {value} ) \
    )

; Same as ngin_signed8, except for 16-bit values
.define ngin_signed16( value ) ( \
    __ngin_choice \
        __ngin_isSigned16InRange {value}, \
        .loword( value ), \
        1 / ( __ngin_isSigned16InRange {value} ) \
    )

; This macro can be used to define a 16.8 fixed point value (24-bit result)
.define ngin_immFixedPoint16_8( int, frac ) ( (int) << 8 | (frac) )

; This macro can be used to define an 8.8 fixed point value (16-bit result)
.define ngin_immFixedPoint8_8 ( int, frac ) ( (int) << 8 | (frac) )

; This macro can be used to parse a fixed point number from a string, such
; as "1.2345" or "-0.75". Note that the number of supported digits is
; limited. Result is rounded to nearest if it cannot be represented
; accurately.
.macro ngin_fixedPoint targetSymbol, number, fractBits
    .local numberInt
    numberInt .set 0
    .local foundDecimalPoint
    foundDecimalPoint .set 0
    .local fractMultiplier
    fractMultiplier .set 1
    .local sign
    sign .set 1
    .repeat .strlen( number ), i
        .if .strat( number, i ) = ngin_Ascii::kDot
            .if foundDecimalPoint
                .error "multiple decimal points found"
            .endif
            foundDecimalPoint .set 1
        .elseif .strat( number, i ) = ngin_Ascii::kMinus .or \
                .strat( number, i ) = ngin_Ascii::kPlus
            .if i <> 0
                .error "sign can only appear in the beginning"
            .endif
            sign .set -1*( .strat( number, i ) = ngin_Ascii::kMinus )
        .elseif .strat( number, i ) >= ngin_Ascii::kZero .and \
                .strat( number, i ) <= ngin_Ascii::kNine
            ; Check for overflow in case of too many digits.
            .if numberInt >= ( ( 1 << 31 ) - 1 ) / 10
                .error "can't fit digits in an integer, use less digits"
            .endif
            numberInt .set 10*numberInt + .strat( number, i ) \
                           - ngin_Ascii::kZero
            .if foundDecimalPoint
                fractMultiplier .set 10*fractMultiplier
            .endif
        .else
            .error "invalid character encountered in fixed point string"
        .endif
    .endrepeat
    ; \todo Warn if result not exact?
    ; \todo Other rounding options?
    ; \todo Is there a better way to check for overflow?
    .if numberInt * ( 1 << fractBits ) / ( 1 << fractBits ) <> numberInt
        .error "overflow in multiplication, use less digits"
    .endif
    ; \todo Break down the calculations so that more digits can be handled
    ;       without overflow.
    targetSymbol = ( numberInt * ( 1 << fractBits ) + fractMultiplier/2 ) \
        / fractMultiplier * sign
.endmacro

.macro ngin_fixedPointQ8 targetSymbol, number
    ngin_fixedPoint {targetSymbol}, {number}, 8
.endmacro

.macro ngin_segmentData segment, data
    .pushseg
    .segment segment
    data
    .popseg
.endmacro

.macro ngin_zp data
    ngin_segmentData "ZEROPAGE", {data}
.endmacro

.macro ngin_bss data
    ngin_segmentData "BSS", {data}
.endmacro

.macro __ngin_bss data
    ngin_segmentData "NGIN_BSS", {data}
.endmacro

.macro ngin_rodata data
    ngin_segmentData "RODATA", {data}
.endmacro

; Push current segment, and switch to 'segment'.
.macro ngin_pushSeg segment
    .pushseg
    .segment segment
.endmacro

.macro ngin_popSeg
    .popseg
.endmacro

.macro ngin_constructor symbol
    ngin_pushSeg "NGIN_RESET_CONSTRUCTORS"
    jsr symbol
    ngin_popSeg
.endmacro

; This macro can be used for documentation when JSR+RTS is replaced with
; a JMP.
.macro ngin_jsrRts operand
    jmp operand
.endmacro

; Divide "i" by "j", round up.
.define __ngin_divideCeil( i, j ) ( ((i) + (j)-1) / (j) )

__ngin_kBitsPerByte = 8

; Calculates the size (in bytes) of a bitfield (1 bit per element) that can
; hold numElements values.
.define ngin_bitFieldSize( numElements ) \
    (__ngin_divideCeil {numElements}, {__ngin_kBitsPerByte})

.macro __ngin_decimalInteger integer
    .local divider
    divider .set 100000000
    .local value
    value = integer

    ; \note .charmap isn't a problem here, because string/character literals
    ;       are not used.

    ; \todo This doesn't seem to work properly for signed numbers (try
    ;       e.g. $FFFFFFFF).

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

.macro __ngin_hexInteger integer
    .local shift
    shift .set 28
    .local value
    value = integer

    ; \note .charmap isn't a problem here, because string/character literals
    ;       are not used.

    .repeat 8, i
        ; Output the digit, padding with zeros at the left side.
        .byte .lobyte( __ngin_choice \
            ( (value>>shift) & $F ) <> 0 .or shift = 0, \
            ( __ngin_choice \
                ( (value>>shift) & $F ) < 10, \
                ( (value>>shift) & $F ) .mod 10 + ngin_Ascii::kZero, \
                ( ( (value>>shift) & $F ) - 10 ) + ngin_Ascii::kA ), \
            ngin_Ascii::kZero )
        shift .set shift-4
    .endrepeat
.endmacro

.macro ngin_asl count
    .repeat count
        asl
    .endrepeat
.endmacro

.macro ngin_lsr count
    .repeat count
        lsr
    .endrepeat
.endmacro

.define ngin_bank( symbol ) .lobyte( .bank( symbol ) )

.macro ngin_scoped symbol, body
    .proc symbol
        body
    .endproc
.endmacro

.macro ngin_repeat times, body
    .repeat times
        body
    .endrepeat
.endmacro

.endif
