-- @description VASC Record with context of previous line
-- @author Thomas Imbert
-- @version 1.0
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about Record and immediately preview the previous media item on the same track or in the project.
-- @changelog 
--   # Initial Release

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

-- Item navigation: Select and move to previous item 40416
-- Time selection: Set time selection to items 40290
-- Item: Select all items on selected tracks in current time selection 40718

function storeNotes()
	if reaper.CountSelectedMediaItems( 0 ) > 0 then -- Check that an item is selected
		local selItem = reaper.GetSelectedMediaItem( 0 , 0 )
		local itemNotes = ""
		local boolean, itemNotes = reaper.GetSetMediaItemInfo_String(selItem , "P_NOTES", itemNotes, false)
		reaper.DeleteExtState( "vascReaper", "vascNotes", false )
		reaper.SetProjExtState( 0, "vascReaper", "vascNotes", tostring(itemNotes)) 
	end 
end

function pasteNotes()     
	if reaper.CountSelectedMediaItems( 0 ) > 0 then -- Check that an item is selected
		local selItem = reaper.GetSelectedMediaItem( 0 , 0 )
		retval, itemNotes = reaper.GetProjExtState( 0, "vascReaper", "vascNotes")
		reaper.GetSetMediaItemInfo_String(selItem , "P_NOTES", itemNotes, true)
	end
end

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

--[[Track selection functions starts here]]
-- This script was generated by Lokasenna_Select tracks by name.lua
local settings = {
  matchmultiple = false,
  search = "GUIDE",
  selchildren = false,
  selparents = false,
  selsiblings = false,
  matchonlytop = false,
}

local function changeSettingsGuide() -- call this function to setup selectTrack() to select only Guide
	settings = {
	  matchmultiple = false,
	  search = "GUIDE",
	  selchildren = false,
	  selparents = false,
	  selsiblings = false,
	  matchonlytop = false,
	}
end 

local function changeSettingsAlt() -- call this function to setup selectTrack() to add Alt Tracks to selection
	settings = {
	  selparents = false,
	  search = "ALT",
	  selchildren = true,
	  matchonlytop = false,
	  selsiblings = false,
	  add_selection = true,
	  matchmultiple = false,
	}
end

local info = debug.getinfo(1,'S');
script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
local script_filename = ({reaper.get_action_context()})[2]:match("([^/\\]+)$")

-- Search Functions --

-- Returns true if the individual words of str_b all appear in str_a
local function fuzzy_match(str_a, str_b)

    if not (str_a and str_b) then return end
    str_a, str_b = string.lower(tostring(str_a)), string.lower(tostring(str_b))

    --Msg("\nfuzzy match, looking for:\n\t" .. str_b .. "\nin:\n\t" .. str_a .. "\n")

    for word in string.gmatch(str_b, "[^%s]+") do
	   --Msg( tostring(word) .. ": " .. tostring( string.match(str_a, word) ) )
	   if not string.match(str_a, word) then return end
    end
    return true
end

local function is_match(str, tr_name, tr_idx)
    if str:sub(1, 1) == "#" then
	   -- Force an integer until/unless I come up with some sort of multiple track syntax
	   str = tonumber(str:sub(2, -1))
	   return str and (math.floor( tonumber(str) ) == tr_idx)

    elseif tostring(str) then
	   return fuzzy_match(tr_name, tostring(str))
    end
end

local function merge_tables(...)

    local tables = {...}

    local ret = {}
    for i = #tables, 1, -1 do
	   if tables[i] then
		  for k, v in pairs(tables[i]) do
			 if v then ret[k] = v end
		  end
	   end
    end

    return ret

end

local function get_tracks_to_sel(settings)
    --[[
	   settings = {
		  search = str,

		  matchmultiple = bool,
		  matchonlytop = bool,
		  selchildren = bool,
		  selparents = bool,

		  mcp = bool,
		  tcp = bool
	   }
    ]]--
    local matches = {}

    -- Find all matches
    for i = 1, reaper.CountTracks(0) do

	   local tr = reaper.GetTrack(0, i - 1)
	   local _, name = reaper.GetTrackName(tr, "")
	   local idx = math.floor( reaper.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER") )
	   local ischild = reaper.GetTrackDepth(tr) > 0

	   if is_match(settings.search, name, idx) and not (ischild and settings.matchonlytop) then
		  matches[idx] = true
		  if not settings.matchmultiple then break end
	   end
    end
    -- Hacky way to check if length of a hash table == 0
    for k in pairs(matches) do
	   if not k then return {} end
    end

    return merge_tables(matches)
end

local function set_selection(tracks, settings)
    if not tracks then return end
    --if not tracks or #tracks == 0 then return end

    for i = 1, reaper.CountTracks(0) do

	   local tr = reaper.GetTrack(0, i - 1)
	   local keep = settings.add_selection and reaper.IsTrackSelected(tr)
	   reaper.SetTrackSelected(tr, not not (tracks[i] or keep))
    end
    reaper.TrackList_AdjustWindows(false)
end

function selectTrack()
	local tracks = get_tracks_to_sel(settings)
	if tracks then
		set_selection( tracks, settings )
		return
	end
end

--[[Track selection functions ends here]]


function main()
	reaper.Main_OnCommand(sws_saveTimeSelection01, 0)
	reaper.Main_OnCommand(sws_saveCursorPos01, 0)
	reaper.Main_OnCommand(sws_saveCurrentTrackSelection, 0)
	changeSettingsGuide()
	selectTrack()
	reaper.Main_OnCommand(40718, 0) -- Item: Select all items on selected tracks in current time selection
	reaper.Main_OnCommand(sws_saveSelectedItems, 0)
	changeSettingsAlt()
	selectTrack()
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