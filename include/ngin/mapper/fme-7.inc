.if .not .defined( NGIN_MAPPER_FME_7_INC_INCLUDED )
NGIN_MAPPER_FME_7_INC_INCLUDED = 1

.assert .defined( NGIN_MAPPER_FME_7 ), error

.include "ngin/core.inc"

.scope ngin_Fme_7
    .enum
        command   = $8000
        parameter = $A000
    .endenum

    .enum
        kChr0_0000
        kChr1_0400
        kChr2_0800
        kChr3_0C00
        kChr4_1000
        kChr5_1400
        kChr6_1800
        kChr7_1C00
        kPrg0_6000
        kPrg1_8000
        kPrg2_A000
        kPrg3_C000
        kMirroring
        kIrqControl
        kIrqCounterLo
        kIrqCounterHi
    .endenum

    .enum irq
        kEnabled        = %1
        kCounterEnabled = %1000_0000
    .endenum

    .enum mirroring
        kVertical       = %00
        kHorizontal     = %01
        kOneScreenA     = %10
        kOneScreenB     = %11
    .endenum
.endscope

; \note "param" can't be "a", because the first load overwrites its value.
.macro ngin_Fme_7_write cmd, param
    ngin_mov8 ngin_Fme_7::command,   cmd
    ngin_mov8 ngin_Fme_7::parameter, param
.endmacro

.endif
