.if .not .defined( NGIN_ASCII_INC_INCLUDED )
NGIN_ASCII_INC_INCLUDED = 1

.enum ngin_Ascii
    kLf     = 10
    kCr     = 13
    kSpace  = 32
    kQuote  = 34
    kZero   = 48
    kNine   = kZero+9
    kPlus   = 43
    kMinus  = 45
    kDot    = 46
.endenum

.endif
