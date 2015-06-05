.include "ngin/ngin-muse.inc"
.include "muse/muse.inc"

; \todo Whatever is needed: NMI handler? Synchronized variables?

; Export the functions for the macros to use.
__ngin_Muse_init            := MUSE_init
__ngin_Muse_update          := MUSE_update
__ngin_Muse_startMusic      := MUSE_startMusic
__ngin_Muse_startSfx        := MUSE_startSfx
__ngin_Muse_stopSfx         := MUSE_stopSfx
__ngin_Muse_isSfxPlaying    := MUSE_isSfxPlaying
__ngin_Muse_setVolume       := MUSE_setVolume
__ngin_Muse_setFlags        := MUSE_setFlags
__ngin_Muse_getSyncEvent    := MUSE_getSyncEvent
