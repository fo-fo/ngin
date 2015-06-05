; Force some segments to exist, even if they are empty, because they have
; define=yes in the linker configuration and will generate a linker warning
; if they don't exist.

.export __ngin_forceSegmentForceImport : absolute = 1

.segment "NGIN_MUSE_CODE"
.segment "NGIN_CODE"
.segment "NGIN_RESET_PROLOGUE"
.segment "NGIN_RESET_CONSTRUCTORS"
.segment "NGIN_RESET_EPILOGUE"
.segment "NGIN_RODATA"
.segment "NGIN_BSS"
.segment "OBJECT_CONSTRUCT_LO"
.segment "OBJECT_CONSTRUCT_HI"
.segment "OBJECT_UPDATE_LO"
.segment "OBJECT_UPDATE_HI"
.segment "CODE"
.segment "RODATA"
.segment "BSS"
