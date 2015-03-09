.include "ngin/map-data.inc"

.segment "NGIN_ZEROPAGE"

; \todo A bunch of pointers

.segment "NGIN_BSS"

__ngin_MapData_load_mapAddress:     .addr 0

.segment "NGIN_CODE"

.proc __ngin_MapData_load
    ; \todo Set up pointers based on the load address.
    rts
.endproc
