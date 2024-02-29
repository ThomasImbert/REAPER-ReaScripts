-- @description Move all but first takes to Alt tracks and assemble in one file
-- @author Thomas Imbert
-- @version 1.2
-- @about
--      To be used with an Alt folder track like the template provided in my "timbert_VASC_AltFolder_default.RTrackTemplate".
--
--		Select all the items of the same dialog take before using this script. The takes will be automatically organized vertically and move to the Alt takes folder.
--
--		Note that this version of the script glues the takes together in the process to allow for a ProTools like punch record, found in my cycle actions "Record Punch PT Like" and "VASC Record Punch PT Like"
-- @changelog
--   #Fixed META marker and validation EXT data getting erased


-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath()..'/scripts/TImbert Scripts/Development/timbert_Lua Utilities.lua'
if reaper.file_exists( timbert_LuaUtils ) then dofile( timbert_LuaUtils ); if not timbert or timbert.version() < 1.4 then timbert.msg('This script requires a newer version of timbert Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"timbert Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires timbert Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'timbert Lua Utilities'"); return end


-- Rename and renumber selected tracks, name by name.lua by juan_r
local function parse_name(trackname)
    local number = string.match (trackname, "(%d*)$")
    local numberdigits = #number
    local basename = string.sub(trackname, 1 , -numberdigits-1)
    return basename, tonumber(number), tonumber(numberdigits)
end

local function renameAndReNumberTracks()

	Num_of_tracks = reaper.CountSelectedTracks(0)
  -- maxnumber[basename] = maximum number found in track names after basename
  maxnumber = {}
  Tracks = {}
  
  -- collect names and possibly numbers

  for i = 0, Num_of_tracks - 1 do
    Tracks[i] = {}
    Tracks[i].mediatrack = reaper.GetSelectedTrack(0,i)
    _, Tracks[i].name = reaper.GetTrackName(Tracks[i].mediatrack, "")

    local basename, number, numberdigits = parse_name(Tracks[i].name)
    if numberdigits == 0 then -- no final number in trackname, we say it's 0 (1 digit)
      number = 0
      numberdigits = 1
    end
    Tracks[i].basename = basename
    Tracks[i].number = number
    Tracks[i].ndigits = numberdigits

    -- find out the max number associated to the given basename

    -- first occurrence of basename? Initialize maxnumber to wimpy maximum
    if maxnumber[basename] == nil then maxnumber[basename] = -1 end
    if number > maxnumber[basename] then maxnumber[basename] = number end
  end

  -- rename the tracks
  for i = 0, Num_of_tracks - 1 do
    new_number = maxnumber[Tracks[i].basename] + 1
    maxnumber[Tracks[i].basename] = new_number
    format = string.format("%%0%dd", Tracks[i].ndigits); -- e.g, "%03d" if it was 3 digits
    new_name = Tracks[i].basename .. string.format(format, new_number);
    
    reaper.GetSetMediaTrackInfo_String(Tracks[i].mediatrack, "P_NAME", new_name, true)
  end
end

-- End of Rename and renumber selected tracks, name by name.lua by juan_r

local function makeItemsSeamless()  
  local num_sel_items = reaper.CountSelectedMediaItems(0)
  local item, bool, notes, itemNotes, data, item_chunk, itemData
  local notes = ""
  local itemsInfo = {}
  local isValid, validValue = {}, {}
  if num_sel_items > 0 then
    for i=1, num_sel_items do
      item = reaper.GetSelectedMediaItem( 0, i-1 )
	  isValid[i], validValue[i] = reaper.GetSetMediaItemInfo_String( item, "P_EXT:VASC_Validation", "", false )
	  itemsInfo[i] = {
		color =   reaper.GetDisplayedMediaItemColor( item ),
		-- validation = validValue[i],
		-- timbert.dbg(validation),
		startPosition = reaper.GetMediaItemInfo_Value( item, "D_POSITION" ),
		}
    end
	reaper.Main_OnCommand(42432, 0) -- Item: Glue items
	for i=1, num_sel_items do
		item = reaper.GetSelectedMediaItem( 0, i-1 )
		reaper.SetMediaItemInfo_Value( item, "I_CUSTOMCOLOR", itemsInfo[i].color )  
		reaper.GetSetMediaItemInfo_String( item, "P_EXT:VASC_Validation", validValue[i], true )
		if i < num_sel_items then
			reaper.SplitMediaItem(  item, itemsInfo[i+1].startPosition )
		end
	end
  end
end


local function moveItemToTracksEach()
	timbert.swsCommand("_BR_SAVE_CURSOR_POS_SLOT_2")
	local item, newItem, trackNumber, selectedTrack, previousTrack, namePreviousTrack
    local itemCount = reaper.CountSelectedMediaItems(0)
    if itemCount == 0 then return end

	local items = {}
	for i = 1, itemCount do
		item = reaper.GetSelectedMediaItem(0,i-1)
		items[i] = reaper.BR_GetMediaItemGUID(item)
	end
	
	for i = 1, #items do
		item = reaper.BR_GetMediaItemByGUID( 0, items[i] )
		if item == nil then return end 
		item_track = reaper.GetMediaItem_Track(item)
		local _, item_chunk =  reaper.GetItemStateChunk(item, '')

		if i == 1 then -- Keep the First selected item on its track
			reaper.DeleteTrackMediaItem(item_track, item)
			newItem = reaper.AddMediaItemToTrack(item_track) 
			reaper.SetItemStateChunk(newItem, item_chunk)
		end

		if (i >= 2 and i <= itemCount) then do -- Moving rest of selected items to the Alt tracks
			reaper.DeleteTrackMediaItem(item_track, item)
			previousTrack = selectedTrack -- store the selected track of the last loop
			selectedTrack = reaper.GetSelectedTrack(0,i-2)
			if selectedTrack == nil then
				reaper.SetOnlyTrackSelected( previousTrack )
				reaper.Main_OnCommand(40062, 0) -- Track: Duplicate tracks
				reaper.TrackList_AdjustWindows(0)
				timbert.swsCommand("_SWS_DELALLITEMS") -- SWS: Delete all items on selected track(s)
				selectedTrack = reaper.GetTrack(0, trackNumber) 
				trackNumber = reaper.GetMediaTrackInfo_Value( selectedTrack , 'IP_TRACKNUMBER' )
				renameAndReNumberTracks()
			end
			trackNumber = reaper.GetMediaTrackInfo_Value( selectedTrack , 'IP_TRACKNUMBER' )
			trackNext = reaper.GetTrack( 0 , trackNumber+1) -- Get next track in list of selected tracks
			newItem = reaper.AddMediaItemToTrack(selectedTrack) -- Create new item to that next track
			reaper.SetItemStateChunk(newItem, item_chunk) -- Recall item chunk
		end
		timbert.swsCommand("_XENAKIOS_MOVEITEMSTOEDITCURSOR")
	end
	end
end

local function main()
	reaper.ClearConsole()
	timbert.swsCommand("_BR_SAVE_CURSOR_POS_SLOT_1")
	timbert.swsCommand("_SWS_SAVETIME1")
	local itemFirst = reaper.GetSelectedMediaItem(0,0)
	local itemFirstTrack = reaper.GetMediaItem_Track(itemFirst)
	reaper.SetTrackSelected(itemFirstTrack , true) -- Selects track of the first of currently selected items
	timbert.swsCommand("_SWS_SAVESEL") 
	reaper.Main_OnCommand(40290, 0) -- Time Selection: Set time selection to items
	makeItemsSeamless()
    timbert.swsCommand("_SWS_SAVEALLSELITEMS1")
	reaper.Main_OnCommand(40625, 0) -- Time selection: Set start point
	reaper.Main_OnCommand(40718, 0) -- Item: Select all items on selected tracks in current time selection
	reaper.Main_OnCommand(40297, 0) -- Track - Unselect (clear selection of) all tracks
	timbert.selectTrack("Alt") -- Add Alt children tracks to track selection
	moveItemToTracksEach()
	timbert.swsCommand("_SWS_RESTORESEL") 
	if timbert.getGuideTrackInfo() == true then
		timbert.swsCommand("_SWS_RESTALLSELITEMS1")
		timbert.pasteNotes()
	end
	reaper.Main_OnCommand(40289, 0) -- Track - Unselect (clear selection of) all items
	reaper.Main_OnCommand(40297, 0) -- Track - Unselect (clear selection of) all tracks
	timbert.swsCommand("_SWS_RESTORESEL") 
	reaper.Main_OnCommand(40718, 0) -- Item: Select all items on selected tracks in current time selection
	timbert.swsCommand("_SWS_RESTTIME1")
	timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_1")
end
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock('Move all but first take to Alt tracks and assemble in one file', 0)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()

