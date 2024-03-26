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

-- Load 'Solo last lane or first comp lane with content of selected track' script
timbert_SoloLanePriority = reaper.GetResourcePath() ..
                               '/scripts/TImbert Scripts/FILBetter/timbert_FILBetter Solo priority lane with content under edit cursor in selected track.lua'
if not reaper.file_exists(timbert_SoloLanePriority) then
    reaper.MB(
        "This script requires 'Solo priority lane with content under edit cursor in selected track'! Please install it here:\n\nExtensions > ReaPack > Browse Packages > 'FILBetter (Better Track Fixed Item Lanes)'",
        script_name, 0)
    return
end

-- Load Config
timbert_FILBetter = reaper.GetResourcePath() ..
                        '/scripts/TImbert Scripts/FILBetter/timbert_FILBetter (Better Track Fixed Item Lanes).lua'
dofile(timbert_FILBetter)

-- USERSETTING Loaded from FILBetterCFG.json--
local showValidationErrorMsg = FILBetter.LoadConfig("showValidationErrorMsg")
---------------

function main()
    -- Validate track selection
    local track, error = timbert.ValidateLanesPreviewScriptsSetup()
    if track == nil then
        if showValidationErrorMsg == true then
            timbert.msg(error, script_name)
        end
        return
    end

    if timbert.ValidateItemsUnderEditCursorOnSelectedTracks() == false then
        return
    end

    local cursPos = reaper.GetCursorPosition()
    local startTime, endTime = reaper.GetSet_LoopTimeRange(false, false, startTime, endTime, false)
    local itemsToMove, itemsShifted = {}, {}
    local laneDestination, foundLane, foundLaneIndex
    timbert.SetTimeSelectionToAllItemsInVerticalStack(true)
    local items, lastLane = timbert.MakeItemArraySortByLane()
    local hasCompLane, compLanes = timbert.GetCompLanes(items, track)

    local laneIndex = timbert.GetActiveTrackLane(track)

    if laneIndex == nil then
        reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
        reaper.GetSet_LoopTimeRange(true, false, startTime, endTime, false)
        reaper.SetEditCurPos(cursPos, false, false)
        return
    end

    -- Test if lane has content
    for i = 1, #items do
        if items[i].laneIndex == laneIndex then
            foundLane = items[i].laneIndex
            foundLaneIndex = i
        end
    end
    if laneIndex > lastLane or laneIndex < items[1].laneIndex or foundLaneIndex == nil then
        reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
        reaper.GetSet_LoopTimeRange(true, false, startTime, endTime, false)
        reaper.SetEditCurPos(cursPos, false, false)
        return
    end

    dofile(timbert_SoloLanePriority) -- Solo last lane or first comp lane with content of selected track
    laneDestination = timbert.GetActiveTrackLane(track) 

    for i = 1, #items do
        if items[i].laneIndex == laneDestination then
            reaper.SetMediaItemInfo_Value(items[i].item, "I_FIXEDLANE", laneIndex)
        end
        if items[i].laneIndex == laneIndex then
            reaper.SetMediaItemInfo_Value(items[i].item, "I_FIXEDLANE", laneDestination)
        end
    end

    reaper.SetMediaTrackInfo_Value(track, "C_LANEPLAYS:" .. tostring(laneDestination), 1)

    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
    reaper.GetSet_LoopTimeRange(true, false, startTime, endTime, false)
    reaper.SetEditCurPos(cursPos, false, false)
    -- Set selection to swapped items?
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block.

main()

reaper.UpdateArrange()

reaper.Undo_EndBlock(script_name, -1) -- End of the undo block.

reaper.PreventUIRefresh(-1)
