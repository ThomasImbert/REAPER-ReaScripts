-- @description Move edit cursor forward away from last items on selected track
-- @author Thomas Imbert
-- @version 1.1
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about Move edit cursor forward away from last items on selected track by timeGap seconds (timeGap = 2 by default)
-- @changelog 
--   # Now uses SetTimeSelectionToAllItemsInVerticalStack
-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1, ({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath() .. '/scripts/TImbert Scripts/Development/timbert_Lua Utilities.lua'
if reaper.file_exists(timbert_LuaUtils) then
    dofile(timbert_LuaUtils);
    if not timbert or timbert.version() < 1.9 then
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

-- USER SETTINGS --
local timeGap = 3
-------------------

function main()
    -- Validate track selection
    if reaper.CountSelectedTracks(0) == 0 then
        timbert.msg("Please select a track first", script_name)
		return
    end

    if reaper.CountSelectedTracks(0) > 1 then
        timbert.msg("Please only select one track", script_name)
        return 
    end
    local track = reaper.GetSelectedTrack(0, 0)

    local itemCount = reaper.CountTrackMediaItems(track)
    if itemCount == 0 then
        return
    end

    local startTime, endTime = reaper.GetSet_LoopTimeRange(false, false, startTime, endTime, false)
    local item = reaper.GetTrackMediaItem(track, itemCount - 1)
    reaper.SetEditCurPos(reaper.GetMediaItemInfo_Value(item, "D_POSITION"), true, false)
    timbert.SetTimeSelectionToAllItemsInVerticalStack()
    reaper.Main_OnCommand(40631, 0) -- Go to end of time selection
    reaper.MoveEditCursor( timeGap, false )
    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items	
    reaper.GetSet_LoopTimeRange(true, false, startTime, endTime, false)
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. 

main()

reaper.UpdateArrange()

reaper.Undo_EndBlock(script_name, -1) -- End of the undo block. 

reaper.PreventUIRefresh(-1)
