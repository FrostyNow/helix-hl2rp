
local PLUGIN = PLUGIN

PLUGIN.name = "Item Stack"
PLUGIN.author = "Ronald"
PLUGIN.description = "Allows stackable items to share the same inventory slot while preserving individual item data."

ix.util.Include("libs/sh_stack.lua", "shared")
ix.util.Include("derma/cl_stack.lua", "client")
