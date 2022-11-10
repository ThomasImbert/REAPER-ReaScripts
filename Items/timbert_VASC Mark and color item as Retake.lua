-- @description VASC Mark and color item under mouse cursor as Retake
-- @author Thomas Imbert
-- @version 1.0
-- @about
--      Changes the color of the item under mouse cursor to the SWS custom color n°2 and stores extData. 
--
--      This quick validation system is meant to work with VASC, and will color the current region if VASC Guide track is present.
-- @changelog
--   #Initial Release


-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath()..'/scripts/Thomas Imbert/Development/timbert_Lua Utilities.lua'
if reaper.file_exists( timbert_LuaUtils ) then dofile( timbert_LuaUtils ); if not timbert or timbert.version() < 1.7 then timbert.msg('This script requires a newer version of timbert Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"timbert Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires timbert Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'timbert Lua Utilities'"); return end

-- settings
local colorNumber = "2" -- references the SWS custom color number
local validationTag = "Retake"


-- local variables
local item, itemCount, cursPos, regionidx, regionPos, regionEnd

local function main(colorNumber) 
	timbert.swsCommand("_SWS_SAVESEL") -- Save current track selection
	reaper.Main_OnCommand(40528, 0) -- Item: Select item under mouse cursor
	timbert.swsCommand("_SWS_SAVEALLSELITEMS1") -- Save selected item(s)
    itemCount = reaper.CountSelectedMediaItems(0)
    if itemCount < 1 then return end
	item = reaper.GetSelectedMediaItem( 0, 0 )
	reaper.GetSetMediaItemInfo_String( item, "P_EXT:VASC_Validation", validationTag, true )
	timbert.swsCommand("_SWS_TAKECUSTCOL"..colorNumber) -- SWS: Set selected take(s) to custom color
	timbert.swsCommand("_BR_SAVE_CURSOR_POS_SLOT_1")  -- SWS/BR: Save edit cursor position, slot 01
	reaper.Main_OnCommand(40514, 0) -- View: Move edit cursor to mouse cursor (no snapping)
	cursPos = reaper.GetCursorPosition()
	local customColor = reaper.GetDisplayedMediaItemColor( item ) -- Get media item color
	_, regionidx = reaper.GetLastMarkerAndCurRegion( 0, cursPos ) -- get region at timeStart (current region)
	_, _, regionPos, regionEnd, nameRegion, realIndex = reaper.EnumProjectMarkers( regionidx ) -- get region name
	local maxValidation = checkValidation() 
	if (maxValidation > 1) then
		timbert.swsCommand("_SWS_RESTORESEL") -- Restore track selection
		timbert.swsCommand("_SWS_RESTALLSELITEMS1") -- Restore selected item(s)
		timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_1")  -- SWS/BR: Restore edit cursor position, slot 01
	return end -- Do not color region and guide segment to Retake value if there is greater validation under that region already

	if (timbert.getGuideTrackInfo()) then 
		local _, _, num_regions = reaper.CountProjectMarkers( 0 )
		reaper.SetProjectMarker4( 0, realIndex, true, regionPos, regionEnd, nameRegion, customColor, 0 ) -- set region color
		timbert.colorStoredGuideSegment(colorNumber,validationTag)
	end
	timbert.swsCommand("_SWS_RESTORESEL") -- Restore track selection
	timbert.swsCommand("_SWS_RESTALLSELITEMS1") -- Restore selected item(s)
	timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_1")  -- SWS/BR: Restore edit cursor position, slot 01
end

function checkValidation()
	timbert.swsCommand("_SWS_SAVETIME1") -- SWS: Save time selection, slot 1
	reaper.GetSet_LoopTimeRange2( 0, true, true, regionPos, regionEnd, true )
	reaper.Main_OnCommand(40717, 0) -- Item: Select all items in current time selection
	local item
	local itemNumber = reaper.CountSelectedMediaItems( 0 )
	local maxValidation = 0 -- 0 = no Validation data, 1 = Retake, 2 = Uncertain, 3 = Validated
	local isValid , validValue = {}, {}
	local countValidated,countUncertain,countRetake = 0,0,0
	for i = 1, itemNumber do
		item = reaper.GetSelectedMediaItem( 0, i-1 )
		isValid[i], validValue[i] = reaper.GetSetMediaItemInfo_String( item, "P_EXT:VASC_Validation", validationTag, false )
		if (validValue[i] == "Validated") then
			countValidated = countValidated + 1
		end
		if (validValue[i] == "Uncertain") then
			countUncertain = countUncertain + 1
		end
		if (validValue[i] == "Retake") then
			countRetake = countRetake + 1
		end
	end
	timbert.swsCommand("_SWS_RESTTIME1") -- SWS: Restore time selection, slot 1

	if (itemNumber - countValidated ~= (itemNumber -1) and countValidated > 1 ) then 
		maxValidation = 3 
		return maxValidation
	end
	if ((itemNumber - countUncertain ~= (itemNumber - 1) and maxValidation < 3)  and (countUncertain - countRetake > 1 or countUncertain > 1)) then 
		maxValidation = 2 
		return maxValidation
	end
	maxValidation = 1
	return maxValidation
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

main(colorNumber)

reaper.Undo_EndBlock('Mark and color item under mouse cursor as '..validationTag, 0)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()