.include "muse.inc"

.segment "NGIN_ZEROPAGE" : zeropage

MUSE_ZEROPAGE:      .res 7

.segment "NGIN_BSS"

MUSE_RAM:           .res 256

.segment "NGIN_MUSE_CODE"

.assert * .mod 256 = 0, error, "MUSE code needs to be aligned to 256 bytes"
.include "muse-ca65.inc"
