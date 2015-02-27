.include "reset.inc"

.segment "VECTORS"
; Global symbol to allow it to be pulled in via --force-import so that ld65
; won't strip this object file.
.export __ngin_vectors := *
    .addr 0 ; \todo NMI
    .addr __ngin_reset
    .addr 0 ; \todo IRQ
