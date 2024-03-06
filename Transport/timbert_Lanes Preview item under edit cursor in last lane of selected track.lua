-- @description Preview item under edit cursor in last lane of selected track
-- @author Thomas Imbert
-- @version 1.1
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about Preview item under edit cursor in last lane with content of selected track
-- @changelog 
--   # Updated architecture to be similar to other Lanes Preview scripts 
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

function main()
    local track = timbert.ValidateLanesPreviewScriptsSetup(script_name)
    if track == nil then
        return
    end

    local items, lastLane = timbert.MakeItemArraySortByLane()
    items = timbert.SelectOnlyFirstItemPerLaneInSelection(items)
    local hasCompLane, compLanes = timbert.GetCompLanes(items, track)

    local laneIndex = lastLane
    reaper.SetMediaTrackInfo_Value(reaper.GetSelectedTrack(0, 0), "C_LANEPLAYS:" .. tostring(laneIndex), 1) -- solos last lane
    timbert.PreviewLaneContent(track, laneIndex)

    -- Recall edit cursor and time selection set during timbert.ValidateLanesPreviewScriptsSetup
    timbert.swsCommand("_SWS_RESTTIME1")
    timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_1")
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

main() -- call main function 

reaper.UpdateArrange()

reaper.Undo_EndBlock(script_name, -1) -- End of the undo block. Leave it at the bottom of your main function.

reaper.PreventUIRefresh(-1)
