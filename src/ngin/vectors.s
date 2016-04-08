.include "reset-private.inc"
.include "nmi-private.inc"

.export __ngin_vectorsForceImport : absolute = 1
.import __ngin_irq

.segment "VECTORS"
    .addr __ngin_nmi
    .addr __ngin_reset
    .addr __ngin_irq
