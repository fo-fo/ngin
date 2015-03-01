.if .not .defined( NGIN_MEMORY_GENERIC_COPY_INC_INCLUDED )
NGIN_MEMORY_GENERIC_COPY_INC_INCLUDED = 1

.include "ngin/memory.inc"
.include "ngin/branch.inc"
.include "ngin/core.inc"

.enum CopyParameterType
    ; Parameter is a memory address which is increased on each iteration.
    memory

    ; Parameter is a memory address which is not increased, but memory is
    ; re-read on each iteration.
    port

    ; Parameter is a constant byte value (hibyte is ignored).
    ; Only valid for source.
    constant
.endenum

.macro genericCopyIteration destinationType, sourceType, destination, source
    .if sourceType = CopyParameterType::memory
        lda ( source ), y
    .elseif sourceType = CopyParameterType::port
        ; Use (foo, x) addressing because only X is guaranteed to be zero.
        lda ( source, x )
    .endif

    .if destinationType = CopyParameterType::memory
        sta ( destination ), y
    .elseif destinationType = CopyParameterType::port
        ; Use (foo, x) addressing because only X is guaranteed to be zero,
        ; AND to avoid the dummy read when writing.
        sta ( destination, x )
    .else
        .error "invalid destination type"
    .endif
.endmacro

.macro genericCopy destinationType, sourceType
    ; Concept used here is the same as in the _MOVFWD routine at:
    ;     http://www.obelisk.demon.co.uk/6502/algorithms.html

    ; \todo There are some optimization possibilities for different variations.

    .local destination, source, size
    destination = __ngin_genericCopy_destination
    source = __ngin_genericCopy_source
    size = __ngin_genericCopy_size

    .if sourceType = CopyParameterType::constant
        lda source
    .endif

    ldy #0
    ; \todo Use X as counter when possible (when we don't need lda (foo, x))
    ldx size + 1
    ngin_branchIfZero sizeLessThan256
        ; Set X to 0 for (foo, x) addressing.
        ldx #0
        ; Copy all 256 byte pages.
        allPagesLoop:
            ; Copy one 256 byte page.
            fullPageLoop:
                genericCopyIteration {destinationType}, {sourceType}, \
                                     {destination}, {source}
                iny
            ngin_branchIfNotZero fullPageLoop

            ; Increase address.
            .if destinationType = CopyParameterType::memory
                inc destination + 1
            .endif
            .if sourceType = CopyParameterType::memory
                inc source + 1
            .endif

            dec size + 1
        ngin_branchIfNotZero allPagesLoop
    sizeLessThan256:
    ; X = 0 here.

    ; Copy the remaining bytes (size modulo 256).
    ; Y = 0 here.
    restLoop:
        ; If Y reached size%256, we're done.
        cpy size + 0
        beq done
        genericCopyIteration {destinationType}, {sourceType}, \
                             {destination}, {source}
        iny
    ; Unconditional branch
    ; \todo Add a macro for unconditional branch, including runtime assert.
    ngin_branchIfNotZero restLoop

done:
    rts
.endmacro

.endif
