.include "generic-copy.inc"

.segment "NGIN_CODE"

.proc __ngin_copyMemoryToPort
    genericCopy CopyParameterType::port, CopyParameterType::memory
.endproc
