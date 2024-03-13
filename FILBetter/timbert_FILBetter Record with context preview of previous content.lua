-- @noindex
-- Record and immediately preview the previous content on the same track, in last lane or first comp lane
-- TrimOnStop auto expands recorded item end beyond the timeselection auto punch
----------------
-- USERSETTING--
local recordingBellOn = false
-- In Metronome setting, allow run during recording
-- Try Primary beat = 250Hz and 100ms duration and sine soft start for a gentle rec bell
---------------

-- Get this script's name
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local reaper = reaper

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath() .. '/scripts/TImbert Scripts/Development/timbert_Lua Utilities.lua'
if not reaper.file_exists(timbert_LuaUtils) then
    reaper.MB(
        "This script requires TImbert Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'TImbert Lua Utilities'",
        script_name, 0)
    return
end
dofile(timbert_LuaUtils)
if not timbert or timbert.version() < 1.922 then
    reaper.MB(
        "This script requires a newer version of TImbert Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages",
        script_name, 0)
    return
end

-- Load lua 'Go to previous item stack in currently selected track fixed lanes' script
timbert_GoToPrevious = reaper.GetResourcePath() ..
                           '/scripts/TImbert Scripts/FILBetter/timbert_FILBetter Go to previous content in fixed lanes of currently selected track.lua'
if not reaper.file_exists(timbert_GoToPrevious) then
    reaper.ShowConsoleMsg(
        "This script requires 'Go to previous content in fixed lanes of currently selected track'! Please install it here:\n\nExtensions > ReaPack > Browse Packages > 'FILBetter (Better Track Fixed Item Lanes)'");
    return
end

-- Load lua 'Go to previous item stack in currently selected track fixed lanes' script
timbert_GoToNext = reaper.GetResourcePath() ..
                       '/scripts/TImbert Scripts/FILBetter/timbert_FILBetter Go to next content in fixed lanes of currently selected track.lua'
if not reaper.file_exists(timbert_GoToNext) then
    reaper.ShowConsoleMsg(
        "This script requires 'Go to next content in fixed lanes of currently selected track'! Please install it here:\n\nExtensions > ReaPack > Browse Packages > 'FILBetter (Better Track Fixed Item Lanes)'");
    return
end

local metronomePos, track
local itemsPre, takesPre, itemsPost, takesPost = {}, {}, {}, {}

local function GetTakes(items)
    if #items < 1 then
        return
    end
    local takes = {}
    local take, takeName
    for i = 1, #items do
        take = reaper.GetActiveTake(items[i].item)
        _, takeName = reaper.GetSetMediaItemTakeInfo_String(reaper.GetActiveTake(items[i].item), "P_NAME", "takeName",
            false)
        table.insert(takes, {
            take = take,
            takeName = takeName
        })
    end
    return takes
end

local function FindRecordedItem(takesPre, takesPost)
    local recordedItem, take, takeName
    local foundMatch = false
    for i = 1, #takesPost do
        foundMatch = false
        takeName = takesPost[i].takeName
        for j = 1, #takesPre do
            if takeName == takesPre[j].takeName then
                foundMatch = true
                break
            end
        end
        if foundMatch == false then
            recordedItem = reaper.GetMediaItemTake_Item(takesPost[i].take)
        end
    end
    return recordedItem
end

local function IsLastContentOnTrack(keepSelectionState)
    local cursorPos = reaper.GetCursorPosition()
    local startTime, endTime = reaper.GetSet_LoopTimeRange(false, false, _, _, false)
    dofile(timbert_GoToNext)
    if reaper.GetCursorPosition() == cursorPos then
        return
    end
    local nextContentPos = reaper.GetCursorPosition()
    if keepSelectionState == true then
        reaper.MoveEditCursor(cursorPos - nextContentPos, false)
        reaper.GetSet_LoopTimeRange(true, false, startTime, endTime, false)
    end
    return nextContentPos
end

local function TrimOnStop(retrigg) -- get last recorded item and trim start to current content stack
    local item
    reaper.PreventUIRefresh(1)

    if not retrigg or retrigg == false then
        reaper.Main_OnCommand(40252, 0) -- Record: Set record mode to normal
        -- reaper.DeleteTempoTimeSigMarker(0, 1)
        timbert.swsCommand("_BR_SAVE_CURSOR_POS_SLOT_4")
        timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_3")
        timbert.SetTimeSelectionToAllItemsInVerticalStack(true)
        itemsPost = timbert.MakeItemArraySortByLane()
        takesPost = GetTakes(itemsPost)
        item = FindRecordedItem(takesPre, takesPost)
        reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
        if item == nil then
            return
        end
        reaper.SetMediaItemSelected(item, true)
        timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_3")
    else
        item = reaper.GetSelectedMediaItem(0, 0)
    end
    reaper.Main_OnCommand(41305, 0) -- Item edit: Trim left edge of item to edit cursor
    reaper.Main_OnCommand(40635, 0) -- Time selection: Remove (unselect) time selection
    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
    reaper.Main_OnCommand(42938, 0) -- Track lanes: Move items up if possible to minimize lane usage
    reaper.PreventUIRefresh(-1)
    return
end

local function RecordLoop(retrigg)
    -- If stopped, trimOnStop and exit
    if reaper.GetPlayState() == 0 then
        reaper.Undo_BeginBlock() -- Begining of the undo block. 
        TrimOnStop(retrigg)
        reaper.Undo_EndBlock("FILBetter Trim on stop", -1) -- End of the undo block.
        return
    end

    -- if not recording
    if reaper.GetPlayState() < 4 then
        return reaper.defer(RecordLoop)
    end

    -- Enable Metronome tick as recording bell for 1 beat
    if recordingBellOn == true and metronomePos ~= nil then
        if reaper.GetPlayPosition() > metronomePos - 0.1 then
            reaper.PreventUIRefresh(1)
            reaper.SetTempoTimeSigMarker(0, -1, metronomePos, -1, -1, reaper.Master_GetTempo(), 4, 4, false)
            reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_METROON"), 0) -- SWS: Metronome enable
        end
        if reaper.GetPlayPosition() > metronomePos + 0.1 then
            reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_METROOFF"), 0) -- SWS: Metronome disable
            reaper.DeleteTempoTimeSigMarker(0, 1)
            reaper.UpdateArrange()
            reaper.PreventUIRefresh(-1)
        end
    end
    return reaper.defer(RecordLoop)
end

function main()
    reaper.Undo_BeginBlock() -- Begining of the undo block. 
    if reaper.GetPlayState() >= 4 then
        reaper.Main_OnCommand(1016, 0) -- Transport: Stop
        RecordLoop(true)
    end

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
        itemsPre = {}
        return
    end

    local laneIndex, previewLength
    laneIndex = timbert.GetActiveTrackLane(track)
    previewLength = timbert.PreviewLaneContent(track, laneIndex, true)
    timbert.SetTimeSelectionToAllItemsInVerticalStack(true)

    local nextContentPos = IsLastContentOnTrack(false)
    if nextContentPos == nil then
        timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_3")
        metronomePos = reaper.GetCursorPosition()
        itemsPre = {}
    else
        timbert.swsCommand("_BR_SAVE_CURSOR_POS_SLOT_3")
        timbert.SetTimeSelectionToAllItemsInVerticalStack(true)
        itemsPre = timbert.MakeItemArraySortByLane()
        takesPre = GetTakes(itemsPre)
    end

    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
    reaper.GetSet_LoopTimeRange(true, true, reaper.GetCursorPosition(), reaper.GetProjectLength(0) + 400, true)
    metronomePos = reaper.GetCursorPosition()
    reaper.MoveEditCursor((-previewLength), false)
    reaper.SetMediaTrackInfo_Value(reaper.GetSelectedTrack(0, 0), "C_ALLLANESPLAY", 0) -- unsolo all Lanes
    timbert.smartRecord()
    timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_3")
    reaper.Undo_EndBlock(script_name, -1) -- End of the undo block.
    RecordLoop()
end

reaper.PreventUIRefresh(1)

reaper.set_action_options(1 | 2)
main()

reaper.UpdateArrange()

reaper.PreventUIRefresh(-1)
