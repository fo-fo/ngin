.if .not .defined( NGIN_LFSR8_INC_INCLUDED )
NGIN_LFSR8_INC_INCLUDED = 1

; \todo Function for seeding?

; Latest value produced by ngin_Lfsr8_random
.global ngin_Lfsr8_value

; Generates a pseudorandom number in range [1, 255] using an 8-bit LFSR.
.global __ngin_Lfsr8_random
.macro ngin_Lfsr8_random
    jsr __ngin_Lfsr8_random
.endmacro

.endif
