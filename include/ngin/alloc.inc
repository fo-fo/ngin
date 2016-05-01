.if .not .defined( NGIN_ALLOC_INC_INCLUDED )
NGIN_ALLOC_INC_INCLUDED = 1

.include "ngin/core.inc"
.include "ngin/lua/lua.inc"

; Space reserved for user variables.
ngin_kAllocReserveUserSize = 20
; Space reserved for internal (Ngin) variables.
ngin_kAllocReserveInternalSize = 20

.globalzp __ngin_alloc_reserve
.macro ngin_alloc symbol, offset, size
    .if .blank( {size} )
        ngin_alloc {symbol}, {offset}, 1
        .exitmac
    .else
        ; Accept more descriptive names for common sizes.
        .if .xmatch( {size}, {.byte} )
            ngin_alloc {symbol}, {offset}, 1
            .exitmac
        .elseif .xmatch( {size}, {.word} )
            ngin_alloc {symbol}, {offset}, 2
            .exitmac
        .elseif .xmatch( {size}, {.dword} )
            ngin_alloc {symbol}, {offset}, 4
            .exitmac
        .endif
    .endif

    .if .blank( {offset} )
        ; Use offset+size from previous invocation as new offset.
        ngin_alloc {symbol}, ::__ngin_alloc_runningOffset, {size}
        .exitmac
    .endif

    ngin_Lua_string .sprintf( "ngin.alloc.alloc( '%s', %d, %d )", \
        .string( symbol ), offset, size )

    ; \note Can't use .define here because it can't be scoped (although
    ;       they do would have the benefit that they can be undefined.)

    ; Force zero page addressing, since we know that the reserve is in ZP.
    symbol := .lobyte( __ngin_alloc_reserve + (offset) )

   ; Save the offset and size for this symbol. Done here instead of in the
   ; Lua code so that scopes will be accounted for.
   .ident( .sprintf( "__ngin_alloc_symbolInfo_%s", .string( symbol ) ) ) = \
        (offset) << 16 | (size)

    ::__ngin_alloc_runningOffset .set (offset)+(size)
.endmacro

; \note This macro will not get rid of the symbol, it will only mark the
;       symbol freed in the internal bookkeeping.
.macro ngin_free s1, s2, s3, s4, s5, s6, s7, s8
    .define __ngin_free_symbolInfo \
        .ident( .sprintf( "__ngin_alloc_symbolInfo_%s", .string( s1 ) ) )
    ngin_Lua_string .sprintf( "ngin.alloc.free( '%s', %d, %d )", \
        .string( s1 ), \
        __ngin_free_symbolInfo >> 16, \
        __ngin_free_symbolInfo & $FFFF \
    )
    .undefine __ngin_free_symbolInfo

    .if .not .blank( {s2} )
        ngin_free {s2}, {s3}, {s4}, {s5}, {s6}, {s7}, {s8}
    .endif
.endmacro

.macro __ngin_alloc symbol, offset, size
    .if .blank( {offset} )
        ; Use offset+size from previous invocation as new offset.
        ; \note No need to add user base here, already in running offset.
        ngin_alloc {symbol}, ::__ngin_alloc_runningOffset, {size}
        .exitmac
    .endif
    ngin_alloc {symbol}, { (offset)+::ngin_kAllocReserveUserSize }, {size}
.endmacro

.define __ngin_free ngin_free

.endif
