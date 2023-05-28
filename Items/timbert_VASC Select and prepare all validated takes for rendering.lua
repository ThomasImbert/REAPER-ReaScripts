-- @description VASC Select and prepare all validated takes for rendering
-- @author Thomas Imbert
-- @version 1.0
-- @about
--      Selects all the validated takes in a VASC prepared session and move them to the beginning of each Guide segment is set in the settings.
--
--      This script is intented to work with the main VASC and VASC validation scripts.
-- @changelog
--   #Initial Release


-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath()..'/scripts/Thomas Imbert Scripts/Development/timbert_Lua Utilities.lua'
if reaper.file_exists( timbert_LuaUtils ) then dofile( timbert_LuaUtils ); if not timbert or timbert.version() < 1.8 then timbert.msg('This script requires a newer version of timbert Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"timbert Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires timbert Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'timbert Lua Utilities'"); return end

-- settings
local validationTag = "Validated"
local reposition = true -- Make sure to only have a unique media item per Guide Segment / region and per track. Glue composite takes before using this script
						 -- Also make sure that not such item is mistakingly placed BEFORE the associated region (even by a little)
local function main() 
	timbert.swsCommand("_SWS_SAVESEL") -- Save current track selection
	reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of all items)
	timbert.selectTrack('Guide')
	timbert.selectTrack('Alt') 
	timbert.selectTrack('Reference') 
	timbert.swsCommand("_SWS_TOGTRACKSEL") -- SWS: Toggle (invert) track selection
	reaper.Main_OnCommand(40421, 0) -- Item: select all items on track
	local itemCount = reaper.CountSelectedMediaItems( 0 )
	local validationEXT
	local item
	for i=1, itemCount do -- Deselect item that don't containt "Validated" EXT
		item = reaper.GetSelectedMediaItem( 0, itemCount - i) 
		_, validationEXT = reaper.GetSetMediaItemInfo_String( item, "P_EXT:VASC_Validation", "value", false )
		if validationEXT ~= validationTag then 
			reaper.SetMediaItemSelected( item, false )
		else if reposition then -- Item is marked Validated, make sure its start time is at Meta Marker / start of region
				local itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
				local itemSnap = reaper.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
				local itemStartTime = itemPos + itemSnap
				local nearestMarkerIdx, nearestRegionIdx = reaper.GetLastMarkerAndCurRegion( 0, itemStartTime )
				local _, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers( nearestRegionIdx )
				if itemStartTime > pos then 
					reaper.SetMediaItemPosition( item, pos, true )
				end
			end
		end
	end
	timbert.swsCommand("_SWS_RESTORESEL") -- Restore track selection
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock('VASC Select and prepare all validated takes for rendering', 0)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()