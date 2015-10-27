.if .not .defined( NGIN_MAP_DATA_INC_INCLUDED )
NGIN_MAP_DATA_INC_INCLUDED = 1

.include "ngin/core.inc"

.enum ngin_MapData_Attributes0
    ; \note The bottom two bits are used for the color set index.
    kSolid     = %000001_00
    kSolidTop  = %000010_00
    ; \todo Some user attributes could be mutually exclusive with kSolid,
    ;       so bits are wasted in that case.
    kUserAttr1 = %000100_00
    kUserAttr2 = %001000_00
    kUserAttr3 = %010000_00
    kUserAttr4 = %100000_00
.endenum

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
    objectsXLo                  .addr
    objectsXHi                  .addr
    objectsYLo                  .addr
    objectsYHi                  .addr
    objectsType                 .addr
    objectsXToYIndex            .addr
    objectsYSortedIndex         .addr
.endstruct

.struct ngin_MapData_Header
    ; \todo Width/height doesn't need to be stored since boundary checks were
    ;       moved to Camera (from MapScroller).
    widthScreens    .byte
    heightScreens   .byte

    ; Map boundaries (world space coordinates); all are inclusive
    boundaryLeft    .word
    boundaryRight   .word
    boundaryTop     .word
    boundaryBottom  .word

    ; Number of objects in the map
    numObjects      .byte

    ; Pointers to map data
    pointers        .tag ngin_MapData_Pointers
.endstruct

.globalzp ngin_MapData_header
.globalzp ngin_MapData_pointers

.global __ngin_MapData_load
.global __ngin_MapData_load_mapAddress
.macro ngin_MapData_load mapAddress
    __ngin_requireParameter {mapAddress}, "mapAddress"

    ngin_mov16 __ngin_MapData_load_mapAddress, {mapAddress}

    jsr __ngin_MapData_load
.endmacro

.endif
