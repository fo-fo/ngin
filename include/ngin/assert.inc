.if .not .defined( NGIN_ASSERT_INC_INCLUDED )
NGIN_ASSERT_INC_INCLUDED = 1

.include "ngin/core.inc"
.include "ngin/lua/lua.inc"

; Runtime (dynamic) assert
.macro ngin_assert assertion, failMessage
    .if .not .blank( {failMessage} )
        ngin_Lua_string .sprintf( "ngin.assert( (%s), '%s' )", assertion, \
                                                               failMessage )
    .else
        ngin_Lua_string .sprintf( "ngin.assert( (%s) )", assertion )
    .endif
.endmacro

.endif
