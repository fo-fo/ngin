.enum inesMirroring
    kHorizontal
    kVertical
    kFourScreen = 8
.endenum

; From linker configuration.
.import __ngin_prgSize, __ngin_chrSize
.assert __ngin_prgSize .mod 16 = 0, error, "PRG size must be a multiple of 16"
.assert __ngin_chrSize .mod  8 = 0, error, "CHR size must be a multiple of 8"

.scope ines
    kMirroring      = inesMirroring::kHorizontal
    kNum16kPrgBanks = __ngin_prgSize/16
    kNum8kChrBanks  = __ngin_chrSize/8
.endscope

.if .defined( NGIN_MAPPER_NROM )
    ines::kMapperNumber .set 0
.elseif .defined( NGIN_MAPPER_FME_7 )
    ines::kMapperNumber .set 69
.else
    .error "unrecognized or undefined mapper"
.endif

.segment "INES_HEADER"
    .byte "NES", $1A
    .byte .lobyte( ines::kNum16kPrgBanks )
    .byte .lobyte( ines::kNum8kChrBanks )
    .byte ( ines::kMapperNumber & %1111 ) << 4 | ines::kMirroring
    .byte ines::kMapperNumber & %1111_0000
