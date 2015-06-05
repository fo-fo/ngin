.if .not .defined( NGIN_SOUND_MUSE_MUSE_INC_INCLUDED )
NGIN_SOUND_MUSE_MUSE_INC_INCLUDED = 1

.global MUSE_init
.global MUSE_update
.global MUSE_startMusic
.global MUSE_startSfx
.global MUSE_stopSfx
.global MUSE_isSfxPlaying
.global MUSE_setVolume
.global MUSE_setFlags
.global MUSE_getSyncEvent

.endif
