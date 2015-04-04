.if .not .defined( NGIN_MAP_DATA_INC_INCLUDED )
NGIN_MAP_DATA_INC_INCLUDED = 1

.include "ngin/core.inc"

.struct ngin_MapData_Pointers
    screenRowPointersLo         .addr
    screenRowPointersHi         .addr
    screenPointersLo            .addr
    screenPointersHi            .addr
    ; \todo Add a level of indirection here? Specify a metatileset
    ;       index in map data, then read these pointers from elsewhere.
    ;       (NOTE: These pointers should still exist in RAM)
    _16x16MetatileTopLeft       .addr
    _16x16MetatileTopRight      .addr
    _16x16MetatileBottomLeft    .addr
    _16x16MetatileBottomRight   .addr
    _16x16MetatileAttributes0   .addr
    _32x32MetatileTopLeft       .addr
    _32x32MetatileTopRight      .addr
    _32x32MetatileBottomLeft    .addr
    _32x32MetatileBottomRight   .addr
.endstruct

.struct ngin_MapData_Header
    ; \todo Might need mapWidth/height for wrap over?
    pointers        .tag ngin_MapData_Pointers
.endstruct

.globalzp ngin_MapData_pointers

.global   __ngin_MapData_load
.globalzp __ngin_MapData_load_mapAddress
.macro ngin_MapData_load mapAddress
    __ngin_requireParameter {mapAddress}, "mapAddress"

    ngin_mov16 __ngin_MapData_load_mapAddress, {mapAddress}

    jsr __ngin_MapData_load
.endmacro

.endif
