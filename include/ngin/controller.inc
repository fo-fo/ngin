.if .not .defined( NGIN_CONTROLLER_INC_INCLUDED )
NGIN_CONTROLLER_INC_INCLUDED = 1

.global   __ngin_Controller_read1
.macro ngin_Controller_read1
    jsr __ngin_Controller_read1
.endmacro

.global   __ngin_Controller_read2
.macro ngin_Controller_read2
    jsr __ngin_Controller_read2
.endmacro

.global   __ngin_Controller_readFast1
.macro ngin_Controller_readFast1
    jsr __ngin_Controller_readFast1
.endmacro

.global   __ngin_Controller_readFast2
.macro ngin_Controller_readFast2
    jsr __ngin_Controller_readFast2
.endmacro

.endif
