-- @description Preview item under edit cursor in next lane of selected track
-- @author Thomas Imbert
-- @version 1.1
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about Preview item under edit cursor in next lane of selected track
-- @changelog 
--   # Added Comp Lane support
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

-- reaper.ClearConsole()
local function CycleLaneIndexFoward(laneIndex, lastLane, items, hasCompLane, compLanes, laneOffset) -- Guard against laneIndex outside possible laneIndex with content
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

local function SelectOnlyFirstItemPerLaneInSelection(items)
    if #items < 2 then
        return items
    end
    local indexesToRemove = {}
    for i = 2, #items do
        if items[i].laneIndex == items[i - 1].laneIndex and reaper.GetMediaItemInfo_Value(items[i].item, "D_POSITION") >
            reaper.GetMediaItemInfo_Value(items[i - 1].item, "D_POSITION") then
            table.insert(indexesToRemove, i)
        end
    end
    for i = #indexesToRemove, 1, -1 do
        table.remove(items, indexesToRemove[i])
    end
    return items
end

function main()
    local track = timbert.ValidateLanesPreviewScriptsSetup(script_name)
    if track == nil then
        return
    end

    local items, lastLane = timbert.MakeItemArraySortByLane()
    items = SelectOnlyFirstItemPerLaneInSelection(items)
    local hasCompLane, compLanes = timbert.GetCompLanes(items, track)

    local laneIndex = timbert.GetActiveTrackLane(track) or lastLane + 1
    laneIndex = CycleLaneIndexFoward(laneIndex, lastLane, items, hasCompLane, compLanes, items[1].laneIndex)
    reaper.SetMediaTrackInfo_Value(reaper.GetSelectedTrack(0, 0), "C_LANEPLAYS:" .. tostring(laneIndex), 1) -- solos last lane

    -- Find item in selected laneIndex
    local itemIndex
    for i = 1, #items do
        if items[i].laneIndex == laneIndex then
            itemIndex = i
            break
        end
    end

    for _, lane in pairs(compLanes) do
        if lane == laneIndex then
            local compItems = timbert.GetSelectedItemsInLaneInfo(laneIndex)
            reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
            local start_time, end_time = reaper.GetSet_ArrangeView2(0, false, 0, 0)
            timbert.PreviewMultipleItems(compItems, track, false)
            reaper.GetSet_ArrangeView2(0, true, 0, 0, start_time, end_time)
            timbert.swsCommand("_SWS_RESTTIME1")
            timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_1")
            return
        end
    end

    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
    reaper.SetMediaItemSelected(items[itemIndex].item, true)
    timbert.swsCommand("_SWS_PREVIEWTRACK") -- Xenakios/SWS: Preview selected media item through track
    timbert.swsCommand("_SWS_RESTTIME1")
    timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_1")
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

main() -- call main function 

reaper.UpdateArrange()

reaper.Undo_EndBlock("Preview item under edit cursor in next lane of selected track", -1) -- End of the undo block. Leave it at the bottom of your main function.

reaper.PreventUIRefresh(-1)
