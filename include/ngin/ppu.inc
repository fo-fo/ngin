.if .not .defined( NGIN_PPU_INC_INCLUDED )
NGIN_PPU_INC_INCLUDED = 1

.scope ppu
    .enum
        ctrl = $2000
        mask
        status
        scroll = $2005
        addr
        data
    .endenum

    .enum oam
        addr = $2003
        data
    .endenum

    ; \todo Same for "ctrl"
    .enum mask
        kGrayscaleOn  = %1
        kGrayscaleOff = %0
        ; \todo The rest of the flags
    .endenum
.endscope

.endif
