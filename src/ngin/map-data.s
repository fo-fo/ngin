.include "ngin/map-data.inc"
.include "ngin/arithmetic.inc"
.include "ngin/lua/lua.inc"

.segment "NGIN_ZEROPAGE" : zeropage

ngin_MapData_header:                    .addr 0
ngin_MapData_pointers:                  .tag ngin_MapData_Pointers

.segment "NGIN_BSS"

__ngin_MapData_load_mapAddress:         .addr 0

.segment "NGIN_CODE"

.proc __ngin_MapData_load
    ; Save the header pointer.
    ngin_mov16 ngin_MapData_header, __ngin_MapData_load_mapAddress

    ; Set up zeropage pointers to various pieces of map data.
    ldx #0
    .assert ngin_MapData_Header::pointers + \
            .sizeof( ngin_MapData_Pointers ) < 256, error
    ldy #ngin_MapData_Header::pointers
    loop:
        lda ( ngin_MapData_header ), y
        sta ngin_MapData_pointers, x
        iny
        inx
        cpx #.sizeof( ngin_MapData_Pointers )
    bne loop

    rts
.endproc
