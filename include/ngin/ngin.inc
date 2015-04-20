.if .not .defined( NGIN_NGIN_INC_INCLUDED )
NGIN_NGIN_INC_INCLUDED = 1

.include "ngin/core.inc"
.include "ngin/arithmetic.inc"
.include "ngin/branch.inc"
.include "ngin/ppu.inc"
.include "ngin/shadow-oam.inc"
.include "ngin/sprite-renderer.inc"
.include "ngin/memory.inc"
.include "ngin/ppu-buffer.inc"
.include "ngin/build-log.inc"
.include "ngin/controller.inc"
.include "ngin/collision.inc"
.include "ngin/lua/lua.inc"
.include "ngin/map-data.inc"
.include "ngin/map-scroller.inc"
.include "ngin/util.inc"
.include "ngin/nmi.inc"

.endif
