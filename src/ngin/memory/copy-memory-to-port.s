.include "generic-copy.inc"

.segment "CODE"

.proc __ngin_copyMemoryToPort
    genericCopy CopyParameterType::port, CopyParameterType::memory
.endproc
