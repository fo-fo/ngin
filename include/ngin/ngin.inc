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
.include "ngin/map-collision.inc"
.include "ngin/ascii.inc"
.include "ngin/camera.inc"
.include "ngin/log.inc"
.include "ngin/lfsr8.inc"
.include "ngin/object.inc"
.include "ngin/object-spawner.inc"
.include "ngin/debug.inc"
.include "ngin/sprite-animator.inc"
.include "ngin/assert.inc"
.include "ngin/ngin-muse.inc"
.include "ngin/debug-draw.inc"

.if .defined( NGIN_MAPPER_NROM )
    .include "ngin/mapper/nrom.inc"
.elseif .defined( NGIN_MAPPER_FME_7 )
    .include "ngin/mapper/fme-7.inc"
.endif

.endif
