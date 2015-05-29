.if .not .defined( NGIN_BRANCH_INC_INCLUDED )
NGIN_BRANCH_INC_INCLUDED = 1

.include "ngin/core.inc"
.include "ngin/assert.inc"

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

.macro ngin_branchIfLessSigned to
    bmi to
.endmacro

.macro ngin_branchIfGreaterOrEqualSigned to
    bpl to
.endmacro

.macro __ngin_longBranch invertedBranchOp, target
    invertedBranchOp over
    jmp target
.local over
over:
.endmacro

; Helper for ngin_longBranch
.define __ngin_branchMatch( op ) .xmatch( .left( 1, {branch} ), op )

.macro ngin_longBranch branch
    .local target
    target = .right( .tcount( {branch} ) - 1, {branch} )

    ; Invert the branch.
    .if __ngin_branchMatch beq
        __ngin_longBranch bne, target
    .elseif __ngin_branchMatch bne
        __ngin_longBranch beq, target
    .elseif __ngin_branchMatch bmi
        __ngin_longBranch bpl, target
    .elseif __ngin_branchMatch bpl
        __ngin_longBranch bmi, target
    .elseif __ngin_branchMatch bcs
        __ngin_longBranch bcc, target
    .elseif __ngin_branchMatch bcc
        __ngin_longBranch bcs, target
    .elseif __ngin_branchMatch ngin_branchIfZero
        __ngin_longBranch ngin_branchIfNotZero, target
    .elseif __ngin_branchMatch ngin_branchIfNotZero
        __ngin_longBranch ngin_branchIfZero, target
    .elseif __ngin_branchMatch ngin_branchIfGreaterOrEqual
        __ngin_longBranch ngin_branchIfLess, target
    .elseif __ngin_branchMatch ngin_branchIfLess
        __ngin_longBranch ngin_branchIfGreaterOrEqual, target
    .else
        .error "ngin_longBranch: couldn't invert branch"
    .endif

    ; Give a warning if the branch could have been done without a long branch.
    ; \todo Option to turn the warning off? There are situations where e.g.
    ;       code generated from a macro might need a long branch in one
    ;       expansion, but not need it in another.
    ; \note The maximum range for backward branch is -128 from the instruction
    ;       following the branch, but we must subtract 3 because we added a JMP.
    ;       The maximum range for a forward branch is +127.
    .assert target - * < -128-3 .or target - * > 127, warning, \
            "branch could've been done without ngin_longBranch"
.endmacro

; This macro can be used to mark unconditional branches in code, and to do
; a runtime check to verify that the expected condition holds.
.macro ngin_always branch
    .if __ngin_branchMatch beq
        .define __ngin_always_flag     "Z"
        .define __ngin_always_expected "true"
    .elseif __ngin_branchMatch bne
        .define __ngin_always_flag     "Z"
        .define __ngin_always_expected "false"
    .elseif __ngin_branchMatch bmi
        .define __ngin_always_flag     "N"
        .define __ngin_always_expected "true"
    .elseif __ngin_branchMatch bpl
        .define __ngin_always_flag     "N"
        .define __ngin_always_expected "false"
    .elseif __ngin_branchMatch bcs
        .define __ngin_always_flag     "C"
        .define __ngin_always_expected "true"
    .elseif __ngin_branchMatch bcc
        .define __ngin_always_flag     "C"
        .define __ngin_always_expected "false"
    .elseif __ngin_branchMatch ngin_branchIfZero
        .define __ngin_always_flag     "Z"
        .define __ngin_always_expected "true"
    .elseif __ngin_branchMatch ngin_branchIfNotZero
        .define __ngin_always_flag     "Z"
        .define __ngin_always_expected "false"
    .elseif __ngin_branchMatch ngin_branchIfGreaterOrEqual
        .define __ngin_always_flag     "C"
        .define __ngin_always_expected "true"
    .elseif __ngin_branchMatch ngin_branchIfLess
        .define __ngin_always_flag     "C"
        .define __ngin_always_expected "false"
    .else
        .error "ngin_always: unrecognized branch"
    .endif

    ngin_assert \
        .sprintf( "REG.%s == %s", __ngin_always_flag, __ngin_always_expected ), \
        .sprintf( "ngin_always: expected %s==%s", \
                   __ngin_always_flag, __ngin_always_expected )

    .undefine __ngin_always_flag
    .undefine __ngin_always_expected

    branch
.endmacro

.endif
