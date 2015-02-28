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

.macro ngin_mov8 to, from
    lda from
    sta to
.endmacro

.macro ngin_mov16 to, from
    ; \todo Optional hibyte offset? Might be sufficient to have a
    ;       template macro, and use that to generate a couple of specialized
    ;       macros (e.g. for objects). Although source and destination
    ;       offsets will often differ...

    .if .match( .left( 1, {from} ), # )
        .local fromStripped
        fromStripped = .right( .tcount( {from} ) - 1, {from} )
        ; \todo Could be optimized if lobyte == hibyte
        ngin_mov8 0+(to), #.lobyte( fromStripped )
        ngin_mov8 1+(to), #.hibyte( fromStripped )
    .else
        ngin_mov8 0+(to), 0+(from)
        ngin_mov8 1+(to), 1+(from)
    .endif
.endmacro

.macro ngin_mov32 to, from
    ; \todo Optional hibyte offset (would need 3 though, so nonsensical)

    .if .match( .left( 1, {from} ), # )
        .local fromStripped
        fromStripped = .right( .tcount( {from} ) - 1, {from} )
        ngin_mov16 0+(to), #.loword( fromStripped )
        ngin_mov16 2+(to), #.hiword( fromStripped )
    .else
        ngin_mov16 0+{to}, 0+{from}
        ngin_mov16 2+(to), 2+(from)
    .endif
.endmacro

.struct ngin_Vector2_16
    x_ .word
    y_ .word
.endstruct

.define ngin_immediateVector2_16( x_, y_ ) ( (.loword( y_ ) << 16) | \
                                              .loword( x_ ) )

.endif
