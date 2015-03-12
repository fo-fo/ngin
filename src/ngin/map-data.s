.include "ngin/map-data.inc"
.include "ngin/arithmetic.inc"

.segment "NGIN_ZEROPAGE" : zeropage

; \note Do not rely on the value of this after MapData_load.
__ngin_MapData_load_mapAddress:         .addr 0

ngin_MapData_pointers:                  .tag ngin_MapData_Pointers

.segment "NGIN_CODE"

.proc __ngin_MapData_load
    ; Set up zeropage pointers to various pieces of map data.
    ldx #0
    .assert ngin_MapData_Header::pointers + \
            .sizeof( ngin_MapData_Pointers ) < 256, error
    ldy #ngin_MapData_Header::pointers
    loop:
        lda ( __ngin_MapData_load_mapAddress ), y
        sta ngin_MapData_pointers, x
        iny
        inx
        cpx #.sizeof( ngin_MapData_Pointers )
    bne loop

    rts
.endproc
