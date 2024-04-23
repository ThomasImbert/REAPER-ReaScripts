-- @noindex
-- Get this script's name
local script_name = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.lua$")
local reaper = reaper

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath() .. '/Scripts/TImbert Scripts/Development/timbert_Lua Utilities.lua'
if not reaper.file_exists(timbert_LuaUtils) then
    reaper.MB(
        "This script requires TImbert Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'TImbert Lua Utilities'",
        script_name, 0)
    return
end
dofile(timbert_LuaUtils)
if not timbert or timbert.version() < 1.927 then
    reaper.MB(
        "This script requires a newer version of TImbert Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages",
        script_name, 0)
    return
end

-- Load Config
timbert_FILBetter = reaper.GetResourcePath() ..
    '/Scripts/TImbert Scripts/FILBetter/timbert_FILBetter (Better Track Fixed Item Lanes).lua'
dofile(timbert_FILBetter)

-- Load 'Solo priority lane with content under edit cursor in selected track' script
timbert_SoloLanePriority = reaper.GetResourcePath() ..
    '/Scripts/TImbert Scripts/FILBetter/timbert_FILBetter Solo priority lane with content under edit cursor in selected track.lua'
if not reaper.file_exists(timbert_SoloLanePriority) then
    reaper.MB(
        "This script requires 'Solo priority lane with content under edit cursor in selected track'! Please install it here:\n\nExtensions > ReaPack > Browse Packages > 'FILBetter (Better Track Fixed Item Lanes)'",
        script_name, 0)
    return
end

-- USERSETTING Loaded from FILBetterCFG.json--
local goToNextSnapToLastContent = FILBetter.LoadConfig("goToNextSnapToLastContent")
local goToContentTimeSelectionMode = FILBetter.LoadConfig("goToContentTimeSelectionMode")
local retVasco, vascoReady = reaper.GetProjExtState(0, "VASCO", "vascoReady")
if retVasco == 1 and vascoReady == "true" then vascoReady = true else vascoReady = false end
---------------
local function GetTimeSelectionMode(goToContentTimeSelectionMode, startTime, endTime)
    if goToContentTimeSelectionMode == "recall" then
        reaper.GetSet_LoopTimeRange(true, false, startTime, endTime, false)
    elseif goToContentTimeSelectionMode == "clear" then
        reaper.Main_OnCommand(40635, 0) -- Time selection: Remove (unselect) time selection
    end
    -- implicit elseif goToContentTimeSelectionMode == "content" or none of the above, do nothing (keep content selected)
end

local vascoRegion = {}
if vascoReady == true then
    vascoRegion = timbert.GetRegionsAtCursor()
end
local function GetCurrentOrPreviousVascoRegion()
    local pos, rgnend
    if not vascoRegion.current then
        pos, rgnend = vascoRegion.previous.pos, vascoRegion.previous.rgnend
    else
        pos, rgnend = vascoRegion.current.pos, vascoRegion.current.rgnend
    end
    return pos, rgnend
end

local function GoToNextVascoRegion(track, startTime, endTime)
    reaper.SetMediaTrackInfo_Value(track, "C_ALLLANESPLAY", 0) -- DeActivate all lanes
    reaper.TrackList_AdjustWindows(true)
    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
    reaper.SetEditCurPos(vascoRegion.next.pos, true, false)
    reaper.GetSet_LoopTimeRange(true, false, vascoRegion.next.pos, vascoRegion.next.rgnend, false)
    GetTimeSelectionMode(goToContentTimeSelectionMode, startTime, endTime)
end

function main()
    local track = reaper.GetSelectedTrack(0, 0)
    if not track then return end
    if reaper.CountTrackMediaItems(track) == 0 then
        if not vascoReady or (not vascoRegion.next and goToNextSnapToLastContent == false) then
            return
        elseif not vascoRegion.next and goToNextSnapToLastContent == true and (vascoRegion.current or vascoRegion.previous) then
            local pos, rgnend = GetCurrentOrPreviousVascoRegion()
            reaper.SetEditCurPos(pos, true, false)
            reaper.GetSet_LoopTimeRange(true, false, pos, rgnend, false)
            return
        else
            reaper.SetEditCurPos(vascoRegion.next.pos, true, false)
            reaper.GetSet_LoopTimeRange(true, false, vascoRegion.next.pos, vascoRegion.next.rgnend, false)
            return
        end
    end

    -- Validate track selection
    local track, error = timbert.ValidateLanesPreviewScriptsSetup()
    if track == nil then
        reaper.Main_OnCommand(40417, 0) -- Item navigation: Select and move to next item
        return
    end
    local startTime, endTime = reaper.GetSet_LoopTimeRange(false, false, startTime, endTime, false)

    if timbert.ValidateItemsUnderEditCursorOnSelectedTracks() == true then
        timbert.SetTimeSelectionToAllItemsInVerticalStack()
        local startContent, _ = reaper.GetSet_LoopTimeRange(false, false, _, _, false)
        reaper.Main_OnCommand(40631, 0)                            -- Go to end of time selection
        reaper.SetMediaTrackInfo_Value(track, "C_ALLLANESPLAY", 1) -- Activate all lanes
        reaper.Main_OnCommand(40417, 0)                            -- Item navigation: Select and move to next item
        timbert.SetTimeSelectionToAllItemsInVerticalStack()
        if not vascoRegion.next then
            dofile(timbert_SoloLanePriority) -- Solo priority lane
            GetTimeSelectionMode(goToContentTimeSelectionMode, startTime, endTime)
            return
        end

        if vascoRegion.next and reaper.GetCursorPosition() == startContent or reaper.GetCursorPosition() > vascoRegion.next.pos then
            GoToNextVascoRegion(track, startTime, endTime)
            return
        end

    else
        reaper.SetMediaTrackInfo_Value(track, "C_ALLLANESPLAY", 1) -- Activate all lanes
        reaper.Main_OnCommand(40417, 0)                            -- Item navigation: Select and move to next item
        reaper.Main_OnCommand(40635, 0)                            -- Time selection: Remove (unselect) time selection
        local cursorPos = reaper.GetCursorPosition()
        if vascoRegion.next and vascoRegion.next.pos < cursorPos then
            GoToNextVascoRegion(track, startTime, endTime)
            return
        end
    end

    if timbert.ValidateItemsUnderEditCursorOnSelectedTracks() == false then
        if vascoRegion.next then
            GoToNextVascoRegion(track, startTime, endTime)
            return
        end
        -- When triggered after last content, don't go back to last content if called by another script or set in config
        if select(2, reaper.get_action_context()) ~= debug.getinfo(1, 'S').source:sub(2) or goToNextSnapToLastContent ==
            false then
            reaper.SetMediaTrackInfo_Value(track, "C_ALLLANESPLAY", 0) -- DeActivate all lanes
            reaper.TrackList_AdjustWindows(true)
            GetTimeSelectionMode(goToContentTimeSelectionMode, startTime, endTime)
            return
        end
        if vascoRegion.current or vascoRegion.previous then
            local pos, rgnend = GetCurrentOrPreviousVascoRegion()
            reaper.SetEditCurPos(pos, true, false)
            reaper.GetSet_LoopTimeRange(true, false, pos, rgnend, false)
            return
        end
        reaper.Main_OnCommand(40416, 0)  -- Item navigation: Select and move to previous item
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
