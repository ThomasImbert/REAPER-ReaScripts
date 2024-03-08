-- @description Lanes Preview content under edit cursor in last lane or first comp lane of selected track
-- @author Thomas Imbert
-- @version 1.0
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about 
--      # Part of the timbert Lanes suite of scripts
--
--      Preview content under edit cursor in last lane or first comp lane of selected track
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

-- Load lua 'timbert_Lanes Preview content under edit cursor in currently soloed lane of selected track' script
timbert_PreviewSoloedLane = reaper.GetResourcePath() ..
                                '/scripts/TImbert Scripts/Transport/timbert_Lanes Preview content under edit cursor in currently soloed lane of selected track.lua'
if not reaper.file_exists(timbert_PreviewSoloedLane) then
    reaper.ShowConsoleMsg(
        "This script requires 'Preview content under edit cursor in currently soloed lane of selected track'! Please install it here:\n\nExtensions > ReaPack > Browse Packages > 'timbert_Lanes Preview content under edit cursor in currently soloed lane of selected track'");
    return
end

local function CorrectLaneIndex(laneIndex, lastLane, items, hasCompLane, compLanes)
    if hasCompLane == true then
        laneIndex = compLanes[1] -- go to first complane
    else
        laneIndex = items[#items].laneIndex
    end
    return laneIndex
end

function main()
    -- Validate track selection
    local track, error = timbert.ValidateLanesPreviewScriptsSetup()
    if track == nil then
        timbert.msg(error, script_name)
        return
    end

    if not timbert.ValidateItemUnderEditCursor(true, 2) then
        return
    end

    local items, lastLane = timbert.MakeItemArraySortByLane()
    items = timbert.SelectOnlyFirstItemPerLaneInSelection(items)
    local hasCompLane, compLanes = timbert.GetCompLanes(items, track)

    local laneIndex = lastLane
    laneIndex = CorrectLaneIndex(laneIndex, lastLane, items, hasCompLane, compLanes)
    reaper.SetMediaTrackInfo_Value(reaper.GetSelectedTrack(0, 0), "C_LANEPLAYS:" .. tostring(laneIndex), 1)
    dofile(timbert_PreviewSoloedLane)

    -- Recall edit cursor and time selection set during timbert.ValidateItemUnderEditCursor
    timbert.swsCommand("_SWS_RESTTIME2")
    timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_2")
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block.

main()

reaper.UpdateArrange()

reaper.Undo_EndBlock(script_name, -1) -- End of the undo block.

reaper.PreventUIRefresh(-1)
