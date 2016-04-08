NGIN_MAPPER_NROM = 1
.include "ngin/mapper/nrom.inc"

.segment "NGIN_MAPPER_INIT"
.export __ngin_initMapper_NROM
.proc __ngin_initMapper_NROM
    ; Nothing to do.

    ; \note This code is inlined, no RTS allowed.
.endproc
