.include "ngin/memory.inc"

.segment "NGIN_ZEROPAGE" : zeropage

__ngin_genericCopy_destination: .addr 0
__ngin_genericCopy_source:      .addr 0

.segment "NGIN_BSS"

__ngin_genericCopy_size:        .word 0
