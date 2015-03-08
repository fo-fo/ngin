.include "generic-copy.inc"

.segment "NGIN_CODE"

.proc __ngin_copyPortToMemory
    genericCopy CopyParameterType::memory, CopyParameterType::port
.endproc
