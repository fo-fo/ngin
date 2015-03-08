.include "generic-copy.inc"

.segment "NGIN_CODE"

.proc __ngin_copyMemory
    genericCopy CopyParameterType::memory, CopyParameterType::memory
.endproc
