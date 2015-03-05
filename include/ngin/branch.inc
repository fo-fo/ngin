.if .not .defined( NGIN_BRANCH_INC_INCLUDED )
NGIN_BRANCH_INC_INCLUDED = 1

.include "ngin/core.inc"

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

.macro __ngin_longBranch invertedBranchOp, target
    invertedBranchOp over
    jmp target
.local over
over:
.endmacro

; Helper for ngin_longBranch
.define __ngin_longBranchMatch( op ) .xmatch( .left( 1, {branch} ), op )

.macro ngin_longBranch branch
    .local target
    target = .right( .tcount( {branch} ) - 1, {branch} )

    ; Invert the branch.
    .if __ngin_longBranchMatch beq
        __ngin_longBranch bne, target
    .elseif __ngin_longBranchMatch bne
        __ngin_longBranch beq, target
    .elseif __ngin_longBranchMatch bmi
        __ngin_longBranch bpl, target
    .elseif __ngin_longBranchMatch bpl
        __ngin_longBranch bmi, target
    .elseif __ngin_longBranchMatch bcc
        __ngin_longBranch bcs, target
    .elseif __ngin_longBranchMatch bcs
        __ngin_longBranch bcc, target
    .elseif __ngin_longBranchMatch ngin_branchIfZero
        __ngin_longBranch ngin_branchIfNotZero, target
    .elseif __ngin_longBranchMatch ngin_branchIfNotZero
        __ngin_longBranch ngin_branchIfZero, target
    .elseif __ngin_longBranchMatch ngin_branchIfLess
        __ngin_longBranch ngin_branchIfGreaterOrEqual, target
    .elseif __ngin_longBranchMatch ngin_branchIfGreaterOrEqual
        __ngin_longBranch ngin_branchIfLess, target
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

.endif
