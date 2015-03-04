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

.macro __ngin_longBranch invertedBranchOp, target
    invertedBranchOp over
    jmp target
.local over
over:
.endmacro

.macro ngin_longBranch branch
    ; \todo Give a warning if the branch could have been done without this
    ;       macro.

    .local target
    target = .right( .tcount( {branch} ) - 1, {branch} )

    ; Invert the branch.
    .if .xmatch( .left( 1, {branch} ), beq )
        __ngin_longBranch bne, target
    .elseif .xmatch( .left( 1, {branch} ), bne )
        __ngin_longBranch beq, target
    .elseif .xmatch( .left( 1, {branch} ), bmi )
        __ngin_longBranch bpl, target
    .elseif .xmatch( .left( 1, {branch} ), bpl )
        __ngin_longBranch bmi, target
    .elseif .xmatch( .left( 1, {branch} ), bcc )
        __ngin_longBranch bcs, target
    .elseif .xmatch( .left( 1, {branch} ), bcs )
        __ngin_longBranch bcc, target
    .elseif .xmatch( .left( 1, {branch} ), ngin_branchIfZero )
        __ngin_longBranch ngin_branchIfNotZero, target
    .elseif .xmatch( .left( 1, {branch} ), ngin_branchIfNotZero )
        __ngin_longBranch ngin_branchIfZero, target
    .elseif .xmatch( .left( 1, {branch} ), ngin_branchIfLess )
        __ngin_longBranch ngin_branchIfGreaterOrEqual, target
    .elseif .xmatch( .left( 1, {branch} ), ngin_branchIfGreaterOrEqual )
        __ngin_longBranch ngin_branchIfLess, target
    .else
        .error "ngin_longBranch: couldn't invert branch"
    .endif
.endmacro

.endif
