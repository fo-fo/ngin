.include "reset.inc"

.export __ngin_vectorsForceImport : absolute = 1

.segment "VECTORS"
    .addr 0 ; \todo NMI
    .addr __ngin_reset
    .addr 0 ; \todo IRQ
