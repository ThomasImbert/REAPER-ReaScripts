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
if not timbert or timbert.version() < 1.924 then
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
local showValidationErrorMsg = FILBetter.LoadConfig("showValidationErrorMsg")
local moveEditCurToStartOfContent = FILBetter.LoadConfig("moveEditCurToStartOfContent")
---------------

local function CorrectLaneIndex(laneIndex, lastLane, items, hasCompLane, compLanes)
    -- Test if currently selected lane is included in items lane range
    if laneIndex > lastLane then
        if hasCompLane == true then
            laneIndex = compLanes[1] -- go to first complane
        else
            laneIndex = items[#items].laneIndex
        end
        return laneIndex
    end

    if laneIndex < items[1].laneIndex then
        laneIndex = items[1].laneIndex
        return laneIndex
    end

    -- Test if lane has content
    local foundLane, foundLaneIndex
    for i = 1, #items do
        if items[i].laneIndex == laneIndex then
            foundLane = items[i].laneIndex
            foundLaneIndex = i
        end
    end
    if foundLaneIndex ~= nil then
        laneIndex = items[foundLaneIndex].laneIndex
        return laneIndex
    end

    -- If Lane doesn't have content, go to next lane with content in item lanes range
    local closestNextLane, closestNextLaneIndex
    for i = 1, #items do
        if items[i].laneIndex - laneIndex > 0 then
            closestNextLane = items[i].laneIndex
            closestNextLaneIndex = i
            break
        end
    end
    laneIndex = items[closestNextLaneIndex].laneIndex
    return laneIndex
end

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
    timbert.SetTimeSelectionToAllItemsInVerticalStack()
    local items, lastLane = timbert.MakeItemArraySortByLane()
    local hasCompLane, compLanes = timbert.GetCompLanes(items, track)
    local laneIndex = timbert.GetActiveTrackLane(track) or lastLane + 1

    laneIndex = CorrectLaneIndex(laneIndex, lastLane, items, hasCompLane, compLanes)
    reaper.SetMediaTrackInfo_Value(track, "C_LANEPLAYS:" .. tostring(laneIndex), 1)
    timbert.PreviewLaneContent(track, laneIndex, false, true)

    reaper.GetSet_LoopTimeRange(true, false, startTime, endTime, false)
    if moveEditCurToStartOfContent == true then
        reaper.SetEditCurPos(timbert.GetSelectedItemsInLaneInfo(laneIndex)[1].itemPosition, false, false)
    else
        reaper.SetEditCurPos(cursPos, false, false)
    end
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block.

main()

reaper.UpdateArrange()

reaper.Undo_EndBlock(script_name, -1) -- End of the undo block.

reaper.PreventUIRefresh(-1)
