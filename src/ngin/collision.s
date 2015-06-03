.include "ngin/collision.inc"
.include "ngin/core.inc"
.include "ngin/arithmetic.inc"
.include "ngin/branch.inc"

.segment "NGIN_BSS"

__ngin_Collision_rectOverlap_rectALeftTop:      .tag ngin_Vector2_16
__ngin_Collision_rectOverlap_rectARightBottom:  .tag ngin_Vector2_16
__ngin_Collision_rectOverlap_rectBLeftTop:      .tag ngin_Vector2_16
__ngin_Collision_rectOverlap_rectBRightBottom:  .tag ngin_Vector2_16

.segment "NGIN_CODE"

.proc __ngin_Collision_rectOverlap
    rectALeftTop     := __ngin_Collision_rectOverlap_rectALeftTop
    rectARightBottom := __ngin_Collision_rectOverlap_rectARightBottom
    rectBLeftTop     := __ngin_Collision_rectOverlap_rectBLeftTop
    rectBRightBottom := __ngin_Collision_rectOverlap_rectBRightBottom

    ; All of following must be true for the rects to overlap:
    ;     rectALeftTop.X     < rectBRightBottom.X  and
    ;     rectARightBottom.X > rectBLeftTop.X      and
    ;     rectALeftTop.Y     < rectBRightBottom.Y  and
    ;     rectARightBottom.Y > rectBLeftTop.Y

    ; \todo The horizontal and vertical case can be macroified.
    ngin_cmp16 rectALeftTop     + ngin_Vector2_16::x_, \
               rectBRightBottom + ngin_Vector2_16::x_
    ngin_branchIfGreaterOrEqual noOverlapClearCarry

    ngin_cmp16 rectARightBottom + ngin_Vector2_16::x_, \
               rectBLeftTop     + ngin_Vector2_16::x_
    ngin_branchIfLess noOverlapRts
    beq noOverlapClearCarry

    ngin_cmp16 rectALeftTop     + ngin_Vector2_16::y_, \
               rectBRightBottom + ngin_Vector2_16::y_
    ngin_branchIfGreaterOrEqual noOverlapClearCarry

    ngin_cmp16 rectARightBottom + ngin_Vector2_16::y_, \
               rectBLeftTop     + ngin_Vector2_16::y_
    ngin_branchIfLess noOverlapRts
    ; If this branch is taken, rects overlap, and carry is already 1.
    bne overlap

    ; If we're here, there was no overlap.

noOverlapClearCarry:
    clc
noOverlapRts:
overlap:
    rts
.endproc
