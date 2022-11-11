-- @description VASC Record Punch PT like with notes
-- @author Thomas Imbert
-- @version 1.5
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about A record punch similar to ProTool's, intended to work with VASC. Copies notes from the Guide track item onto the recorded take.
-- @changelog 
--   # Added Auto Extend Guide Start

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath()..'/scripts/Thomas Imbert/Development/timbert_Lua Utilities.lua'
if reaper.file_exists( timbert_LuaUtils ) then dofile( timbert_LuaUtils ); if not timbert or timbert.version() < 1.3 then timbert.msg('This script requires a newer version of TImbert Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"TImbert Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires TImbert Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'TImbert Lua Utilities'"); return end

local isExtendLoop = false
local isExtRecord, extValue 
local cursPos, regionPos, regionEnd, nameRegion, color

function extendGuide()
	isExtRecord, extValue = reaper.GetProjExtState( 0, "VASC_Record", "ExtendGuide" )
	if extValue == 0 then isExtendLoop = false else isExtendLoop = true end -- convert extValue into bool for cleaner code 
	if not isExtendLoop then return end -- bool false when play / stop is , interrupt Loop
	timbert.swsCommand("_BR_SAVE_CURSOR_POS_SLOT_1") -- Save Edit cursor Pos 
	reaper.Main_OnCommand(40434, 0) -- View: Move edit cursor to play cursor
	cursPos = reaper.GetCursorPosition()
	_, regionidx = reaper.GetLastMarkerAndCurRegion( 0, cursPos ) -- get region at timeStart (current region)
	_, _, regionPos, regionEnd, nameRegion, _, color = reaper.EnumProjectMarkers3( 0, regionidx ) -- get region name

	if (regionEnd - cursPos) < 1 then
		timbert.swsCommand("_SWS_SAVEALLSELITEMS1") -- Save selected item(s)
		reaper.MoveEditCursor( regionEnd, false )
		timbert.swsCommand("_SWS_SAVETIME1") -- SWS: Save time selection, slot 1
		reaper.GetSet_LoopTimeRange2( 0, true, false, regionEnd, (regionEnd+2), false ) -- create a 2s time selection starting from region End
		reaper.Main_OnCommand(40200, 0) -- Time selection: Insert empty space at time selection (moving later items)
		reaper.Main_OnCommand(40617, 0) -- Markers: Delete time signature marker near cursor (To be called Twice after the previous, once for each end of the time selection)
		reaper.MoveEditCursor( regionEnd+2, false )
		reaper.Main_OnCommand(40617, 0) -- Markers: Delete time signature marker near cursor (To be called Twice after the previous, once for each end of the time selection)
		timbert.selectStoredGuideTrackItem() 
		reaper.Main_OnCommand(41311, 0) -- Item edit: Trim right edge of item to edit cursor
		SetProjectMarker3( 0, regionidx, true, regionPos, regionEnd+2, nameRegion, color )
		timbert.swsCommand("_SWS_RESTTIME1") -- SWS: Restore time selection, slot 1
		timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_1") -- Restore Edit cursor Pos 
		timbert.swsCommand("_SWS_RESTALLSELITEMS1") -- Restore selected item(s)
	end
	reaper.defer(extendGuide)
end


function main()
	local isRecording = reaper.GetToggleCommandState(1013)
	local isGuideTrackInfo = timbert.getGuideTrackInfo()

	if (isGuideTrackInfo == false and isRecording == 0 ) then
		reaper.Main_OnCommand(1013, 0) -- Transport: Record   
		-- timbert.dbg("No GuideTrackInfo and not recording")
	return end
	
	if (isGuideTrackInfo == false and isRecording == 1 ) then
		reaper.Main_OnCommand(40666, 0) -- Record: Start new files during recording  
		reaper.Main_OnCommand(40670, 0) -- Record: Add recorded media to project
		-- timbert.dbg("No GuideTrackInfo and recording")
	return end

	if (isGuideTrackInfo == true and isRecording == 1) then
		reaper.Main_OnCommand(40666, 0) -- Record: Start new files during recording
		reaper.Main_OnCommand(40670, 0) -- Record: Add recorded media to project
		timbert.pasteNotes()
		reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of all items)
		timbert.selectStoredGuideTrackItem()
		-- timbert.dbg("GuideTrackInfo and recording")
	return end
	
	-- timbert.dbg("GuideTrackInfo and not recording")
	reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of all items)
	timbert.selectStoredGuideTrackItem() 
	reaper.Main_OnCommand(1013, 0) -- Transport: Record   
	if not isExtendLoop then 
		reaper.SetProjExtState( 0, "VASC_Record", "ExtendGuide", 1 ) 
		extendGuide()
	end
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

main() -- call main function 

reaper.UpdateArrange()

reaper.Undo_EndBlock("VASC Record Punch with notes", -1 ) -- End of the undo block. Leave it at the bottom of your main function.

reaper.PreventUIRefresh(-1)