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
timbert_GoToPrevious = reaper.GetResourcePath() ..
                           '/scripts/TImbert Scripts/Transport/timbert_Lanes Go to previous content stack in fixed lanes of currently selected track.lua'
if not reaper.file_exists(timbert_GoToPrevious) then
    reaper.ShowConsoleMsg(
        "This script requires 'Go to previous content stack in fixed lanes of currently selected track'! Please install it here:\n\nExtensions > ReaPack > Browse Packages > 'timbert_Lanes Go to previous content stack in fixed lanes of currently selected track'");
    return
end

-- Load lua 'Go to previous item stack in currently selected track fixed lanes' script
timbert_GoToNext = reaper.GetResourcePath() ..
                       '/scripts/TImbert Scripts/Transport/timbert_Lanes Go to next content in fixed lanes of currently selected track.lua'
if not reaper.file_exists(timbert_GoToNext) then
    reaper.ShowConsoleMsg(
        "This script requires 'Go to next content in fixed lanes of currently selected track'! Please install it here:\n\nExtensions > ReaPack > Browse Packages > 'timbert_Lanes Go to next content in fixed lanes of currently selected track'");
    return
end

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

function main()
    reaper.Main_OnCommand(1016, 0) -- Transport: Stop
    ExpandOnStop()

    -- Validate track selection
    local track, error = timbert.ValidateLanesPreviewScriptsSetup()
    if track == nil then
        timbert.msg(error, script_name)
        return
    end

    if reaper.GetMediaTrackInfo_Value(track, "I_RECARM") == 0 then
        timbert.msg("Selected track isn't record armed!", script_name)
        return
    end

    timbert.swsCommand("_BR_SAVE_CURSOR_POS_SLOT_3")

    dofile(timbert_GoToPrevious)

    if not timbert.ValidateItemUnderEditCursor(true, 2) then
        timbert.smartRecord()
        return
    end

    local laneIndex, previewLength, startTime, endTime, stackLength
    laneIndex = timbert.GetActiveTrackLane(track)
    previewLength = timbert.PreviewLaneContent(track, laneIndex, true)
    timbert.SetTimeSelectionToAllItemsInVerticalStack(true)
    startTime, endTime = reaper.GetSet_LoopTimeRange(false, false, startTime, endTime, false) -- length of the full stack
    stackLength = endTime - startTime
    local cursorPos = reaper.GetCursorPosition()
    dofile(timbert_GoToNext) -- load and dofile

    if reaper.GetCursorPosition() == cursorPos then -- no more content stack later in the session
        timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_3")
        reaper.GetSet_LoopTimeRange(true, true, reaper.GetCursorPosition(), reaper.GetCursorPosition() + stackLength,
            true)
    else
        timbert.SetTimeSelectionToAllItemsInVerticalStack(false)
    end

    reaper.MoveEditCursor((-previewLength), false)
    reaper.SetMediaTrackInfo_Value(reaper.GetSelectedTrack(0, 0), "C_ALLLANESPLAY", 0) -- unsolo all Lanes
    timbert.smartRecord()
    timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_3")
    ExpandOnStop()
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. 

reaper.set_action_options(1 | 2)
main()

reaper.UpdateArrange()

reaper.Undo_EndBlock(script_name, -1) -- End of the undo block.

reaper.PreventUIRefresh(-1)
