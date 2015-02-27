.scope ines
    kMapperNumber   = 0
    kMirroring      = 0
    kNum16kPrgBanks = 2
    kNum8kChrBanks  = 0
.endscope

.segment "INES_HEADER"
.export __ngin_inesHeader := *
    .byte "NES", $1A
    .byte ines::kNum16kPrgBanks
    .byte ines::kNum8kChrBanks
    .byte ( ines::kMapperNumber & %1111 ) << 4 | ines::kMirroring
    .byte ines::kMapperNumber & %1111_0000
