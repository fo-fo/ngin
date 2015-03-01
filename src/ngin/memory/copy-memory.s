.include "generic-copy.inc"

.segment "CODE"

.proc __ngin_copyMemory
    genericCopy CopyParameterType::memory, CopyParameterType::memory
.endproc
