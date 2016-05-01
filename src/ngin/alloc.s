.include "ngin/alloc.inc"

ngin_Lua_require "alloc.lua"

.segment "NGIN_ZEROPAGE" : zeropage

__ngin_alloc_reserve:       .res ngin_kAllocReserveUserSize + \
                                 ngin_kAllocReserveInternalSize
