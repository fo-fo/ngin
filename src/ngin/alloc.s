.include "ngin/alloc.inc"

ngin_Lua_require "alloc.lua"

.segment "NGIN_ZEROPAGE" : zeropage

ngin_kAllocReserveSize = 16
__ngin_alloc_reserve:       .res ngin_kAllocReserveSize
; \todo Allocate a separate area for Ngin's internal temporary variables
;       (arguments, local variables, etc)
