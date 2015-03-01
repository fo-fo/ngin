.include "generic-copy.inc"

.segment "CODE"

.proc __ngin_copyPort
    genericCopy CopyParameterType::port, CopyParameterType::port
.endproc
