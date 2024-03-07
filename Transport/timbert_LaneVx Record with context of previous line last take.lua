-- @description Lanes Record with context of previous line's last take
-- @author Thomas Imbert
-- @version 1.4
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about 
--      # Part of the timbert Lanes suite of scripts
--
--      Record and immediately preview the previous media item on the same track or in the project.
--
--      This script requires 'Go to previous item stack in fixed lanes of currently selected track' & 'Preview content under edit cursor in last lane or first comp lane of selected track'
-- @changelog 
--   # Removed call to clear the console
-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1, ({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath() .. '/scripts/TImbert Scripts/Development/timbert_Lua Utilities.lua'
if reaper.file_exists(timbert_LuaUtils) then
    dofile(timbert_LuaUtils);
    if not timbert or timbert.version() < 1.921 then
        timbert.msg(
            'This script requires a newer version of TImbert Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',
            "TImbert Lua Utilities");
        return
    end
else
    reaper.ShowConsoleMsg(
        "This script requires TImbert Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'TImbert Lua Utilities'");
    return
end

-- Load lua 'Go to previous item stack in currently selected track fixed lanes' script
--"P:\REAPER-ReaScripts\Transport\timbert_Lanes Go to previous item stack in fixed lanes of currently selected track.lua"
timbert_GoToPrevious = reaper.GetResourcePath() .. '/scripts/TImbert Scripts/Transport/timbert_Lanes Go to previous item stack in fixed lanes of currently selected track.lua'
if not reaper.file_exists(timbert_GoToPrevious) then
    reaper.ShowConsoleMsg(
        "This script requires 'Go to previous item stack in fixed lanes of currently selected track'! Please install it here:\n\nExtensions > ReaPack > Browse Packages > 'timbert_Lanes Go to previous item stack in fixed lanes of currently selected track'");
    return
end

-- Load lua 'Preview last lane or first comp lane' script
timbert_PreviewContext = reaper.GetResourcePath() .. '/scripts/TImbert Scripts/Transport/timbert_Lanes Preview content under edit cursor in last lane or first comp lane of selected track.lua'
if not reaper.file_exists(timbert_PreviewContext) then
    reaper.ShowConsoleMsg(
        "This script requires 'Preview content under edit cursor in last lane or first comp lane of selected track'! Please install it here:\n\nExtensions > ReaPack > Browse Packages > 'timbert_Lanes Preview content under edit cursor in last lane or first comp lane of selected track'");
    return
end
-- dofile(timbert_PreviewContext);


local function ExpandOnStop()
    if reaper.GetPlayState() == 4 then
        return reaper.defer(ExpandOnStop)
    end -- returns if still recording
    if reaper.CountSelectedMediaItems(0) ~= 1 then
        return reaper.defer(ExpandOnStop)
    end -- return if no item is selected
    reaper.Main_OnCommand(40612, 0) -- Item: Set item end to source media end
    reaper.Main_OnCommand(40252, 0) -- Record: Set record mode to normal
    return
end

function maximum(a)
    local mi = 1 -- maximum index
    local m = a[mi] -- maximum value
    for i, val in ipairs(a) do
        if val > m then
            mi = i
            m = val
        end
    end
    return mi
end

local function SelectLastLaneInCurrentItemSelection()
    -- reaper.ClearConsole()
    -- timbert.dbg("item Count: "..reaper.CountSelectedMediaItems( 0 ))
    local itemArray = {}
    for i = 1, reaper.CountSelectedMediaItems(0) do
        local item = reaper.GetSelectedMediaItem(0, i - 1)
        local itemLane = reaper.GetMediaItemInfo_Value(item, "I_FIXEDLANE")
        -- timbert.dbg("Item Lane: "..itemLane)
        itemArray[i] = itemLane
    end
    local itemSelect = reaper.GetSelectedMediaItem(0, maximum(itemArray) - 1)
    -- timbert.dbg("Item to select: "..(maximum(itemArray)))
    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
    reaper.SetMediaItemSelected(itemSelect, true)
end

function main()
    reaper.Main_OnCommand(1016, 0) -- Transport: Stop
    ExpandOnStop()

    if reaper.CountSelectedTracks(0) == 0 then
        timbert.msg("Please select a track first", script_name)
        return
    end

    local track = reaper.GetSelectedTrack(0, 0)
    -- Return if fixed Lanes isn't enable on selected track
    if reaper.GetMediaTrackInfo_Value(track, "I_FREEMODE") ~= 2 then
        timbert.msg(
            "Fixed item lanes isn't enable on selected track, right click on it or go to Track Menu to enable it",
            script_name)
        return
    end

    if reaper.GetMediaTrackInfo_Value(track, "I_RECARM") == 0 then
        timbert.msg("Selected track isn't record armed!", script_name)
        return
    end

	timbert.swsCommand("_BR_SAVE_CURSOR_POS_SLOT_2")
    timbert.swsCommand("_SWS_SAVETIME2")

-- local items, lastLane = timbert.MakeItemArraySortByLane()

    dofile(timbert_GoToPrevious)
	-- dofile(timbert_PreviewContext)


	-- timbert.swsCommand("_SWS_RESTTIME2")
    -- timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_2")


    -- OLD VERSION
    -- reaper.SetMediaTrackInfo_Value(reaper.GetSelectedTrack(0, 0), "C_LANEPLAYS:0", 1)
    -- reaper.Main_OnCommand(40416, 0) -- Item navigation: Select and move to previous item 

    -- if reaper.CountSelectedMediaItems(0) == 0 then
    --     timbert.smartRecord()
    --     return
    -- end

    -- timbert.swsCommand("_XENAKIOS_SELITEMSUNDEDCURSELTX") -- Xenakios/SWS: Select items under edit cursor on selected tracks
    -- reaper.Main_OnCommand(40290, 0) -- Time selection: Set time selection to items 
    -- timbert.swsCommand("_SWS_SAVETIME1")
    -- SelectLastLaneInCurrentItemSelection()
    -- reaper.Main_OnCommand(40290, 0) -- Time selection: Set time selection to items 
    -- timbert.swsCommand("_SWS_SAVETIME2")
    -- timbert.swsCommand("_SWS_PREVIEWTRACK") -- Xenakios/SWS: Preview selected media item through track
    -- timbert.swsCommand("_SWS_RESTTIME1") -- Restore time selection as long as the longest lane take
    -- timbert.moveEditCursor_LeftByTimeSelLength(0, true) -- Move right by that time selection length
    -- reaper.Main_OnCommand(41042, 0) -- Move edit cursor forward one measure
    -- timbert.moveTimeSelectionToCursor()
    -- timbert.swsCommand("_SWS_SAVETIME1")
    -- timbert.swsCommand("_SWS_RESTTIME2") -- restore time selection of length = last line's lane
    -- timbert.swsCommand("_BR_SAVE_CURSOR_POS_SLOT_1")
    -- timbert.moveEditCursor_LeftByTimeSelLength(0)
    -- timbert.swsCommand("_SWS_RESTTIME1")
    -- reaper.SetMediaTrackInfo_Value(reaper.GetSelectedTrack(0, 0), "C_ALLLANESPLAY", 0)
    -- reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of all items)
    -- timbert.smartRecord()
    -- timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_1")
    -- ExpandOnStop()
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

reaper.set_action_options(1 | 2)
main() -- call main function 

reaper.UpdateArrange()

reaper.Undo_EndBlock("LaneVx Record with context of previous line's last take", -1) -- End of the undo block. Leave it at the bottom of your main function.

reaper.PreventUIRefresh(-1)
