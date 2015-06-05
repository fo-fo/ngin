.if .not .defined( NGIN_NGIN_MUSE_INC_INCLUDED )
NGIN_NGIN_MUSE_INC_INCLUDED = 1

.include "ngin/core.inc"

.global __ngin_Muse_init
.macro ngin_Muse_init soundData
    __ngin_requireParameter {soundData}, "soundData"

    __ngin_getOperandStride {soundData}, __ngin_Muse_init_strideSoundData

    .if .match( .left( 1, {soundData} ), # )
        .local soundDataStripped
        soundDataStripped = .right( .tcount( {soundData} ) - 1, \
                                             {soundData} )

        ; \todo Macro for ldax? (Support strides, etc. Note that ",x" addressing
        ;       won't be able to work.)
        lda #.lobyte( soundDataStripped )
        ldx #.hibyte( soundDataStripped )
    .else
        lda 0 * __ngin_Muse_init_strideSoundData + soundData
        ldx 1 * __ngin_Muse_init_strideSoundData + soundData
    .endif

    jsr __ngin_Muse_init
.endmacro

.global __ngin_Muse_update
.macro ngin_Muse_update
    jsr __ngin_Muse_update
.endmacro

.global __ngin_Muse_startMusic
.macro ngin_Muse_startSong song
    __ngin_requireParameter {song}, "song"

    lda song
    jsr __ngin_Muse_startMusic
.endmacro

.global __ngin_Muse_startSfx
.macro ngin_Muse_startEffect effect, channel
    __ngin_requireParameter {effect},  "effect"
    __ngin_requireParameter {channel}, "channel"

    lda effect
    ldx channel
    jsr __ngin_Muse_startSfx
.endmacro

.global __ngin_Muse_setFlags
.macro ngin_Muse_setFlags flags
    __ngin_requireParameter {flags}, "flags"

    lda flags
    jsr __ngin_Muse_setFlags
.endmacro

.endif
