-- @description Move selected items to edit cursor (snap offset position)
-- @author Thomas Imbert
-- @version 1.0
-- @about 
--      # Move selected items to edit cursor (snap offset position)
--
--      Supports keeping relative item position by changing keepRelativePosition to true in the script
--
--      Anchor item is the selected item under mouse OR selected item on only selected track
--
--      If no item can be identified as anchor, script behave as if keepRelativePosition was false
-- @changelog
--   #Initial release

-- Get this script's name and directory
local script_name = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.lua$")
local reaper = reaper
local luaUtils = true

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath() .. '/Scripts/TImbert Scripts/Development/timbert_Lua Utilities.lua'
if reaper.file_exists(timbert_LuaUtils) then
	dofile(timbert_LuaUtils)
	if not timbert or timbert.version() < 1.927 then
		luaUtils = false
	end
else
	luaUtils = false
end

-- USER OPTION --
local keepRelativePosition = false
-- default = false
-- if set to true, the selected item under mouse OR item on the selected track will move as expected
-- other items will keep their relative position

function main()
	if reaper.CountSelectedMediaItems(0) == 0 then
		if luaUtils == true then
			timbert.TooltipMsg(script_name .. "\nNo item selected", 3)
		end
		return
	end
	local itemMain, itemMainPos, itemMainOffset
	if keepRelativePosition == true then
		local _, _, details = reaper.BR_GetMouseCursorContext()
		if details == "item" and reaper.IsMediaItemSelected(reaper.BR_GetMouseCursorContext_Item()) then
			itemMain = reaper.BR_GetMouseCursorContext_Item()
			itemMainPos = reaper.GetMediaItemInfo_Value(itemMain, "D_POSITION")
			itemMainOffset = reaper.GetMediaItemInfo_Value(itemMain, "D_SNAPOFFSET")
		else
			if reaper.CountSelectedTracks(0) == 1 then
				for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
					if reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, i)) == reaper.GetSelectedTrack(0, 0) then
						itemMain = reaper.GetSelectedMediaItem(0, i)
						itemMainPos = reaper.GetMediaItemInfo_Value(itemMain, "D_POSITION")
						itemMainOffset = reaper.GetMediaItemInfo_Value(itemMain, "D_SNAPOFFSET")
						break
					end
				end
			else
				itemMain = nil
			end
		end
	end

	-- Move
	local itemPos, itemLength, itemOffset
	for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
		itemPos, itemLength, itemOffset =
			reaper.GetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0, i), "D_POSITION"),
			reaper.GetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0, i), "D_LENGTH"),
			reaper.GetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0, i), "D_SNAPOFFSET")
		if reaper.GetSelectedMediaItem(0, i) == itemMain or itemMain == nil or reaper.CountSelectedMediaItems(0) == 1 then
			reaper.SetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0, i), "D_POSITION",
				reaper.GetCursorPosition() -
				itemOffset)
		else
			reaper.SetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0, i), "D_POSITION",
				reaper.GetCursorPosition() -
				(itemMainOffset + (itemMainPos - itemPos)))
		end
	end

	-- Tooltip
	if luaUtils == false then
		return
	end
	if keepRelativePosition == true and itemMain ~= nil and reaper.CountSelectedMediaItems(0) > 1 then
		local _, trackID = reaper.GetSetMediaTrackInfo_String(reaper.GetMediaItem_Track(itemMain), "P_NAME", "",
			false)
		if trackID == "" then
			trackID = reaper.GetMediaTrackInfo_Value(reaper.GetMediaItem_Track(itemMain),
				"IP_TRACKNUMBER")
			trackID = math.floor(trackID)
		end
		timbert.TooltipMsg(script_name .. "\nRelative to item on track " .. trackID, 3)
	end
end

reaper.set_action_options(1 | 2)

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock(script_name, 0)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
