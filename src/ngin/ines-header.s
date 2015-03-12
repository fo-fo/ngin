.export __ngin_inesHeaderForceImport : absolute = 1

.enum inesMirroring
    kHorizontal
    kVertical
    kFourScreen = 8
.endenum

.scope ines
    kMapperNumber   = 0
    kMirroring      = inesMirroring::kHorizontal
    kNum16kPrgBanks = 2
    kNum8kChrBanks  = 1
.endscope

.segment "INES_HEADER"
    .byte "NES", $1A
    .byte ines::kNum16kPrgBanks
    .byte ines::kNum8kChrBanks
    .byte ( ines::kMapperNumber & %1111 ) << 4 | ines::kMirroring
    .byte ines::kMapperNumber & %1111_0000
