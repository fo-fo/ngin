.include "generic-copy.inc"

.segment "CODE"

.proc __ngin_fillMemory
    genericCopy CopyParameterType::memory, CopyParameterType::constant
.endproc
