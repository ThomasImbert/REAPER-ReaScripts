-- @description VASC Record with context of previous line Test LuaUtils
-- @author Thomas Imbert
-- @version 1.0
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about Record and immediately preview the previous media item on the same track or in the project. TEST VERSION
-- @changelog 
--   # Initial Release

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath()..'/scripts/Thomas Imbert/Development/timbert_Lua Utilities.lua'
if reaper.file_exists( timbert_LuaUtils ) then dofile( timbert_LuaUtils ); if not timbert or timbert.version() < 1.0 then timbert.msg('This script requires a newer version of TImbert Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"TImbert Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires TImbert Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'TImbert Lua Utilities'"); return end



-- #local declarations#

-- Record state
local record_command_state = reaper.GetToggleCommandState(1013) 
-- Get computer specific ID of "SWS: Save Selected track(s) selected item(s), slot 1"
local save_item_slot_1_ID = reaper.NamedCommandLookup("_SWS_SAVESELITEMS1") 
-- Get computer specific ID of "SWS: Restore Selected track(s) selected item(s), slot 1"
local restore_item_slot_1_ID = reaper.NamedCommandLookup("_SWS_RESTSELITEMS1") 
-- Get computer specific ID of "_SWS_SAVESEL"
local sws_saveCurrentTrackSelection = reaper.NamedCommandLookup("_SWS_SAVESEL") 
-- Get computer specific ID of "_SWS_RESTORESEL"
local sws_restoreTrackSelection = reaper.NamedCommandLookup("_SWS_RESTORESEL")  
-- Get computer specific ID of "_XENAKIOS_SELITEMSUNDEDCURSELTX"
local sws_selectItems_editCursor_onSelectedTracks = reaper.NamedCommandLookup("_XENAKIOS_SELITEMSUNDEDCURSELTX") 
-- Get computer specific ID of "_SWS_SAVEALLSELITEMS1"
local sws_saveSelectedItems = reaper.NamedCommandLookup("_SWS_SAVEALLSELITEMS1") 
-- Get computer specific ID of "_SWS_RESTALLSELITEMS1"
local sws_restoreSelectedItems = reaper.NamedCommandLookup("_SWS_RESTALLSELITEMS1") 
-- Get computer specific ID of "_SWS_SAVETIME1"
local sws_saveTimeSelection01 = reaper.NamedCommandLookup("_SWS_SAVETIME1") 
-- Get computer specific ID of "_SWS_RESTTIME1"
local sws_restoreTimeSelection01 = reaper.NamedCommandLookup("_SWS_RESTTIME1") 
-- Get computer specific ID of "_BR_SAVE_CURSOR_POS_SLOT_1"
local sws_saveCursorPos01 = reaper.NamedCommandLookup("_BR_SAVE_CURSOR_POS_SLOT_1")
-- Get computer specific ID of "_BR_RESTORE_CURSOR_POS_SLOT_1"
local sws_restoreCursorPos01 = reaper.NamedCommandLookup("_BR_RESTORE_CURSOR_POS_SLOT_1") 
-- Get computer specific ID of "_SWS_TOGTRACKSEL"
local sws_invertTrackSelection = reaper.NamedCommandLookup("_SWS_TOGTRACKSEL") 
-- Get computer specific ID of "_SWS_PREVIEWTRACK"
local sws_previewSelectedItemTrack = reaper.NamedCommandLookup("_SWS_PREVIEWTRACK") 

function moveTimeSelectionToCursor()
  local start_time, end_time = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  if start_time == end_time then return end
  local length = end_time-start_time
  local cursor = reaper.GetCursorPosition()
  reaper.GetSet_LoopTimeRange(true, false, cursor, cursor+length, false)
end

local function moveEditCursor_LeftByTimeSelLength(proj) -- PPP_EditCur_MoveLeftByTimeSelLen converted into lua
	local ts_beg, ts_end, ts_len
	local ec_pos = reaper.GetCursorPositionEx(proj)
	ts_beg, ts_end = reaper.GetSet_LoopTimeRange2(proj, 0, 0, ts_beg, ts_end, 0)
	ts_len = ts_end - ts_beg
	
	reaper.SetEditCurPos2(proj, ec_pos - ts_len, 0, 0)
end

local function smartRecord() -- amagalma_Smart automatic record mode converted into .lua
	local cursorPos
	if reaper.GetPlayState() == 4 then -- Return if already recording
		cursorPos = reaper.GetPlayPosition() 
	return end
	local timeExists, ItemExists = 0, 0
	cursorPos = reaper.GetCursorPosition()
	local timeStart, timeEnd = reaper.GetSet_LoopTimeRange( 0, 0, timeStart, timeEnd, 0 )
	if (timeStart ~= timeEnd and timeStart >= cursorPos) then
		timeExists = 1
	end

	local itemStart
	if reaper.CountSelectedMediaItems(0) > 0 then 
	local item = reaper.GetSelectedMediaItem(0,0)
	itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION") 
		if itemStart >= cursorPos then
			ItemExists =1
		end
	end
	
	if timeExists ~= 1 then	
		reaper.Main_OnCommand(40252, 0) -- Set record mode to normal
		reaper.Main_OnCommand(40046, 0) -- Transport: Start/stop recording at edit cursor
	return end
	if ItemExists ~= 1 then 
		reaper.Main_OnCommand(40076, 0) -- Set record mode to time auto-punch
		reaper.Main_OnCommand(40046, 0) -- Transport: Start/stop recording at edit cursor
	return end
	if itemStart < timeStart then 
		reaper.Main_OnCommand(40076, 0) -- Set record mode to time auto-punch
		reaper.Main_OnCommand(40046, 0) -- Transport: Start/stop recording at edit cursor
	return end
	reaper.Main_OnCommand(40253, 0) -- Set record mode to item auto-punch
	reaper.Main_OnCommand(40046, 0) -- Transport: Start/stop recording at edit cursor
end

function main()
	reaper.Main_OnCommand(sws_saveTimeSelection01, 0)
	reaper.Main_OnCommand(sws_saveCursorPos01, 0)
	reaper.Main_OnCommand(sws_saveCurrentTrackSelection, 0)
	selectTrack(Guide)
	reaper.Main_OnCommand(40718, 0) -- Item: Select all items on selected tracks in current time selection
	reaper.Main_OnCommand(sws_saveSelectedItems, 0)
	selectTrack(Alt)
	reaper.Main_OnCommand(sws_invertTrackSelection, 0)
	reaper.Main_OnCommand(40416, 0) -- Item navigation: Select and move to previous item 
	reaper.Main_OnCommand(40290, 0) -- Time selection: Set time selection to items 
	reaper.Main_OnCommand(sws_previewSelectedItemTrack, 0) -- Xenakios/SWS: Preview selected media item through track
	reaper.Main_OnCommand(sws_restoreCursorPos01, 0) -- SWS/BR: Restore edit cursor position, slot 01 
	moveTimeSelectionToCursor()
	moveEditCursor_LeftByTimeSelLength(0) 
	reaper.Main_OnCommand(sws_restoreTrackSelection, 0)
	reaper.Main_OnCommand(sws_restoreTimeSelection01, 0)
	reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of all items)
	-- reaper.Main_OnCommand(1013, 0) -- Transport: Record
	smartRecord()
	reaper.Main_OnCommand(sws_restoreCursorPos01, 0)
	reaper.Main_OnCommand(sws_restoreSelectedItems, 0)
	storeNotes()
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

main() -- call main function 

reaper.UpdateArrange()

reaper.Undo_EndBlock("VASC Record with context of previous line", -1 ) -- End of the undo block. Leave it at the bottom of your main function.

reaper.PreventUIRefresh(-1)