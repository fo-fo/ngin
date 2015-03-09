.include "ngin/ngin.inc"

ngin_entryPoint start
.proc start
    dumb = 12345

    ngin_Lua_string "print( 'Symbol dumb = ' .. SYM.dumb[ 1 ] )", \
                    ::ngin_Lua_kUniqueAddress

    jmp *
.endproc
