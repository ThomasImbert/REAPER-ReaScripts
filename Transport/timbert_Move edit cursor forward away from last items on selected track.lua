-- @description Move edit cursor forward away from last items on selected track
-- @author Thomas Imbert
-- @version 1.0
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about Move edit cursor forward away from last items on selected track by timeGap seconds (timeGap = 2 by default)
-- @changelog 
--   # intial release
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
local timeGap = 2
-------------------

local function GetItemPosition(item)
    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION");
    local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH");
    return pos, len
end

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

    local item = reaper.GetTrackMediaItem(track, itemCount - 1)
    local pos, len = GetItemPosition(item)
    reaper.SetEditCurPos(pos + len + 2, true, false)
    timbert.swsCommand("_XENAKIOS_SELITEMSUNDEDCURSELTX") -- Xenakios/SWS: Select items under edit cursor on selected tracks

    while reaper.CountSelectedMediaItems(0) > 0 do
        item = reaper.GetSelectedMediaItem(0, 0)
        pos, len = GetItemPosition(item)
        reaper.SetEditCurPos(pos + len + timeGap, true, false);
        reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items	
        timbert.swsCommand("_XENAKIOS_SELITEMSUNDEDCURSELTX") -- Xenakios/SWS: Select items under edit cursor on selected tracks
    end

    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items	
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. 

main()

reaper.UpdateArrange()

reaper.Undo_EndBlock(script_name, -1) -- End of the undo block. 

reaper.PreventUIRefresh(-1)
