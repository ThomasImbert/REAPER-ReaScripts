-- @noindex
-- This script requires 'Solo last lane or first comp lane with content of selected track' provided by the Lanes suite of scripts
-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath() .. '/scripts/TImbert Scripts/Development/timbert_Lua Utilities.lua'
if reaper.file_exists(timbert_LuaUtils) then
    dofile(timbert_LuaUtils)
else
    reaper.ShowConsoleMsg(
        "This script requires TImbert Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'TImbert Lua Utilities'");
    return
end

-- Load metapackage "timbert_Lanes" and use it to check timbert_Lua Utilities version
timbert_Lanes = reaper.GetResourcePath() .. '/scripts/TImbert Scripts/Transport/Lanes/timbert_Lanes.lua'
if not reaper.file_exists(timbert_Lanes) then
    reaper.ShowConsoleMsg(
        "This script requires 'timbert_Lanes'! Please install it here:\n\nExtensions > ReaPack > Browse Packages > 'timbert_Lanes'")
    return
end
dofile(timbert_Lanes)
local validateUtilities = lanes.ValidateLuaUtils()
if validateUtilities ~= nil then
    timbert.msg(validateUtilities, script_name)
    return
end

-- Load 'Solo last lane or first comp lane with content of selected track' script
timbert_SoloLanePriority = reaper.GetResourcePath() ..
                               '/scripts/TImbert Scripts/Transport/Lanes/timbert_Lanes Solo last lane or first comp lane with content of selected track.lua'
if not reaper.file_exists(timbert_SoloLanePriority) then
    reaper.ShowConsoleMsg(
        "This script requires 'Solo last lane or first comp lane with content of selected track'! Please install it here:\n\nExtensions > ReaPack > Browse Packages > 'timbert_Lanes'");
    return
end

function main()
    -- Validate track selection
    local track, error = timbert.ValidateLanesPreviewScriptsSetup()
    if track == nil then
        timbert.msg(error, script_name)
        return
    end

    if reaper.CountTrackMediaItems(track) == 0 then
        return
    end

    if timbert.ValidateItemUnderEditCursor(true) then
        timbert.SetTimeSelectionToAllItemsInVerticalStack()
        reaper.Main_OnCommand(40631, 0) -- Go to end of time selection      
        reaper.SetMediaTrackInfo_Value(track, "C_ALLLANESPLAY", 1) -- Activate all lanes
        reaper.Main_OnCommand(40417, 0) -- Item navigation: Select and move to next item
        timbert.SetTimeSelectionToAllItemsInVerticalStack()
        dofile(timbert_SoloLanePriority) -- Solo last lane or first comp lane with content of selected track
        return
    else
        reaper.SetMediaTrackInfo_Value(track, "C_ALLLANESPLAY", 1) -- Activate all lanes
        reaper.Main_OnCommand(40417, 0) -- Item navigation: Select and move to next item
        reaper.Main_OnCommand(40635, 0) -- Time selection: Remove (unselect) time selection
    end

    if not timbert.ValidateItemUnderEditCursor(true) then
        reaper.SetMediaTrackInfo_Value(track, "C_ALLLANESPLAY", 0) -- DeActivate all lanes
        -- reaper.Main_OnCommand(40416, 0) -- Item navigation: Select and move to previous item
        -- timbert.SetTimeSelectionToAllItemsInVerticalStack()
        -- dofile(timbert_SoloLanePriority) -- Solo last lane or first comp lane with content of selected track
        return
    end
    timbert.SetTimeSelectionToAllItemsInVerticalStack()
    dofile(timbert_SoloLanePriority) -- Solo last lane or first comp lane with content of selected track
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block.

main()

reaper.UpdateArrange()

reaper.Undo_EndBlock(script_name, -1) -- End of the undo block.

reaper.PreventUIRefresh(-1)
