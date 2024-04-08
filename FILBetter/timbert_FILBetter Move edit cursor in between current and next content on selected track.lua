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

-- Load lua 'Go to previous item stack in currently selected track fixed lanes' script
timbert_GoToPrevious = reaper.GetResourcePath() ..
                           '/scripts/TImbert Scripts/FILBetter/timbert_FILBetter Go to previous content in fixed lanes of currently selected track.lua'
if not reaper.file_exists(timbert_GoToPrevious) then
    reaper.ShowConsoleMsg(
        "This script requires 'Go to previous content in fixed lanes of currently selected track'! Please install it here:\n\nExtensions > ReaPack > Browse Packages > 'FILBetter (Better Track Fixed Item Lanes)'");
    return
end

-- Load lua 'Go to previous item stack in currently selected track fixed lanes' script
timbert_GoToNext = reaper.GetResourcePath() ..
                       '/scripts/TImbert Scripts/FILBetter/timbert_FILBetter Go to next content in fixed lanes of currently selected track.lua'
if not reaper.file_exists(timbert_GoToNext) then
    reaper.ShowConsoleMsg(
        "This script requires 'Go to next content in fixed lanes of currently selected track'! Please install it here:\n\nExtensions > ReaPack > Browse Packages > 'FILBetter (Better Track Fixed Item Lanes)'");
    return
end

-- Load Config
timbert_FILBetter = reaper.GetResourcePath() ..
                        '/scripts/TImbert Scripts/FILBetter/timbert_FILBetter (Better Track Fixed Item Lanes).lua'
dofile(timbert_FILBetter)

-- USERSETTING Loaded from FILBetterCFG.json--
local showValidationErrorMsg = FILBetter.LoadConfig("showValidationErrorMsg")
---------------

local function getNextContentPos()
    local cursorPos = reaper.GetCursorPosition()
    dofile(timbert_GoToNext)
    if reaper.GetCursorPosition() == cursorPos then
        return
    end
    local nextContentPos = reaper.GetCursorPosition()
    return nextContentPos
end

function main()
    -- Validate track selection
    local track = reaper.GetSelectedTrack(0, 0)
    if track == nil then
        if showValidationErrorMsg == true then
            timbert.msg("No track selected", script_name)
        end
        return
    end

    if reaper.CountTrackMediaItems(track) == 0 then
        return
    end

    if timbert.ValidateItemsUnderEditCursorOnSelectedTracks() == false then
        return
    end

    local _, isRec = reaper.GetProjExtState(0, "FILBetter", "Rec_Series")
    if isRec == "true" then
        reaper.SetProjExtState(0, "FILBetter", "MoveEditCurBetween", "true")
        reaper.Main_OnCommand(1016, 0) -- Transport: Stop
        return
    end

    local startTime, endTime, endCurrContent, nextContentPos, _
    
    startTime, endTime = reaper.GetSet_LoopTimeRange(false, false, _, _, false)
    timbert.SetTimeSelectionToAllItemsInVerticalStack()
    _, endCurrContent = reaper.GetSet_LoopTimeRange(false, false, _, _, false)
    nextContentPos = getNextContentPos()
    if nextContentPos ~= nil then
        reaper.SetEditCurPos((endCurrContent + nextContentPos) / 2, false, false)
    end
    reaper.GetSet_LoopTimeRange(true, false, startTime, endTime, false)
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. 

main()

reaper.UpdateArrange()

reaper.Undo_EndBlock(script_name, -1) -- End of the undo block.

reaper.PreventUIRefresh(-1)
