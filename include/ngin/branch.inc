.if .not .defined( NGIN_BRANCH_INC_INCLUDED )
NGIN_BRANCH_INC_INCLUDED = 1

.macro ngin_branchIfZero to
    beq to
.endmacro

.macro ngin_branchIfNotZero to
    bne to
.endmacro

.macro ngin_branchIfLess to
    bcc to
.endmacro

.macro ngin_branchIfGreaterOrEqual to
    bcs to
.endmacro

.endif
