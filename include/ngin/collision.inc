.if .not .defined( NGIN_COLLISION_INC_INCLUDED )
NGIN_COLLISION_INC_INCLUDED = 1

.include "ngin/core.inc"

; \todo Provide an inlined version of this function (avoids memory copies,
;       but bloats code size)
.global __ngin_Collision_rectOverlap
.global __ngin_Collision_rectOverlap_rectALeftTop
.global __ngin_Collision_rectOverlap_rectARightBottom
.global __ngin_Collision_rectOverlap_rectBLeftTop
.global __ngin_Collision_rectOverlap_rectBRightBottom
.macro ngin_Collision_rectOverlap rectALeftTop, rectARightBottom, \
                                  rectBLeftTop, rectBRightBottom

    __ngin_requireParameter {rectALeftTop},     "rectALeftTop"
    __ngin_requireParameter {rectARightBottom}, "rectARightBottom"
    __ngin_requireParameter {rectBLeftTop},     "rectBLeftTop"
    __ngin_requireParameter {rectBRightBottom}, "rectBRightBottom"

    ngin_mov32 __ngin_Collision_rectOverlap_rectALeftTop,     {rectALeftTop}
    ngin_mov32 __ngin_Collision_rectOverlap_rectARightBottom, {rectARightBottom}
    ngin_mov32 __ngin_Collision_rectOverlap_rectBLeftTop,     {rectBLeftTop}
    ngin_mov32 __ngin_Collision_rectOverlap_rectBRightBottom, {rectBRightBottom}

    jsr __ngin_Collision_rectOverlap
.endmacro

.macro ngin_Collision_rectPoint rectALeftTop, rectARightBottom, pointB
    __ngin_requireParameter {rectALeftTop},     "rectALeftTop"
    __ngin_requireParameter {rectARightBottom}, "rectARightBottom"
    __ngin_requireParameter {pointB},           "pointB"

    ; Use the rectOverlap routine, but pass a 1x1 rect.
    ; \todo This will waste some space passing the same argument twice,
    ;       so might be worth creating an optimized routine for it.
    ngin_Collision_rectOverlap {rectALeftTop}, {rectARightBottom}, {pointB}, {pointB}
.endmacro

.endif
