.if .not .defined( NGIN_SAMPLE_OBJECTS_OBJECT_BALL_INC_INCLUDED )
NGIN_SAMPLE_OBJECTS_OBJECT_BALL_INC_INCLUDED = 1

.include "ngin/ngin.inc"

; Object data contents are specified in the header file so that objects can
; access data from other objects.
ngin_Object_declare object_ball
    ; 16.8 fixed point position
    position        .tag ngin_Vector2_16_8

    ; 8.8 fixed point velocity
    velocity        .tag ngin_Vector2_8_8

    ; Number of times that the object has collided against the background
    numCollisions   .byte
ngin_Object_endDeclare

.endif
