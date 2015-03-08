.include "generic-copy.inc"

.segment "NGIN_CODE"

.proc __ngin_fillMemory
    genericCopy CopyParameterType::memory, CopyParameterType::constant
.endproc
