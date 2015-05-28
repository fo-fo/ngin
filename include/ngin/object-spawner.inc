.if .not .defined( NGIN_OBJECT_SPAWNER_INC_INCLUDED )
NGIN_OBJECT_SPAWNER_INC_INCLUDED = 1

.include "ngin/core.inc"

; These values (in pixels) define any extra width/height added into the edge
; coordinates at both sides. IOW, objects will be spawned before they come
; visually into view.
ngin_ObjectSpawner_kViewSlackX = 64
ngin_ObjectSpawner_kViewSlackY = 64

; Maximum number of objects in a map object list (including sentinels)
; \todo Should be configurable, to avoid waste of bytes for the "spawned" list.
ngin_ObjectSpawner_kMaxMapObjects = 256

; If currentIndex is set to this value, the object wasn't created by
; ObjectSpawner. We can use 0 as an invalid index, because there's always a
; sentinel, non-reachable object at index 0.
ngin_ObjectSpawner_kInvalidSpawnIndex = 0

; Index, in the map object list, of the object that is currently being
; spawned. Valid in the object constructor.
; \todo If an object spawns another object in its constructor, this will not
;       hold the correct value for the *new* object.
.global ngin_ObjectSpawner_spawnIndex

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

.global __ngin_ObjectSpawner_resetSpawn
.global __ngin_ObjectSpawner_resetSpawn_index
.macro ngin_ObjectSpawner_resetSpawn index
    __ngin_requireParameter {index}, "index"

    ngin_mov8 __ngin_ObjectSpawner_resetSpawn_index, {index}

    jsr __ngin_ObjectSpawner_resetSpawn
.endmacro

.global __ngin_ObjectSpawner_inView
.global __ngin_ObjectSpawner_inView_index
.macro ngin_ObjectSpawner_inView index
    __ngin_requireParameter {index}, "index"

    ngin_mov8 __ngin_ObjectSpawner_inView_index, {index}

    jsr __ngin_ObjectSpawner_inView
.endmacro

.endif
