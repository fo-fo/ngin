.if .not .defined( NGIN_MAP_DATA_INC_INCLUDED )
NGIN_MAP_DATA_INC_INCLUDED = 1

.include "ngin/core.inc"

.struct ngin_MapData_Header
    num16x16Metatiles   .byte
    num32x32Metatiles   .byte
    numScreens          .byte
    mapWidth            .byte ; Unit: screens
    data                .tag __ngin_EmptyStruct
.endstruct

; \todo globalzp for pointers

.global __ngin_MapData_load
.global __ngin_MapData_load_mapAddress
.macro ngin_MapData_load mapAddress
    __ngin_requireParameter {mapAddress}, "mapAddress"

    ngin_mov16 __ngin_MapData_load_mapAddress, {mapAddress}

    jsr __ngin_MapData_load
.endmacro

.endif
