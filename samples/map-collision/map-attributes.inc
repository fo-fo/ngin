.if .not .defined( NGIN_SAMPLE_MAP_COLLISION_ATTRIBUTES_INC_INCLUDED )
NGIN_SAMPLE_MAP_COLLISION_ATTRIBUTES_INC_INCLUDED = 1

.include "ngin/ngin.inc"

.enum MapAttributes
    kSpecial = ngin_MapData_Attributes0::kUserAttr1
.endenum

.endif
