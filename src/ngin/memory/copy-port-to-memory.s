.include "generic-copy.inc"

.segment "CODE"

.proc __ngin_copyPortToMemory
    genericCopy CopyParameterType::memory, CopyParameterType::port
.endproc
