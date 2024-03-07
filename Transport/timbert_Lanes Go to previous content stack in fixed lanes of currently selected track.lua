-- @description Lanes Go to previous content in fixed lanes of currently selected track
-- @author Thomas Imbert
-- @version 1.0
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about 
--      # Part of the timbert Lanes suite of scripts
--
--      Go to previous content in fixed lanes of currently selected track
--
--      This script requires 'Solo last lane or first comp lane with content of selected track' 
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

-- Load 'Solo last lane or first comp lane with content of selected track' script
timbert_SoloLanePriority = reaper.GetResourcePath() ..
                               '/scripts/TImbert Scripts/Transport/timbert_Lanes Solo last lane or first comp lane with content of selected track.lua'
if not reaper.file_exists(timbert_SoloLanePriority) then
    reaper.ShowConsoleMsg(
        "This script requires 'Solo last lane or first comp lane with content of selected track'! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'Lanes Solo last lane or first comp lane with content of selected track'");
    return
end

local function GetItemStackStart(item0, item1, timeSelectStart)
    local item0End = reaper.GetMediaItemInfo_Value(item0, "D_POSITION") +
                         reaper.GetMediaItemInfo_Value(item0, "D_LENGTH")
    while item0End > timeSelectStart do
        item1 = item0
        timeSelectStart = reaper.GetMediaItemInfo_Value(item1, "D_POSITION")
        reaper.Main_OnCommand(40416, 0) -- Item navigation: Select and move to previous item
        item0 = reaper.GetSelectedMediaItem(0, 0)
        if item0 ~= item1 then
            item0End = reaper.GetMediaItemInfo_Value(item0, "D_POSITION") +
                           reaper.GetMediaItemInfo_Value(item0, "D_LENGTH")
        else
            break
        end
    end
    return timeSelectStart
end

function main()
    -- Validate track selection without selecting item or moving edit cursor
    local track = timbert.ValidateLanesPreviewScriptsSetup(script_name, false)
    if track == nil then
        return
    end

    -- Move to previous item across all lanes of selected track
    local item1, item2, item1Lane, item0, item0Start, item0End
    reaper.SetMediaTrackInfo_Value(track, "C_ALLLANESPLAY", 1) -- Activate all lanes
    reaper.Main_OnCommand(40416, 0) -- Item navigation: Select and move to previous item

    -- Return and go to first item on track if cursor is before that position when triggering this script
    timbert.swsCommand("_XENAKIOS_SELITEMSUNDEDCURSELTX") -- Xenakios/SWS: Select items under edit cursor on selected tracks
    if reaper.CountSelectedMediaItems(0) == 0 then
        reaper.Main_OnCommand(40417, 0) -- Item navigation: Select and move to next item
        item1 = reaper.GetSelectedMediaItem(0, 0)
        item1Lane = reaper.GetMediaItemInfo_Value(item1, "I_FIXEDLANE")
        reaper.SetMediaTrackInfo_Value(track, "C_LANEPLAYS:" .. tostring(item1Lane), 1)
        reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of all items)
        dofile(timbert_SoloLanePriority) -- Solo last lane or first comp lane with content of selected track
        return
    end
    item1 = reaper.GetSelectedMediaItem(0, 0)

    -- Find the first item position in the item stack ending with selected item1
    item1Lane = reaper.GetMediaItemInfo_Value(item1, "I_FIXEDLANE")
    reaper.SetMediaTrackInfo_Value(track, "C_LANEPLAYS:" .. tostring(item1Lane), 1)
    reaper.Main_OnCommand(40290, 0) -- Time selection: Set time selection to items
    local timeSelectStart, timeSelectEnd = reaper.GetSet_LoopTimeRange(false, false, _, _, false)
    reaper.Main_OnCommand(40416, 0) -- Item navigation: Select and move to previous item
    item0 = reaper.GetSelectedMediaItem(0, 0)
    timeSelectStart = GetItemStackStart(item0, item1, timeSelectStart)
    reaper.GetSet_LoopTimeRange(true, false, timeSelectStart, timeSelectEnd, false)

    -- Move Edit cursor to found position
    -- Make sure the Edit cursor is at the earliest start position in the stack 
    -- This avoids getting 'stuck' on the current stack when retriggering this script  
    reaper.Main_OnCommand(40630, 0) -- Go to start of time selection
    timbert.swsCommand("_XENAKIOS_SELITEMSUNDEDCURSELTX") -- Xenakios/SWS: Select items under edit cursor on selected tracks
    reaper.Main_OnCommand(40290, 0) -- Time selection: Set time selection to items
    reaper.Main_OnCommand(40630, 0) -- Go to start of time selection

    dofile(timbert_SoloLanePriority) -- Solo last lane or first comp lane with content of selected track
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

main() -- call main function 

reaper.UpdateArrange()

reaper.Undo_EndBlock(script_name, -1) -- End of the undo block. Leave it at the bottom of your main function.

reaper.PreventUIRefresh(-1)
