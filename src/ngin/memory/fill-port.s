.include "generic-copy.inc"

.segment "CODE"

.proc __ngin_fillPort
    genericCopy CopyParameterType::port, CopyParameterType::constant
.endproc
