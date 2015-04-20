.include "reset-private.inc"
.include "nmi-private.inc"

.export __ngin_vectorsForceImport : absolute = 1

.segment "VECTORS"
    .addr __ngin_nmi
    .addr __ngin_reset
    .addr 0 ; \todo IRQ
