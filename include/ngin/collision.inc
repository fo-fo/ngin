.if .not .defined( NGIN_COLLISION_INC_INCLUDED )
NGIN_COLLISION_INC_INCLUDED = 1

.include "ngin/core.inc"

.global __ngin_Collision_rectOverlap
.global __ngin_Collision_rectOverlap_rectATopLeft
.global __ngin_Collision_rectOverlap_rectABottomRight
.global __ngin_Collision_rectOverlap_rectBTopLeft
.global __ngin_Collision_rectOverlap_rectBBottomRight
.macro ngin_Collision_rectOverlap rectATopLeft, rectABottomRight, \
                                  rectBTopLeft, rectBBottomRight

    __ngin_requireParameter {rectATopLeft},     "rectATopLeft"
    __ngin_requireParameter {rectABottomRight}, "rectABottomRight"
    __ngin_requireParameter {rectBTopLeft},     "rectBTopLeft"
    __ngin_requireParameter {rectBBottomRight}, "rectBBottomRight"

    ngin_mov32 __ngin_Collision_rectOverlap_rectATopLeft,     {rectATopLeft}
    ngin_mov32 __ngin_Collision_rectOverlap_rectABottomRight, {rectABottomRight}
    ngin_mov32 __ngin_Collision_rectOverlap_rectBTopLeft,     {rectBTopLeft}
    ngin_mov32 __ngin_Collision_rectOverlap_rectBBottomRight, {rectBBottomRight}

    jsr __ngin_Collision_rectOverlap
.endmacro

.endif
