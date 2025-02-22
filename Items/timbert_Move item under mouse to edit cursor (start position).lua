-- @description Move item under mouse to edit cursor (start position)
-- @author Thomas Imbert
-- @version 1.0
-- @about
--      # Move item under mouse to edit cursor (start position)
-- @changelog
--   #Initial release

-- Get this script's name and directory
local script_name = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.lua$")
local reaper = reaper
local luaUtils = true

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath() .. "/Scripts/TImbert Scripts/Development/timbert_Lua Utilities.lua"
if reaper.file_exists(timbert_LuaUtils) then
	dofile(timbert_LuaUtils)
	if not timbert or timbert.version() < 1.929 then
		luaUtils = false
	end
else
	luaUtils = false
end

function main()
	local _, _, details = reaper.BR_GetMouseCursorContext()
	-- return if mouse not on an item
	if details ~= "item" then
		if luaUtils == true then
			timbert.TooltipMsg(script_name .. "\nNo item under mouse cursor", 3)
		end
		return
	end
	local item = reaper.BR_GetMouseCursorContext_Item()
	reaper.SetMediaItemInfo_Value(item, "D_POSITION", reaper.GetCursorPosition())
end

reaper.set_action_options(1 | 2)

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock(script_name, 0)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
