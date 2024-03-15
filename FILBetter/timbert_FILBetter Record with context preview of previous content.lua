-- @noindex
-- Record and immediately preview the previous content on the same track, in last lane or first comp lane
-- TrimOnStop auto expands recorded item end beyond the timeselection auto punch
----------------------------
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
if not timbert or timbert.version() < 1.924 then
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

-- Load Config
timbert_FILBetter = reaper.GetResourcePath() ..
                        '/scripts/TImbert Scripts/FILBetter/timbert_FILBetter (Better Track Fixed Item Lanes).lua'
dofile(timbert_FILBetter)

-- USERSETTING Loaded from FILBetterCFG.json--
local showValidationErrorMsg = FILBetter.LoadConfig("showValidationErrorMsg")
local recallCursPosWhenTrimingOnStop = FILBetter.LoadConfig("recallCursPosWhenTrimingOnStop")
local recordingBellOn = FILBetter.LoadConfig("recordingBellOn")
-- In Metronome setting, allow run during recording
-- Try Primary beat = 250Hz and 100ms duration and sine soft start for a gentle rec bell
---------------

local punchInPos, track, previewLength, laneIndexContext, _
local itemsPre, takesPre, itemsPost, takesPost = {}, {}, {}, {}

local function GetTakes(items)
    if items == nil or #items < 1 then
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
        reaper.SetEditCurPos(cursorPos, false, false)
        reaper.GetSet_LoopTimeRange(true, false, startTime, endTime, false)
    end
    return nextContentPos
end

local function TrimOnStop(retrigg) -- get last recorded item and trim start to current content stack
    local item, cursorRecall, punchInPos
    reaper.PreventUIRefresh(1)

    if not retrigg or retrigg == false then
        reaper.Main_OnCommand(40252, 0) -- Record: Set record mode to This script requires a newer version of TImbert Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages
        cursorRecall = reaper.GetCursorPosition()
        _, punchInPos = reaper.GetProjExtState(0, "FILBetter", "RecWithContext_PunchInPos")
        reaper.SetEditCurPos(punchInPos, false, false)
        timbert.SetTimeSelectionToAllItemsInVerticalStack(true)
        itemsPost = timbert.MakeItemArraySortByLane()
        takesPost = GetTakes(itemsPost)
        item = FindRecordedItem(takesPre, takesPost)
        reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
        if item == nil then
            return
        end
        reaper.SetMediaItemSelected(item, true)
        reaper.SetEditCurPos(punchInPos, false, false)
    else
        item = reaper.GetSelectedMediaItem(0, 0)
    end
    reaper.Main_OnCommand(41305, 0) -- Item edit: Trim left edge of item to edit cursor
    reaper.Main_OnCommand(40635, 0) -- Time selection: Remove (unselect) time selection
    reaper.Main_OnCommand(42938, 0) -- Track lanes: Move items up if possible to minimize lane usage
    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
    reaper.SetMediaTrackInfo_Value(reaper.GetMediaItemInfo_Value(item, "P_TRACK"),
        "C_LANEPLAYS:" .. reaper.GetMediaItemInfo_Value(item, "I_FIXEDLANE"), 1)

    reaper.PreventUIRefresh(-1)
    if not retrigg and recallCursPosWhenTrimingOnStop == true then
        reaper.SetEditCurPos(cursorRecall, false, false)
    end
    return
end

local function RecordLoop(retrigg)
    -- If stopped, trimOnStop and exit
    if reaper.GetPlayState() == 0 then
        reaper.Undo_BeginBlock() -- Begining of the undo block. 
        TrimOnStop(retrigg)
        reaper.SetProjExtState(0, "FILBetter", "RecWithContext_Track", "")
        reaper.SetProjExtState(0, "FILBetter", "RecWithContext_ContextPos", "")
        reaper.SetProjExtState(0, "FILBetter", "RecWithContext_ContextLane", "")
        reaper.SetProjExtState(0, "FILBetter", "RecWithContext_PunchInPos", "")
        reaper.Undo_EndBlock("FILBetter Trim on stop", -1) -- End of the undo block.
        return
    end

    -- if not recording
    if reaper.GetPlayState() < 4 then
        return reaper.defer(RecordLoop)
    end

    -- Enable Metronome tick as recording bell for 1 tick
    if recordingBellOn == true and punchInPos ~= nil then
        reaper.PreventUIRefresh(1)
        if reaper.GetPlayPosition() > punchInPos - 0.1 then
            reaper.SetTempoTimeSigMarker(0, -1, punchInPos, -1, -1, reaper.Master_GetTempo(), 4, 4, false)
            reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_METROON"), 0) -- SWS: Metronome enable
        end
        if reaper.GetPlayPosition() > punchInPos + 0.2 then
            reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_METROOFF"), 0) -- SWS: Metronome disable
            reaper.DeleteTempoTimeSigMarker(0, 1)
        end
        reaper.PreventUIRefresh(-1)
    end
    return reaper.defer(RecordLoop)
end

function main()
    local cursorPosInitial, cursorPosContext
    reaper.Undo_BeginBlock() -- Begining of the undo block. 
    if reaper.GetPlayState() >= 4 then
        reaper.Main_OnCommand(1016, 0) -- Transport: Stop
        _, punchInPos = reaper.GetProjExtState(0, "FILBetter", "RecWithContext_PunchInPos")
        reaper.SetEditCurPos(punchInPos, false, false)
        RecordLoop(true)

    end

    if reaper.GetPlayState() == 0 then
        -- Validate track selection
        local track, error = timbert.ValidateLanesPreviewScriptsSetup()
        if track == nil then
            if showValidationErrorMsg == true then
                timbert.msg(error, script_name)
            end
            return
        end

        if reaper.GetMediaTrackInfo_Value(track, "I_RECARM") == 0 then
            if showValidationErrorMsg == true then
                timbert.msg("Selected track isn't record armed!", script_name)
            end
            return
        end

        -- store value once for this recording series
        reaper.SetProjExtState(0, "FILBetter", "RecWithContext_Track", reaper.GetTrackGUID(track))
        cursorPosInitial = reaper.GetCursorPosition()
        dofile(timbert_GoToPrevious)
        if timbert.ValidateItemsUnderEditCursorOnSelectedTracks() == false or cursorPosInitial ==
            reaper.GetCursorPosition() then
            reaper.Main_OnCommand(40635, 0) -- Time selection: Remove (unselect) time selection
            timbert.smartRecord()
            itemsPre = {}
            punchInPos = cursorPosInitial
            reaper.SetProjExtState(0, "FILBetter", "RecWithContext_PunchInPos", punchInPos)
            reaper.Undo_EndBlock(script_name, -1) -- End of the undo block.
            RecordLoop(false)
            return
        end
        cursorPosContext = reaper.GetCursorPosition()
        reaper.SetProjExtState(0, "FILBetter", "RecWithContext_ContextPos", cursorPosContext)
        laneIndexContext = timbert.GetActiveTrackLane(track)
        reaper.SetProjExtState(0, "FILBetter", "RecWithContext_ContextLane", laneIndexContext)

        if IsLastContentOnTrack(false) == nil then
            reaper.SetEditCurPos(cursorPosInitial, false, false)
            punchInPos = cursorPosInitial
            itemsPre = {}
        else
            punchInPos = reaper.GetCursorPosition()
            timbert.SetTimeSelectionToAllItemsInVerticalStack(true)
            itemsPre = timbert.MakeItemArraySortByLane()
            takesPre = GetTakes(itemsPre)
        end
        reaper.SetProjExtState(0, "FILBetter", "RecWithContext_PunchInPos", punchInPos)
        reaper.Main_SaveProject(0, false)
    end

    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
    reaper.Main_OnCommand(40635, 0) -- Time selection: Remove (unselect) time selection
    _, cursorPosContext = reaper.GetProjExtState(0, "FILBetter", "RecWithContext_ContextPos")
    _, track = reaper.GetProjExtState(0, "FILBetter", "RecWithContext_Track")
    track = reaper.BR_GetMediaTrackByGUID(0, track)
    _, laneIndexContext = reaper.GetProjExtState(0, "FILBetter", "RecWithContext_ContextLane")
    reaper.SetEditCurPos(cursorPosContext + 0.01, true, false) -- add 0.01 since cursorPoContext number got converted into string when stored in ExtState
    previewLength = timbert.PreviewLaneContent(track, tonumber(laneIndexContext), true)

    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
    _, punchInPos = reaper.GetProjExtState(0, "FILBetter", "RecWithContext_PunchInPos")
    reaper.GetSet_LoopTimeRange(true, true, punchInPos, punchInPos + 400, false)
    reaper.SetEditCurPos(punchInPos, false, false)
    reaper.MoveEditCursor(-previewLength, false)
    reaper.SetMediaTrackInfo_Value(reaper.GetSelectedTrack(0, 0), "C_ALLLANESPLAY", 0) -- unsolo all Lanes
    timbert.smartRecord()
    reaper.SetEditCurPos(punchInPos, false, false)
    reaper.Undo_EndBlock(script_name, -1) -- End of the undo block.
    RecordLoop(false)
end

reaper.PreventUIRefresh(1)

reaper.set_action_options(1 | 2)
main()

reaper.UpdateArrange()

reaper.PreventUIRefresh(-1)
