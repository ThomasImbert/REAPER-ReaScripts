-- @description VASC Extend Guide
-- @author Thomas Imbert
-- @version 1.0
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about Auto extends the current VASC Guide segment when recording.
-- @changelog 
--   # Initial Release

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath()..'/scripts/Thomas Imbert/Development/timbert_Lua Utilities.lua'
if reaper.file_exists( timbert_LuaUtils ) then dofile( timbert_LuaUtils ); if not timbert or timbert.version() < 1.3 then timbert.msg('This script requires a newer version of TImbert Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"TImbert Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires TImbert Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'TImbert Lua Utilities'"); return end

local playPos, regionPos, regionEnd, nameRegion, color, regionidx
local is_new_value, filename, sectionID, cmdID, mode, resolution, val = reaper.get_action_context()


function exit() 
	reaper.SetToggleCommandState( sectionID, cmdID, 0 )
end

function main() 	
	
	reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

	reaper.PreventUIRefresh(1) 

	if reaper.GetToggleCommandState(1013)  == 0 then 
		reaper.defer(main)
		reaper.PreventUIRefresh(-1)
	return end 

	-- timbert.swsCommand("_SWS_SAVETIME1") -- Save time selection slot 1
	playPos = reaper.GetPlayPosition() -- returns latency-compensated actual-what-you-hear position
	_, regionidx = reaper.GetLastMarkerAndCurRegion( 0, playPos ) -- get region at timeStart (current region)
	_, _, regionPos, regionEnd, nameRegion, regionidx, color = reaper.EnumProjectMarkers3( 0, regionidx ) -- get region data

	-- timbert.dbg("regionEnd - cursPos = " .. regionEnd - cursPos)
	if (regionEnd - playPos) > 1 then 
		reaper.defer(main)
		reaper.PreventUIRefresh(-1)
	return end
	

	reaper.GetSet_LoopTimeRange2( 0, true, false, regionEnd, (regionEnd+2), false ) -- create a 2s time selection starting from region End
	reaper.Main_OnCommand(40200, 0) -- Time selection: Insert empty space at time selection (moving later items)
	timeSigIdx = reaper.FindTempoTimeSigMarker( 0, (playPos+4) )
	reaper.DeleteTempoTimeSigMarker( 0, timeSigIdx )
	reaper.DeleteTempoTimeSigMarker( 0, timeSigIdx-1 )
	local userSelectedItem = reaper.GetSelectedMediaItem( 0, 0 )
	reaper.IsMediaItemSelected( userSelectedItem )
	timbert.selectStoredGuideTrackItem() 
	itemGuide = reaper.GetSelectedMediaItem( 0, 0 ) 
	length = reaper.GetMediaItemInfo_Value( itemGuide, "D_LENGTH" )
	reaper.SetMediaItemLength(  reaper.GetSelectedMediaItem( 0, 0 ), length+2, false )
	reaper.SetProjectMarker3( 0, regionidx, true, regionPos, (regionEnd+2), nameRegion, 0 )

	if userSelectedItem ~= itemGuide then 
		reaper.SetMediaItemSelected( userSelectedItem, true ) 
	else
		reaper.SetMediaItemSelected( itemGuide, true )
	end
	reaper.Main_OnCommand(40020, 0) -- Time selection: Remove (unselect) time selection and loop points

	reaper.defer(main)
	reaper.Undo_EndBlock("VASC Extend Guide", 4 ) -- End of the undo block. Leave it at the bottom of your main function.

	reaper.PreventUIRefresh(-1)
end

reaper.SetToggleCommandState(sectionID, cmdID, 1)
reaper.RefreshToolbar2(sectionID, cmdID)
reaper.defer(main)
reaper.atexit(exit)

