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
if not timbert or timbert.version() < 1.922 then
    reaper.MB(
        "This script requires a newer version of TImbert Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages",
        script_name, 0)
    return
end

local function CycleLaneIndexFoward(laneIndex, lastLane, items, hasCompLane, compLanes) -- Guard against laneIndex outside possible laneIndex with content
    if laneIndex > lastLane then
        if hasCompLane == true then
            laneIndex = compLanes[1] -- go to first complane
        else
            laneIndex = items[#items].laneIndex
        end
        return laneIndex
    end

    if laneIndex < items[1].laneIndex or laneIndex == items[#items].laneIndex then
        laneIndex = items[1].laneIndex
        return laneIndex
    end

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
        timbert.msg(error, script_name)
        return
    end

    if not timbert.ValidateItemUnderEditCursor(true) then
        return
    end

    local items, lastLane = timbert.MakeItemArraySortByLane()
    items = timbert.SelectOnlyFirstItemPerLaneInSelection(items)
    local hasCompLane, compLanes = timbert.GetCompLanes(items, track)

    local laneIndex = timbert.GetActiveTrackLane(track) or lastLane + 1
    laneIndex = CycleLaneIndexFoward(laneIndex, lastLane, items, hasCompLane, compLanes, items[1].laneIndex)
    reaper.SetMediaTrackInfo_Value(reaper.GetSelectedTrack(0, 0), "C_LANEPLAYS:" .. tostring(laneIndex), 1)
    timbert.PreviewLaneContent(track, laneIndex)

    -- Recall edit cursor and time selection set during timbert.ValidateItemUnderEditCursor
    timbert.swsCommand("_SWS_RESTTIME1")
    timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_1")
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block.

main()

reaper.UpdateArrange()

reaper.Undo_EndBlock(script_name, -1) -- End of the undo block.

reaper.PreventUIRefresh(-1)
