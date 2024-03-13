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

    local itemsToMove, itemsShifted = {}, {}
    local laneDestination, foundLane, foundLaneIndex
    timbert.SetTimeSelectionToAllItemsInVerticalStack(true)
    local items, lastLane = timbert.MakeItemArraySortByLane()
    local hasCompLane, compLanes = timbert.GetCompLanes(items, track)

    local laneIndex = timbert.GetActiveTrackLane(track)

    if laneIndex == nil then
        reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
        -- Recall edit cursor and time selection set during timbert.ValidateItemUnderEditCursor
        timbert.swsCommand("_SWS_RESTTIME1")
        timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_1")
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
        -- Recall edit cursor and time selection set during timbert.ValidateItemUnderEditCursor
        timbert.swsCommand("_SWS_RESTTIME1")
        timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_1")
        return
    end

    if hasCompLane == true then
        laneDestination = compLanes[1]
    else
        laneDestination = lastLane
    end

    for i = 1, #items do
        if items[i].laneIndex == laneDestination then
            -- table.insert(itemsShifted, reaper.BR_GetMediaItemGUID(items[i].item))
            reaper.SetMediaItemInfo_Value(items[i].item, "I_FIXEDLANE", laneIndex)
        end
        if items[i].laneIndex == laneIndex then
            -- table.insert(itemsToMove, reaper.BR_GetMediaItemGUID(items[i].item))
            reaper.SetMediaItemInfo_Value(items[i].item, "I_FIXEDLANE", laneDestination)
        end
    end

    reaper.SetMediaTrackInfo_Value(track, "C_LANEPLAYS:" .. tostring(laneDestination), 1)

    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
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
