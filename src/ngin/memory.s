.include "ngin/memory.inc"

.segment "ZEROPAGE"

__ngin_genericCopy_destination: .addr 0
__ngin_genericCopy_source:      .addr 0

.segment "BSS"

__ngin_genericCopy_size:        .word 0
