-- @description Lanes Preview content under edit cursor in currently soloed lane of selected track
-- @author Thomas Imbert
-- @version 1.0
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about 
--      # Part of the timbert Lanes suite of scripts
--
--      Preview item under edit cursor in currently soloed lane of selected track
-- @changelog 
--   # Initial release
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
    local track = timbert.ValidateLanesPreviewScriptsSetup(script_name)
    if track == nil then
        return
    end

    local items, lastLane = timbert.MakeItemArraySortByLane()
    local hasCompLane, compLanes = timbert.GetCompLanes(items, track)

    local laneIndex = timbert.GetActiveTrackLane(track) or lastLane + 1
    laneIndex = CorrectLaneIndex(laneIndex, lastLane, items, hasCompLane, compLanes)
    reaper.SetMediaTrackInfo_Value(track, "C_LANEPLAYS:" .. tostring(laneIndex), 1)
    timbert.PreviewLaneContent(track, laneIndex)

    -- Recall edit cursor and time selection set during timbert.ValidateLanesPreviewScriptsSetup
    timbert.swsCommand("_SWS_RESTTIME1")
    timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_1")
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

main()

reaper.UpdateArrange()

reaper.Undo_EndBlock(script_name, -1) -- End of the undo block. Leave it at the bottom of your main function.

reaper.PreventUIRefresh(-1)