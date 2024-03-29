-- @noindex
-- Get this script's name
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local reaper = reaper

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath() .. '/scripts/TImbert Scripts/Development/timbert_Lua Utilities.lua'
if not reaper.file_exists(timbert_LuaUtils) then
    reaper.MB(
        "This script requires TImbert Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'TImbert Lua Utilities'",
        script_name, 0)
    return
end
dofile(timbert_LuaUtils)
if not timbert or timbert.version() < 1.926 then
    reaper.MB(
        "This script requires a newer version of TImbert Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages",
        script_name, 0)
    return
end

-- Load Config
timbert_FILBetter = reaper.GetResourcePath() ..
                        '/scripts/TImbert Scripts/FILBetter/timbert_FILBetter (Better Track Fixed Item Lanes).lua'
dofile(timbert_FILBetter)


-- Load 'Solo priority lane with content under edit cursor in selected track' script
timbert_SoloLanePriority = reaper.GetResourcePath() ..
                               '/scripts/TImbert Scripts/FILBetter/timbert_FILBetter Solo priority lane with content under edit cursor in selected track.lua'
if not reaper.file_exists(timbert_SoloLanePriority) then
    reaper.MB(
        "This script requires 'Solo priority lane with content under edit cursor in selected track'! Please install it here:\n\nExtensions > ReaPack > Browse Packages > 'FILBetter (Better Track Fixed Item Lanes)'",
        script_name, 0)
    return
end

-- USERSETTING Loaded from FILBetterCFG.json--
local goToPreviousSnapTofirstContent = FILBetter.LoadConfig("goToPreviousSnapTofirstContent")
local goToContentTimeSelectionMode = FILBetter.LoadConfig("goToContentTimeSelectionMode")
---------------

local function GetTimeSelectionMode(goToContentTimeSelectionMode, startTime, endTime)
    if goToContentTimeSelectionMode == "recall" then
        reaper.GetSet_LoopTimeRange(true, false, startTime, endTime, false)
    elseif goToContentTimeSelectionMode == "clear" then
        reaper.Main_OnCommand(40635, 0) -- Time selection: Remove (unselect) time selection
    end
    -- implicit elseif goToContentTimeSelectionMode == "content" or none of the above, do nothing (keep content selected)
end

function main()
    -- Validate track selection
    local track, error = timbert.ValidateLanesPreviewScriptsSetup()
    if track == nil then
        reaper.Main_OnCommand(40416, 0) -- Item navigation: Select and move to previous item
        -- timbert.msg(error, script_name)
        return
    end

    if reaper.CountTrackMediaItems(track) == 0 then
        return
    end
    
    local startTime, endTime = reaper.GetSet_LoopTimeRange(false, false, startTime, endTime, false)

    if timbert.ValidateItemsUnderEditCursorOnSelectedTracks() == true then
        timbert.SetTimeSelectionToAllItemsInVerticalStack()
        reaper.Main_OnCommand(40630, 0) -- Go to start of time selection    
        reaper.SetMediaTrackInfo_Value(track, "C_ALLLANESPLAY", 1) -- Activate all lanes
        reaper.Main_OnCommand(40416, 0) -- Item navigation: Select and move to previous item
        timbert.SetTimeSelectionToAllItemsInVerticalStack()
        dofile(timbert_SoloLanePriority) -- Solo priority lane
        GetTimeSelectionMode(goToContentTimeSelectionMode, startTime, endTime)
        return
    else
        reaper.SetMediaTrackInfo_Value(track, "C_ALLLANESPLAY", 1) -- Activate all lanes
        reaper.Main_OnCommand(40416, 0) -- Item navigation: Select and move to previous item
        reaper.Main_OnCommand(40635, 0) -- Time selection: Remove (unselect) time selection
    end

    if timbert.ValidateItemsUnderEditCursorOnSelectedTracks() == false then
        -- When triggered before first content, don't go forward to first content if called by another script or set in config
        if select(2, reaper.get_action_context()) ~= debug.getinfo(1, 'S').source:sub(2) or goToPreviousSnapTofirstContent == false then
            reaper.SetMediaTrackInfo_Value(track, "C_ALLLANESPLAY", 0) -- DeActivate all lanes
            GetTimeSelectionMode(goToContentTimeSelectionMode, startTime, endTime)
            return
        end
        reaper.Main_OnCommand(40417, 0) -- Item navigation: Select and move to next item
        timbert.SetTimeSelectionToAllItemsInVerticalStack()
        dofile(timbert_SoloLanePriority) --  Solo priority lane
        GetTimeSelectionMode(goToContentTimeSelectionMode, startTime, endTime)
        return
    end
    timbert.SetTimeSelectionToAllItemsInVerticalStack()
    dofile(timbert_SoloLanePriority) --  Solo priority lane
    GetTimeSelectionMode(goToContentTimeSelectionMode, startTime, endTime)
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. 

main()

reaper.UpdateArrange()

reaper.Undo_EndBlock(script_name, -1) -- End of the undo block. 

reaper.PreventUIRefresh(-1)
