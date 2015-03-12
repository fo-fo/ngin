.include "ngin/ngin.inc"

.segment "RODATA"

.proc testMapData
    kNum16x16Metatiles  = 2
    kNum32x32Metatiles  = 3
    kNumScreens         = 2
    kMapHeight          = 3

    ; Screen rows
    ; For each row of the map, this array contains screen indices.
    ; \note The code may assume that the rows are sequential in memory.
    .scope screenRows
        row0: .byte 0, 1, 0
        row1: .byte 1, 1, 1
        row2: .byte 0, 0, 0
    .endscope

    ; Screens
    ; Every screen is an 8x8 array of 32x32px metatile indices, making up a
    ; 256x256px screen.
    .scope screens
        .proc screen0
            .byte 0, 0, 0, 0, 0, 0, 0, 1
            .byte 0, 0, 0, 0, 0, 0, 0, 1
            .byte 0, 0, 0, 0, 0, 0, 0, 1
            .byte 0, 0, 0, 1, 1, 0, 0, 1
            .byte 0, 0, 0, 1, 1, 0, 0, 1
            .byte 0, 0, 0, 0, 0, 0, 0, 1
            .byte 0, 0, 0, 0, 0, 0, 0, 1
            .byte 1, 1, 1, 1, 1, 1, 1, 1
        .endproc

        .proc screen1
            .byte 2, 0, 0, 0, 0, 0, 0, 0
            .byte 2, 0, 0, 0, 0, 0, 0, 0
            .byte 2, 0, 0, 0, 0, 0, 0, 0
            .byte 2, 0, 0, 2, 2, 0, 0, 0
            .byte 2, 0, 0, 2, 2, 0, 0, 0
            .byte 2, 0, 0, 0, 0, 0, 0, 0
            .byte 2, 0, 0, 0, 0, 0, 0, 0
            .byte 2, 0, 0, 0, 0, 0, 0, 0
        .endproc
    .endscope

    ; Screen row pointers
    .scope screenRowPointers
        .define screenRowPointers_ screenRows::row0, screenRows::row1, \
                                   screenRows::row2
        lo: .lobytes screenRowPointers_
        hi: .hibytes screenRowPointers_
        .undefine screenRowPointers_
    .endscope
    .assert .sizeof( screenRowPointers ) = 2*kMapHeight, error

    ; Screen pointers
    .scope screenPointers
        .define screenPointers_ screens::screen0, screens::screen1
        lo: .lobytes screenPointers_
        hi: .hibytes screenPointers_
        .undefine screenPointers_
    .endscope
    .assert .sizeof( screenPointers ) = 2*kNumScreens, error

    ; 32x32 metatiles
    .scope _32x32Metatiles
        topLeft:     .byte 0, 1, 1
        topRight:    .byte 0, 1, 0
        bottomLeft:  .byte 0, 1, 0
        bottomRight: .byte 0, 1, 1
    .endscope
    .assert .sizeof( _32x32Metatiles ) = 4*kNum32x32Metatiles, error

    ; 16x16 metatiles
    ; \todo .struct for the metatile data?
    .scope _16x16Metatiles
        topLeft:     .byte 4, 1
        topRight:    .byte 4, 3
        bottomLeft:  .byte 4, 2
        bottomRight: .byte 4, 1
        attributes0: .byte 0, 0
    .endscope
    .assert .sizeof( _16x16Metatiles ) = 5*kNum16x16Metatiles, error

    ; -------------------------------------------------------------------------

    ; ngin_MapData_Header
    .proc header
        ; ngin_MapData_Pointers
        .addr screenRowPointers::lo
        .addr screenRowPointers::hi
        .addr screenPointers::lo
        .addr screenPointers::hi
        .addr _16x16Metatiles::topLeft
        .addr _16x16Metatiles::topRight
        .addr _16x16Metatiles::bottomLeft
        .addr _16x16Metatiles::bottomRight
        .addr _16x16Metatiles::attributes0
        .addr _32x32Metatiles::topLeft
        .addr _32x32Metatiles::topRight
        .addr _32x32Metatiles::bottomLeft
        .addr _32x32Metatiles::bottomRight
    .endproc
.endproc

.export testMapDataHeader := testMapData::header
