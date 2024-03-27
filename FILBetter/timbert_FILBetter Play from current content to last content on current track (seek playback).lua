-- @noindex
-- Retriggering this script before end of playback stops and resets cursor to previous content position.
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

-- Load lua 'Go to previous item stack in currently selected track fixed lanes' script
timbert_GoToNext = reaper.GetResourcePath() ..
                       '/scripts/TImbert Scripts/FILBetter/timbert_FILBetter Go to next content in fixed lanes of currently selected track.lua'
if not reaper.file_exists(timbert_GoToNext) then
    reaper.ShowConsoleMsg(
        "This script requires 'Go to next content in fixed lanes of currently selected track'! Please install it here:\n\nExtensions > ReaPack > Browse Packages > 'FILBetter (Better Track Fixed Item Lanes)'");
    return
end

-- Load 'Solo priority lane with content under edit cursor in selected track' script
timbert_SoloLanePriority = reaper.GetResourcePath() ..
                               '/scripts/TImbert Scripts/FILBetter/timbert_FILBetter Solo priority lane with content under edit cursor in selected track.lua'
if not reaper.file_exists(timbert_SoloLanePriority) then
    reaper.MB(
        "This script requires 'Solo priority lane with content under edit cursor in selected track'! Please install it here:\n\nExtensions > ReaPack > Browse Packages > 'FILBetter (Better Track Fixed Item Lanes)'",
        script_name, 0)
    return
end

-- USERSETTING Loaded from FILBetterCFG.json--
local seekPlaybackRetriggCurPos = FILBetter.LoadConfig("seekPlaybackRetriggCurPos")
local seekPlaybackEndCurPos = FILBetter.LoadConfig("seekPlaybackEndCurPos")
---------------

local _, _, sectionID, cmdID, _, _, _ = reaper.get_action_context()
local startTime, endTime, startCurr, endCurr, playPos, startNext, endNext, curPos, curPosCurrent, curPosPrevious,
    curPosOrigin, isFinished, items

local track, error = timbert.ValidateLanesPreviewScriptsSetup()
if track == nil then
    return
end

local function Exit()
    reaper.Main_OnCommand(1016, 0) -- Transport: Stop

    reaper.PreventUIRefresh(1)
    if isFinished == true then
        if seekPlaybackEndCurPos == "last" then
            reaper.SetEditCurPos(curPosCurrent, true, false)
        elseif seekPlaybackEndCurPos == "after last" then
            timbert.SetTimeSelectionToAllItemsInVerticalStack()
            reaper.Main_OnCommand(40631, 0) -- Go to end of time selection
            reaper.MoveEditCursor(3, false)
        end
    else
        if seekPlaybackRetriggCurPos == "current" then
            reaper.SetEditCurPos(curPosCurrent, true, false)
        elseif seekPlaybackRetriggCurPos == "previous" then
            reaper.SetEditCurPos(curPosPrevious, true, false)
        elseif seekPlaybackRetriggCurPos == "origin" then
            reaper.SetEditCurPos(curPosOrigin, true, false)
        elseif seekPlaybackRetriggCurPos == "last" then
            local track = reaper.GetSelectedTrack(0, 0)
            local itemCount = reaper.CountTrackMediaItems(track)
            local lastItem = reaper.GetTrackMediaItem(track, itemCount - 1)
            reaper.SetEditCurPos(reaper.GetMediaItemInfo_Value(lastItem, "D_POSITION"), true, false)
            timbert.SetTimeSelectionToAllItemsInVerticalStack()
            reaper.Main_OnCommand(40630, 0) -- Go to start of time selection
        end
    end
    reaper.UpdateArrange()
    reaper.PreventUIRefresh(-1)

    reaper.GetSet_LoopTimeRange(true, false, startTime, endTime, false)
    reaper.set_action_options(8)
    reaper.SetToggleCommandState(sectionID, cmdID, 0)
end

local function Seek()
    if reaper.GetPlayState() ~= 1 then
        return
    end
    playPos = reaper.GetPlayPosition()
    if playPos >= endCurr then

        reaper.Undo_BeginBlock() -- Begining of the undo block. 
        reaper.PreventUIRefresh(1)

        reaper.Main_OnCommand(1016, 0) -- Transport: Stop

        dofile(timbert_GoToNext)
        timbert.SetTimeSelectionToAllItemsInVerticalStack()
        items = timbert.GetSelectedItemsInLaneInfo(timbert.GetActiveTrackLane(track))
        reaper.GetSet_LoopTimeRange(true, false, items[1].itemPosition,
            items[#items].itemPosition + items[#items].itemLength, false)
        startNext, endNext = reaper.GetSet_LoopTimeRange(false, false, _, _, false)
        curPosPrevious = startCurr
        curPosCurrent = startNext
        if startNext == startCurr then
            isFinished = true
            reaper.Undo_EndBlock("FILBetter Play last content ", 0) -- End of the undo block. 
            reaper.UpdateArrange()
            reaper.PreventUIRefresh(-1)
            return
        end
        startCurr, endCurr = startNext, endNext

        reaper.Main_OnCommand(1007, 0) -- Transport: Play

        reaper.Undo_EndBlock("FILBetter Play next content", 0) -- End of the undo block. 

        reaper.UpdateArrange()
        reaper.PreventUIRefresh(-1)
    end
    reaper.defer(Seek)
end

function main()
    if reaper.CountTrackMediaItems(track) == 0 then
        return
    end

    startTime, endTime = reaper.GetSet_LoopTimeRange(false, false, _, _, false)

    reaper.PreventUIRefresh(2)
    if timbert.ValidateItemsUnderEditCursorOnSelectedTracks() == false then
        dofile(timbert_GoToNext)
    end

    if timbert.ValidateItemsUnderEditCursorOnSelectedTracks() == false then
        return
    end

    timbert.SetTimeSelectionToAllItemsInVerticalStack()
    items = timbert.GetSelectedItemsInLaneInfo(timbert.GetActiveTrackLane(track))
    reaper.GetSet_LoopTimeRange(true, false, items[1].itemPosition,
        items[#items].itemPosition + items[#items].itemLength, false)
    startCurr, endCurr = reaper.GetSet_LoopTimeRange(false, false, _, _, false)
    curPosOrigin, curPosCurrent, curPosPrevious = startCurr, startCurr, startCurr
    dofile(timbert_SoloLanePriority) -- Solo priority lane
    reaper.Main_OnCommand(1007, 0) -- Transport: Play

    reaper.UpdateArrange()
    reaper.PreventUIRefresh(-2)
    reaper.Undo_EndBlock(script_name, 0) -- End of the undo block. 

    reaper.defer(Seek)

    reaper.atexit(Exit)
end

reaper.Undo_BeginBlock() -- Begining of the undo block. 
reaper.set_action_options(1 | 4)
reaper.SetToggleCommandState(sectionID, cmdID, 1)
main()