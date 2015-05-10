.if .not .defined( NGIN_OBJECT_SPAWNER_INC_INCLUDED )
NGIN_OBJECT_SPAWNER_INC_INCLUDED = 1

.include "ngin/core.inc"

; These values (in pixels) define any extra width/height added into the edge
; coordinates at both sides. IOW, objects will be spawned before they come
; visually into view.
ngin_ObjectSpawner_kViewSlackX = 64
ngin_ObjectSpawner_kViewSlackY = 64

.global __ngin_ObjectSpawner_setPosition
.global __ngin_ObjectSpawner_setPosition_position
.macro ngin_ObjectSpawner_setPosition position
    __ngin_requireParameter {position}, "position"

    ngin_mov32 __ngin_ObjectSpawner_setPosition_position, {position}

    jsr __ngin_ObjectSpawner_setPosition
.endmacro

.global __ngin_ObjectSpawner_scrollHorizontal
.global __ngin_ObjectSpawner_scrollHorizontal_amount
.macro ngin_ObjectSpawner_scrollHorizontal amount
    __ngin_requireParameter {amount}, "amount"

    ngin_mov8 __ngin_ObjectSpawner_scrollHorizontal_amount, {amount}

    jsr __ngin_ObjectSpawner_scrollHorizontal
.endmacro

.global __ngin_ObjectSpawner_scrollVertical
.global __ngin_ObjectSpawner_scrollVertical_amount
.macro ngin_ObjectSpawner_scrollVertical amount
    __ngin_requireParameter {amount}, "amount"

    ngin_mov8 __ngin_ObjectSpawner_scrollVertical_amount, {amount}

    jsr __ngin_ObjectSpawner_scrollVertical
.endmacro

.endif
