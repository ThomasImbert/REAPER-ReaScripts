-- @description Lanes Solo last lane or first comp lane with content of selected track
-- @author Thomas Imbert
-- @version 1.0
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about 
--      # Part of the timbert Lanes suite of scripts
--
--      Preview item under edit cursor in last lane or first comp lane of selected track
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
    if hasCompLane == true then
        laneIndex = compLanes[1] -- go to first complane
    else
        laneIndex = items[#items].laneIndex
    end
    return laneIndex
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
    laneIndex = CorrectLaneIndex(laneIndex, lastLane, items, hasCompLane, compLanes)
    reaper.SetMediaTrackInfo_Value(reaper.GetSelectedTrack(0, 0), "C_LANEPLAYS:" .. tostring(laneIndex), 1)
    
    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of all items)
    reaper.Main_OnCommand(40635, 0) -- Time selection: Remove (unselect) time selection
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

main() -- call main function 

reaper.UpdateArrange()

reaper.Undo_EndBlock(script_name, -1) -- End of the undo block. Leave it at the bottom of your main function.

reaper.PreventUIRefresh(-1)