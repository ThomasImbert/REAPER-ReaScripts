-- @description Swap item with alt take (item) under mouse cursor
-- @author Thomas Imbert
-- @version 1.0
-- @about
--      To be used with an Alt folder track like the template provided in my "timbert_VASC_AltFolder_default.RTrackTemplate".
--
--      Swap item under mouse cursor with the item on the main track above it.
-- @changelog
--   #Initial Release


-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath()..'/scripts/TImbert Scripts/Development/timbert_Lua Utilities.lua'
if reaper.file_exists( timbert_LuaUtils ) then dofile( timbert_LuaUtils ); if not timbert or timbert.version() < 1.4 then timbert.msg('This script requires a newer version of timbert Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"timbert Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires timbert Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'timbert Lua Utilities'"); return end

local function saveSelectedTracks() -- uses ExtState to recall later on with addSavedTracksSelection(), from me2beats save and restore scripts
	local selTracks = ''
	for i = 0, reaper.CountSelectedTracks()-1 do
	  selTracks = selTracks..reaper.GetTrackGUID(reaper.GetSelectedTrack(0,i))
	end
	
	reaper.DeleteExtState('AltTakeSwap', 'selTracks', 0)
	reaper.SetExtState('AltTakeSwap', 'selTracks', selTracks, 0)
end

local function addSavedTracksSelection()
	local selTracks = reaper.GetExtState('AltTakeSwap', 'selTracks')
	if not selTracks or selTracks == '' then return end
	
	for guid in selTracks:gmatch'{.-}' do
	  local track = reaper.BR_GetMediaTrackByGUID(0, guid)
	  if track then reaper.SetTrackSelected(track,1) end
	end
end


local function swapItemsVertically()
	local item, newItem
    local itemCount = reaper.CountSelectedMediaItems(0)

	if itemCount == 1 then 
		timbert.msg("Error: You need 2 items with the same start time exactly, one under an 'ALT' folder track  and the other outside of it" ,"Error: Swap take with alt take under mouse cursor")
		timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_1")
		timbert.swsCommand("_SWS_RESTORESEL") 
		timbert.swsCommand("_SWS_RESTALLSELITEMS1")
		return end

	if itemCount > 2 then 
		timbert.msg("Error: More than one Media item outside of Alt tracks, please only have one vertically","Error: Swap take with alt take under mouse cursor")
		timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_1")
		timbert.swsCommand("_SWS_RESTORESEL") 
	return end

	local items, item, track, itemChunk = {}, {}, {}, {}
	for i = 1, itemCount do -- Get Item Data
		item = reaper.GetSelectedMediaItem(0,i-1)
		items[i] = reaper.BR_GetMediaItemGUID (item)
	end

	for i = 1, #items do -- Remove Items from their original track
		item = reaper.BR_GetMediaItemByGUID( 0, items[i] )
		track[i] = reaper.GetMediaItem_Track(item)
		_, itemChunk[i] =  reaper.GetItemStateChunk(item, '')
		reaper.DeleteTrackMediaItem(track[i], item)
	end

	for i = 0, itemCount-1 do -- Place each item to the other item's original track
		timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_1")
		newItem = reaper.AddMediaItemToTrack(track[(1+i)]) 
		reaper.SetItemStateChunk(newItem, tostring(itemChunk[(2-i)]))
	end
	
	reaper.Main_OnCommand(40297, 0) -- Track - Unselect (clear selection of) all tracks
	reaper.SetTrackSelected( track[1], true ) -- select track of top item
	reaper.SetMediaItemSelected( reaper.BR_GetMediaItemByGUID( 0, items[2] ), true ) -- select top item
	timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_1")
end

local function main()
	timbert.swsCommand("_SWS_SAVESEL") 
	timbert.swsCommand("_SWS_SAVETIME1")
	timbert.swsCommand("_BR_SAVE_CURSOR_POS_SLOT_1") 
	timbert.swsCommand("_SWS_SAVEALLSELITEMS1")
	reaper.Main_OnCommand(40528, 0) -- Item: Select item under mouse cursor

    local itemCount = reaper.CountSelectedMediaItems(0)
    if itemCount < 1 then return end

	reaper.Main_OnCommand(41110, 0) -- Track: Select track under mouse
	reaper.Main_OnCommand(40290, 0) -- Time Selection: Set time selection to items
	saveSelectedTracks()
	reaper.Main_OnCommand(40297, 0) -- Track - Unselect (clear selection of) all tracks
	timbert.selectTrack("Guide") -- Select Guide track exclusively
	timbert.selectTrack("Alt") -- Add Alt children tracks to track selection
	timbert.swsCommand("_SWS_TOGTRACKSEL")  -- SWS: Toggle (invert) track selection
	addSavedTracksSelection()
	timbert.swsCommand("_XENAKIOS_SELITEMSUNDEDCURSELTX") -- Xenakios/SWS: Select items under edit cursor on selected tracks
	swapItemsVertically()
	timbert.swsCommand("_SWS_RESTTIME1")
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock('Swap take with alt take under mouse cursor', 0)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()