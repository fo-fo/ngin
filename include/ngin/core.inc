.if .not .defined( NGIN_CORE_INC_INCLUDED )
NGIN_CORE_INC_INCLUDED = 1

; Enable line continuation with backslash (unfortunately not a .feature)
.linecont +

.macro ngin_entryPoint entrySymbol
    .export __ngin_start := entrySymbol
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

; \todo Maybe better to have these as an union in Vector2_16.
.union ngin_Vector2_8_8
    .struct
        fracX_  .byte
        intX_   .byte
        fracY_  .byte
        intY_   .byte
    .endstruct
    .struct
        x_      .word
        y_      .word
    .endstruct
.endunion

.define ngin_immediateVector2_16( x_, y_ ) ( (.loword( y_ ) << 16) | \
                                              .loword( x_ ) )

.define ngin_Vector2_16_immediateX( vector ) .loword( vector )
.define ngin_Vector2_16_immediateY( vector ) .hiword( vector )

.struct __ngin_EmptyStruct
.endstruct

.define __ngin_isSignedByteInRange( value ) \
    ( (value) >= -128 .and (value) <= 127 )

.define __ngin_isSignedWordInRange( value ) \
    ( (value) >= -32768 .and (value) <= 32767 )

; Converts a signed value -128..127 to a corresponding unsigned byte in range
; 0..255. If the input value is out of range, causes a division by zero, which
; stops the compilation. Division by zero is used to stop the compilation so
; that it will work even if force_range feature is enabled. The intended usage
; is for constants in places which normally only accept unsigned bytes,
; e.g. lda #ngin_signedByte -66
.define ngin_signedByte( value ) ( \
    __ngin_choice \
        __ngin_isSignedByteInRange {value}, \
        .lobyte( value ), \
        1 / ( __ngin_isSignedByteInRange {value} ) \
    )

; Same as ngin_signedByte, except for 16-bit values
.define ngin_signedWord( value ) ( \
    __ngin_choice \
        __ngin_isSignedWordInRange {value}, \
        .loword( value ), \
        1 / ( __ngin_isSignedWordInRange {value} ) \
    )

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

; This macro can be used to mark unconditional branches in code, and to do
; a runtime check to verify that the expected condition holds.
.macro ngin_always branch
    ; \todo Check what branch is used, and assert that the branch condition
    ;       is true (e.g. if BCC, assert that carry is 0)
    branch
.endmacro

; This macro can be used for documentation when JSR+RTS is replaced with
; a JMP.
.macro ngin_jsrRts operand
    jmp operand
.endmacro

.endif
