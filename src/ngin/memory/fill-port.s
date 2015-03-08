.include "generic-copy.inc"

.segment "NGIN_CODE"

.proc __ngin_fillPort
    genericCopy CopyParameterType::port, CopyParameterType::constant
.endproc
