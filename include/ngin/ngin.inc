.if .not .defined( NGIN_NGIN_INC_INCLUDED )
NGIN_NGIN_INC_INCLUDED = 1

.include "ngin/core.inc"
.include "ngin/arithmetic.inc"
.include "ngin/branch.inc"
.include "ngin/ppu.inc"
.include "ngin/shadow-oam.inc"
.include "ngin/sprite-renderer.inc"
.include "ngin/memory.inc"

.endif