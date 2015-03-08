.include "generic-copy.inc"

.segment "NGIN_CODE"

.proc __ngin_copyPort
    genericCopy CopyParameterType::port, CopyParameterType::port
.endproc
