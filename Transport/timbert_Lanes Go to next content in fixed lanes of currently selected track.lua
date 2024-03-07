-- @description Lanes Go to next content in fixed lanes of currently selected track
-- @author Thomas Imbert
-- @version 1.0
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about 
--      # Part of the timbert Lanes suite of scripts
--
--      Go to next content in fixed lanes of currently selected track
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

local function IsCursorOnItem()
    timbert.swsCommand("_XENAKIOS_SELITEMSUNDEDCURSELTX") -- Xenakios/SWS: Select items under edit cursor on selected tracks
    if reaper.CountSelectedMediaItems(0) < 1 then
        return
    end
    local item = reaper.GetSelectedMediaItem(0, reaper.CountSelectedMediaItems(0) - 1)
    if reaper.GetCursorPosition() == reaper.GetMediaItemInfo_Value(item, "D_POSITION") then
        return
    end
    if reaper.GetCursorPosition() < reaper.GetMediaItemInfo_Value(item, "D_POSITION") +
        reaper.GetMediaItemInfo_Value(item, "D_LENGTH") then
        return true
    end
end

local function GetItemStackEnd(item0, item1, timeSelectEnd)
    local item0End = reaper.GetMediaItemInfo_Value(item0, "D_POSITION") +
                         reaper.GetMediaItemInfo_Value(item0, "D_LENGTH")
    while item0End < timeSelectEnd do
        item1 = item0
        timeSelectEnd = reaper.GetMediaItemInfo_Value(item1, "D_POSITION") +
                            reaper.GetMediaItemInfo_Value(item1, "D_LENGTH")
        reaper.Main_OnCommand(40417, 0) -- Item navigation: Select and move to next item
        item0 = reaper.GetSelectedMediaItem(0, 0)
        if item0 ~= item1 then
            item0End = reaper.GetMediaItemInfo_Value(item0, "D_POSITION") +
                           reaper.GetMediaItemInfo_Value(item0, "D_LENGTH")
        else
            break
        end
    end
    return timeSelectEnd
end

function main()
    reaper.ClearConsole()
    -- Validate track selection without selecting item or moving edit cursor
    local track = timbert.ValidateLanesPreviewScriptsSetup(script_name, false)
    if track == nil then
        return
    end

    timbert.swsCommand("_XENAKIOS_SELITEMSUNDEDCURSELTX") -- Xenakios/SWS: Select items under edit cursor on selected tracks
    reaper.Main_OnCommand(40290, 0) -- Time selection: Set time selection to items
    -- if isCursorOnItemAtStart == true then
    local itemCountCycle, itemCountCycle2
    repeat
        itemCountCycle = reaper.CountSelectedMediaItems(0)
        reaper.Main_OnCommand(40718, 0) -- Item: Select all items on selected tracks in current time selection
        reaper.Main_OnCommand(40290, 0) -- Time selection: Set time selection to items
        itemCountCycle2 = reaper.CountSelectedMediaItems(0)
    until itemCountCycle2 == itemCountCycle

    -- local isCursorOnItemAtStart = false or IsCursorOnItem()
    -- Move to next item across all lanes of selected track
    reaper.Main_OnCommand(40631, 0) -- Go to end of time selection      
    local item1, item2, item1Lane, item0, item0Start, item0End
    reaper.SetMediaTrackInfo_Value(track, "C_ALLLANESPLAY", 1) -- Activate all lanes
    reaper.Main_OnCommand(40417, 0) -- Item navigation: Select and move to next item

    -- Go to last item on track if cursor is after that position when triggering this script and return
    timbert.swsCommand("_XENAKIOS_SELITEMSUNDEDCURSELTX") -- Xenakios/SWS: Select items under edit cursor on selected tracks
    if reaper.CountSelectedMediaItems(0) == 0 then
        reaper.Main_OnCommand(40416, 0) -- Item navigation: Select and move to previous item
        item1 = reaper.GetSelectedMediaItem(0, 0)
        item1Lane = reaper.GetMediaItemInfo_Value(item1, "I_FIXEDLANE")
        reaper.SetMediaTrackInfo_Value(track, "C_LANEPLAYS:" .. tostring(item1Lane), 1)
        reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of all items)
        return
    end

    dofile(timbert_SoloLanePriority) -- Solo last lane or first comp lane with content of selected track
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

main() -- call main function 

reaper.UpdateArrange()

reaper.Undo_EndBlock(script_name, -1) -- End of the undo block. Leave it at the bottom of your main function.

reaper.PreventUIRefresh(-1)
