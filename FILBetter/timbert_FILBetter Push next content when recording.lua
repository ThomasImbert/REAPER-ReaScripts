-- @noindex
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
if not timbert or timbert.version() < 1.923 then
    reaper.MB(
        "This script requires a newer version of TImbert Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages",
        script_name, 0)
    return
end

local _, _, sectionID, cmdID, _, _, _ = reaper.get_action_context()
local cursorPos1, cursorPos2, nextContentPos, emptyItem, currentContentEndPos, playPos, timeStart, timeEnd, track, lane
local retval_recPushRecordingEXT, val_recPushRecordingEXT
local timeThreshold = 10

function Exit()
    reaper.SetToggleCommandState(sectionID, cmdID, 0)
end

function main()
    timeStart, timeEnd = reaper.GetSet_LoopTimeRange(false, false, _, _, false) -- Save TimeSelect at time of recording
    if reaper.GetPlayState() <= 04 then -- if no recording
        reaper.SetProjExtState(0, "FILBetter", "RecPush_RecordingStarted", "false")
        return reaper.defer(main)
    end
    retval_recPushRecordingEXT, val_recPushRecordingEXT = reaper.GetProjExtState(0, "FILBetter",
        "RecPush_RecordingStarted")
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    if val_recPushRecordingEXT ~= "true" then
        reaper.SetProjExtState(0, "FILBetter", "RecPush_RecordingStarted", "true")
        reaper.SetProjExtState(0, "FILBetter", "RecPush_TimeStart", timeStart)
        reaper.SetProjExtState(0, "FILBetter", "RecPush_TimeEnd", timeEnd)

        track = reaper.GetSelectedTrack(0, 0)
        cursorPos1 = reaper.GetCursorPosition()
        timbert.SetTimeSelectionToAllItemsInVerticalStack()
        reaper.Main_OnCommand(40631, 0) -- Go to end of time selection   
        currentContentEndPos = reaper.GetCursorPosition()
        lane = timbert.GetActiveTrackLane(track)
        reaper.SetMediaTrackInfo_Value(track, "C_ALLLANESPLAY", 1) -- Activate all lanes
        reaper.Main_OnCommand(40417, 0) -- Item navigation: Select and move to next item
        reaper.SetMediaTrackInfo_Value(track, "C_LANEPLAYS:" .. tostring(lane), 1)
        if reaper.GetCursorPosition() == currentContentEndPos then
            return reaper.defer(main)
        else
            nextContentPos = reaper.GetCursorPosition()
            reaper.MoveEditCursor(cursorPos1 - nextContentPos, false)
            reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
        end
    end

    reaper.GetSet_LoopTimeRange(true, false, timeStart, timeEnd, false) -- reset timeselection to initial state

    playPos = reaper.GetPlayPosition()
    if (nextContentPos - playPos) > timeThreshold or playPos < currentContentEndPos then
        reaper.Undo_EndBlock(script_name, 0)
        reaper.PreventUIRefresh(-1)
        reaper.defer(main)
        return
    end

    cursorPos2 = reaper.GetCursorPosition()
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SAVESELITEMS1"), 0) -- SWS: Save selected track(s) selected item(s), slot 1    
    reaper.Main_OnCommand(40020, 0) -- Time selection: Remove (unselect) time selection and loop points
    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
    while nextContentPos - playPos < timeThreshold do
        reaper.GetSet_LoopTimeRange(true, false, playPos, nextContentPos, false) -- create a timeThreshold length time selection at play position
        reaper.Main_OnCommand(40310, 0) -- Set ripple editing per-track
        reaper.Main_OnCommand(40142, 0) -- Insert empty item
        emptyItem = reaper.GetSelectedMediaItem(0, 0)
        reaper.Main_OnCommand(40309, 0) -- Set ripple editing off
        reaper.DeleteTrackMediaItem(track, emptyItem)
        nextContentPos = nextContentPos + (nextContentPos - playPos)
    end
    _, timeStart = reaper.GetProjExtState(0, "FILBetter", "RecPush_TimeStart")
    _, timeEnd = reaper.GetProjExtState(0, "FILBetter", "RecPush_TimeEnd")
    reaper.GetSet_LoopTimeRange(true, false, timeStart, timeEnd, false) -- reset timeselection to initial state
    -- nextContentPos = nextContentPos + timeThreshold
    reaper.MoveEditCursor(cursorPos1 - reaper.GetCursorPosition(), false)
    reaper.defer(main)
    reaper.Undo_EndBlock(script_name, 8)
    reaper.PreventUIRefresh(-1)
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_RESTSELITEMS1"), 0) -- SWS: Restore selected track(s) selected item(s), slot 1
end

reaper.set_action_options(1)
reaper.SetToggleCommandState(sectionID, cmdID, 1)
reaper.RefreshToolbar2(sectionID, cmdID)
reaper.defer(main)
reaper.atexit(Exit)
