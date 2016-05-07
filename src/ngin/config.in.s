.include "ngin/config.generated.inc"
.include "ngin/lua/lua.inc"

.export __ngin_configForceImport : absolute = 1

ngin_Lua_require "config.generated.lua"
