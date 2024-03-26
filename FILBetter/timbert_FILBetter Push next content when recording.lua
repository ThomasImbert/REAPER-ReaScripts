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
if not timbert or timbert.version() < 1.926 then
    reaper.MB(
        "This script requires a newer version of TImbert Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages",
        script_name, 0)
    return
end

-- Load Config
timbert_FILBetter = reaper.GetResourcePath() ..
                        '/scripts/TImbert Scripts/FILBetter/timbert_FILBetter (Better Track Fixed Item Lanes).lua'
dofile(timbert_FILBetter)

-- USERSETTING Loaded from FILBetterCFG.json--
local pushNextContentTime = FILBetter.LoadConfig("pushNextContentTime")
---------------

local _, _, sectionID, cmdID, _, _, _ = reaper.get_action_context()
local cursorPos1, cursorPos2, nextContentPos, nextContentItem, emptyItem, currentContentEndPos, playPos, timeStart,
    timeEnd, track, lane, arrangeStart, arrangeEnd
local val_recPushRecordingEXT
local timeThreshold = pushNextContentTime

function Exit()
    reaper.SetToggleCommandState(sectionID, cmdID, 0)
end

function main()
    timeStart, timeEnd = reaper.GetSet_LoopTimeRange(false, false, _, _, false) -- Save TimeSelect at time of recording
    if reaper.GetPlayState() <= 04 then -- if no recording
        reaper.SetProjExtState(0, "FILBetter", "RecPush_RecordingStarted", "false")
        reaper.SetProjExtState(0, "FILBetter", "RecPush_RecordingStartPos", "")
        return reaper.defer(main)
    end

    -- if Recording
    _, val_recPushRecordingEXT = reaper.GetProjExtState(0, "FILBetter", "RecPush_RecordingStarted")
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    if val_recPushRecordingEXT ~= "true" then -- do once the following, reset when stopping recording
        arrangeStart, arrangeEnd = reaper.GetSet_ArrangeView2(0, false, 0, 0, _, _)
        reaper.SetProjExtState(0, "FILBetter", "RecPush_RecordingStarted", "true")
        reaper.SetProjExtState(0, "FILBetter", "RecPush_TimeStart", timeStart)
        reaper.SetProjExtState(0, "FILBetter", "RecPush_TimeEnd", timeEnd)
        track = reaper.GetSelectedTrack(0, 0)
        cursorPos1 = reaper.GetCursorPosition()
        reaper.SetProjExtState(0, "FILBetter", "RecPush_RecordingStartPos", cursorPos1)
        timbert.SetTimeSelectionToAllItemsInVerticalStack()
        reaper.Main_OnCommand(40631, 0) -- Go to end of time selection   
        currentContentEndPos = reaper.GetCursorPosition()
        reaper.SetProjExtState(0, "FILBetter", "RecPush_AnchorContentEndPos", currentContentEndPos)
        lane = timbert.GetActiveTrackLane(track)
        reaper.SetMediaTrackInfo_Value(track, "C_ALLLANESPLAY", 1) -- Activate all lanes
        reaper.Main_OnCommand(40417, 0) -- Item navigation: Select and move to next item
        if reaper.GetCursorPosition() ~= currentContentEndPos then
            _, nextContentItem = reaper.GetSetMediaItemInfo_String(reaper.GetSelectedMediaItem(0, 0), "GUID",
                "nextContentItem", false)
            reaper.SetProjExtState(0, "FILBetter", "RecPush_NextContentItem", nextContentItem)
            nextContentPos = reaper.GetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0, 0), "D_POSITION")
            reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
        end
        reaper.Main_OnCommand(40026, 0) -- File: Save project to Save all ProjExtState
        reaper.SetMediaTrackInfo_Value(track, "C_LANEPLAYS:" .. tostring(lane), 1) -- reset selected lane
        reaper.GetSet_LoopTimeRange(true, false, timeStart, timeEnd, false) -- reset timeselection to initial state
        reaper.SetEditCurPos(cursorPos1, false, false)
        reaper.GetSet_ArrangeView2(0, true, 0, 0, arrangeStart, arrangeEnd)
    end

    _, cursorPos1 = reaper.GetProjExtState(0, "FILBetter", "RecPush_RecordingStartPos")
    playPos = reaper.GetPlayPosition()
    if nextContentPos == nil or (nextContentPos - playPos) > timeThreshold or playPos < currentContentEndPos then
        reaper.Undo_EndBlock(script_name, 0)
        reaper.PreventUIRefresh(-1)
        reaper.defer(main)
        return
    end

    cursorPos2 = reaper.GetCursorPosition()
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SAVESELITEMS1"), 0) -- SWS: Save selected track(s) selected item(s), slot 1    
    timeStart, timeEnd = reaper.GetSet_LoopTimeRange(false, false, _, _, false) -- Save TimeSelect at before pushing items
    reaper.Main_OnCommand(40020, 0) -- Time selection: Remove (unselect) time selection and loop points
    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
    arrangeStart, arrangeEnd = reaper.GetSet_ArrangeView2(0, false, 0, 0, _, _)
    while nextContentPos - playPos < timeThreshold do
        reaper.SetEditCurPos(playPos, true, false)
        reaper.GetSet_LoopTimeRange(true, true, playPos, nextContentPos, false) -- create a timeThreshold length time selection at play position
        reaper.Main_OnCommand(40310, 0) -- Set ripple editing per-track
        reaper.Main_OnCommand(40142, 0) -- Insert empty item
        emptyItem = reaper.GetSelectedMediaItem(0, 0)
        reaper.Main_OnCommand(40309, 0) -- Set ripple editing off
        reaper.DeleteTrackMediaItem(track, emptyItem)
        _, nextContentItem = reaper.GetProjExtState(0, "FILBetter", "RecPush_NextContentItem")
        nextContentPos = reaper.GetMediaItemInfo_Value(reaper.BR_GetMediaItemByGUID(0, nextContentItem), "D_POSITION")
    end

    reaper.SetEditCurPos(cursorPos2, false, false)
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_RESTSELITEMS1"), 0) -- SWS: Restore selected track(s) selected item(s), slot 1
    reaper.GetSet_LoopTimeRange(true, false, timeStart, timeEnd, false) -- reset timeselection 
    reaper.GetSet_ArrangeView2(0, true, 0, 0, arrangeStart, arrangeEnd)
    reaper.defer(main)
    reaper.Undo_EndBlock(script_name, 8)
    reaper.PreventUIRefresh(-1)
end

reaper.set_action_options(1)
reaper.SetToggleCommandState(sectionID, cmdID, 1)
reaper.RefreshToolbar2(sectionID, cmdID)
reaper.defer(main)
reaper.atexit(Exit)
