-- @description VASC Go to previous Guide segment
-- @author Thomas Imbert
-- @version 1.0
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about Moves edit cursor and region selection to the previous VASC Guide track segment without interrupting recording.
-- @changelog 
--   # Initial Release



-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath()..'/scripts/Thomas Imbert Scripts/Development/timbert_Lua Utilities.lua'
if reaper.file_exists( timbert_LuaUtils ) then dofile( timbert_LuaUtils ); if not timbert or timbert.version() < 1.5 then timbert.msg('This script requires a newer version of timbert Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"timbert Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires timbert Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'timbert Lua Utilities'"); return end

local function regionTimeSelect() -- from Thonex: Set time selection to region at edit cursor  
  Cur_Pos =  reaper.GetCursorPosition()                                                             
  markeridx, regionidx = reaper.GetLastMarkerAndCurRegion( 0, Cur_Pos)
  retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(  regionidx )
  reaper.GetSet_LoopTimeRange(true, false, pos, rgnend, false )
end

local function selectTrackSelectedItem()
    reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
    local item = reaper.GetSelectedMediaItem(0, 0)
    local track = reaper.GetMediaItem_Track(item)
    reaper.SetTrackSelected(track, true)
end

local function goToPreviousTake()     
  timbert.swsCommand("_SWS_SAVESEL") -- Save current track selection
  timbert.selectTrack("Guide")
  timbert.swsCommand("_XENAKIOS_SELITEMSUNDEDCURSELTX") -- _XENAKIOS_SELITEMSUNDEDCURSELTX
  reaper.Main_OnCommand(40416, 0) -- Item: Select and move to previous item
  timbert.swsCommand("_SWS_TOGSAVESEL") -- SWS: Toggle between current and saved track selection
  regionTimeSelect() -- Set time selection to region at edit cursor.lua
end

local function goToPreviousTakeRec()     
  selectTrackSelectedItem()
  timbert.swsCommand("_SWS_SAVESEL") -- Save current track selection
  timbert.swsCommand("_SWS_SAVESELITEMS1") -- "SWS: Save Selected track(s) selected item(s), slot 1"
  timbert.selectTrack("Guide") -- Select Guide track exclusively
  timbert.swsCommand("_XENAKIOS_SELITEMSUNDEDCURSELTX") -- _XENAKIOS_SELITEMSUNDEDCURSELTX
  timbert.storeNotes() -- timbert_Store selected item notes.lua 
  reaper.Main_OnCommand(40416, 0) -- Item: Select and move to previous item
  timbert.swsCommand("_SWS_SAVESELITEMS1") -- "SWS: Save Selected track(s) selected item(s), slot 1"
  reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
  timbert.swsCommand("_SWS_TOGSAVESEL") -- SWS: Toggle between current and saved track selection
  timbert.swsCommand("_SWS_RESTSELITEMS1") -- "SWS: Restore Selected track(s) selected item(s), slot 1"
  timbert.pasteNotes() -- Paste to selected item notes
  timbert.swsCommand("_SWS_TOGSAVESEL") -- SWS: Toggle between current and saved track selection
  timbert.swsCommand("_SWS_RESTSELITEMS1") -- "SWS: Restore Selected track(s) selected item(s), slot 1"
  timbert.swsCommand("_SWS_TOGSAVESEL") -- SWS: Toggle between current and saved track selection
  regionTimeSelect() -- Set time selection to region at edit cursor.lua
end

local function main()
    local record_command_state = reaper.GetToggleCommandState(1013) -- Record state
    
    -- If transport is stopped
    if reaper.GetToggleCommandState(1007) == 0 then
    goToPreviousTake()
    timbert.swsCommand("_SWS_HSCROLL10") -- _SWS_HSCROLL10 Horizontal scroll to put edit cursor at 10% 
    return end

    -- If Record is off
    if record_command_state  == 0 then 
    reaper.Main_OnCommand(40667, 0) -- Transport: Stop
    goToPrevious()
    timbert.swsCommand("_SWS_HSCROLL10") -- _SWS_HSCROLL10 Horizontal scroll to put edit cursor at 10% 
    reaper.Main_OnCommand(1007, 0) -- Transport: Play
    return end

    reaper.Main_OnCommand(40667, 0) -- Transport: Stop
    goToPreviousTakeRec()
    timbert.swsCommand("_SWS_HSCROLL10") -- _SWS_HSCROLL10 Horizontal scroll to put edit cursor at 10% 
    reaper.Main_OnCommand(1013, 0) -- Transport: Record
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

main() 

reaper.UpdateArrange()

reaper.Undo_EndBlock("VASC Go to previous Guide segment", -1 ) -- End of the undo block. Leave it at the bottom of your main function.

reaper.PreventUIRefresh(-1)