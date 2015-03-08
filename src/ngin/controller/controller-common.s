.include "controller-common.inc"

; These temporary variables are used by blargg-read-joy.inc.
.segment "NGIN_ZEROPAGE" : zeropage
    __ngin_controllerTemp1: .byte 0
    __ngin_controllerTemp2: .byte 0
    __ngin_controllerTemp3: .byte 0
