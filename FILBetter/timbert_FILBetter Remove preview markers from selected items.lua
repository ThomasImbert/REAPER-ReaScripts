-- @noindex
-- Get this script's name
local script_name = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.lua$")
local reaper = reaper

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath() .. "/Scripts/TImbert Scripts/Development/timbert_Lua Utilities.lua"
if not reaper.file_exists(timbert_LuaUtils) then
	reaper.MB(
		"This script requires TImbert Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'TImbert Lua Utilities'",
		script_name,
		0
	)
	return
end
dofile(timbert_LuaUtils)
if not timbert or timbert.version() < 1.929 then
	reaper.MB(
		"This script requires a newer version of TImbert Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages",
		script_name,
		0
	)
	return
end

-- Load Config
timbert_FILBetter = reaper.GetResourcePath()
	.. "/Scripts/TImbert Scripts/FILBetter/timbert_FILBetter (Better Track Fixed Item Lanes).lua"
dofile(timbert_FILBetter)

-- USERSETTING Loaded from FILBetterCFG.json--
local previewMarkerName = FILBetter.LoadConfig("previewMarkerName") -- default "[FILB]"
---------------

local function FindTakeMarkerIndex(take)
	local markerName, index, _
	-- Check if "previewMarkerName" take Marker already exists
	if reaper.GetNumTakeMarkers(take) > 0 then
		for i = 0, reaper.GetNumTakeMarkers(take) - 1 do
			_, markerName, _ = reaper.GetTakeMarker(take, i)
			if markerName == previewMarkerName then
				index = i
				break
			end
		end
	end
	return index
end

function main()
	local itemCount = reaper.CountSelectedMediaItems(0)
	if itemCount < 1 then
		return
	end

	local take, index

	for i = 0, itemCount - 1 do
		take = reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, i))
		index = FindTakeMarkerIndex(take)
		if index ~= nil then
			reaper.DeleteTakeMarker(take, index)
		end
	end
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block.

main()

reaper.UpdateArrange()

reaper.Undo_EndBlock(script_name, -1) -- End of the undo block.

reaper.PreventUIRefresh(-1)
