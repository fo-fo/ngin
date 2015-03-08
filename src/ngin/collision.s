.include "ngin/collision.inc"
.include "ngin/core.inc"
.include "ngin/arithmetic.inc"
.include "ngin/branch.inc"

.segment "NGIN_BSS"

__ngin_Collision_rectOverlap_rectATopLeft:      .tag ngin_Vector2_16
__ngin_Collision_rectOverlap_rectABottomRight:  .tag ngin_Vector2_16
__ngin_Collision_rectOverlap_rectBTopLeft:      .tag ngin_Vector2_16
__ngin_Collision_rectOverlap_rectBBottomRight:  .tag ngin_Vector2_16

.segment "NGIN_CODE"

.proc __ngin_Collision_rectOverlap
    rectATopLeft     := __ngin_Collision_rectOverlap_rectATopLeft
    rectABottomRight := __ngin_Collision_rectOverlap_rectABottomRight
    rectBTopLeft     := __ngin_Collision_rectOverlap_rectBTopLeft
    rectBBottomRight := __ngin_Collision_rectOverlap_rectBBottomRight

    ; All of following must be true for the rects to overlap:
    ;     rectATopLeft.X     < rectBBottomRight.X  and
    ;     rectABottomRight.X > rectBTopLeft.X      and
    ;     rectATopLeft.Y     < rectBBottomRight.Y  and
    ;     rectABottomRight.Y > rectBTopLeft.Y

    ngin_cmp16 rectATopLeft     + ngin_Vector2_16::x_, \
               rectBBottomRight + ngin_Vector2_16::x_
    ngin_branchIfGreaterOrEqual noOverlapClearCarry

    ngin_cmp16 rectABottomRight + ngin_Vector2_16::x_, \
               rectBTopLeft     + ngin_Vector2_16::x_
    ngin_branchIfLess noOverlapRts
    beq noOverlapClearCarry

    ngin_cmp16 rectATopLeft     + ngin_Vector2_16::y_, \
               rectBBottomRight + ngin_Vector2_16::y_
    ngin_branchIfGreaterOrEqual noOverlapClearCarry

    ngin_cmp16 rectABottomRight + ngin_Vector2_16::y_, \
               rectBTopLeft     + ngin_Vector2_16::y_
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
