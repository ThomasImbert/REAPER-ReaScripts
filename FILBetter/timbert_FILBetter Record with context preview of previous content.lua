-- @noindex
-- Record and immediately preview the previous content on the same track, in last lane or first comp lane
-- ExpandOnStop auto expands recorded item end beyond the timeselection auto punch
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
if not timbert or timbert.version() < 1.922 then
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

local metronomePos, itemsPre, itemsPost, newItem

local function FindRecordedItem(itemsPre, itemsPost)
    local recordedItem, take, takeName
    local foundMatch = false
    -- input items list before recording
    -- table of names
    timbert.dbgVar(#itemsPre, "#itemsPre")
    timbert.dbgVar(#itemsPost, "#itemsPost")
    for i = 1, #itemsPost do
        take = reaper.GetActiveTake(itemsPost[i].item)
        _, takeName = reaper.GetSetMediaItemTakeInfo_String(reaper.GetActiveTake(itemsPost[i].item), "P_NAME",
            "takeName", false)
        foundMatch = false
        for j = 1, #itemsPre do
            if takeName ==
                reaper.GetSetMediaItemTakeInfo_String(reaper.GetActiveTake(itemsPost[j].item), "P_NAME", "takeName",
                    false) then
                foundMatch = true
            end
        end
        if foundMatch == false then
            recordedItem = reaper.GetMediaItemTake_Item(take)
            -- since we glue on preview multiple items, takename change..... HAVE TO FIX
        end
    end
    return recordedItem
end

local function ExpandOnStop()
    -- if reaper.GetPlayState() == 5 and reaper.GetPlayPosition() > metronomePos -  (60 /  reaper.Master_GetTempo() *3) then 
    --     reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_METROON"), 0) -- SWS: Metronome enable
    -- end 
    -- if reaper.GetPlayPosition() > metronomePos and reaper.GetPlayState() == 5 then
    --     reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_METROOFF"), 0) -- SWS: Metronome disable
    -- end
    if reaper.GetPlayState() ~= 0 then
        return reaper.defer(ExpandOnStop)
    end -- returns if still recording
    -- if reaper.CountSelectedMediaItems(0) ~= 1 then
    --     return reaper.defer(ExpandOnStop)
    -- end -- return if no item is selected
    if not itemsPre then
        return
    end
    reaper.Main_OnCommand(40252, 0) -- Record: Set record mode to normal
    -- reaper.DeleteTempoTimeSigMarker(0, 1)
    timbert.swsCommand("_BR_SAVE_CURSOR_POS_SLOT_4")
    timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_3")
    timbert.SetTimeSelectionToAllItemsInVerticalStack(true)
    itemsPost = timbert.MakeItemArraySortByLane()
    newItem = FindRecordedItem(itemsPre, itemsPost)
    reaper.SetMediaItemSelected(newItem, true)
    reaper.SetMediaItemInfo_Value(newItem, "B_MUTE", 1)
    timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_4")
    reaper.Main_OnCommand(40635, 0) -- Time selection: Remove (unselect) time selection
    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
    return
end

function main()
    metronomePos = reaper.GetCursorPosition()
    reaper.Main_OnCommand(1016, 0) -- Transport: Stop
    ExpandOnStop()

    -- Validate track selection
    local track, error = timbert.ValidateLanesPreviewScriptsSetup()
    if track == nil then
        timbert.msg(error, script_name)
        return
    end

    if reaper.GetMediaTrackInfo_Value(track, "I_RECARM") == 0 then
        timbert.msg("Selected track isn't record armed!", script_name)
        return
    end

    timbert.swsCommand("_BR_SAVE_CURSOR_POS_SLOT_3")
    dofile(timbert_GoToPrevious)
    if not timbert.ValidateItemUnderEditCursor(true, 2) then
        timbert.smartRecord()
        return
    end

    local laneIndex, previewLength
    laneIndex = timbert.GetActiveTrackLane(track)
    previewLength = timbert.PreviewLaneContent(track, laneIndex, true)
    timbert.SetTimeSelectionToAllItemsInVerticalStack(true)

    local cursorPos = reaper.GetCursorPosition()
    -- Trigger go to next but avoid coming back to last content if cursor at end of session
    reaper.SetExtState("FILBetterOptions", "GoToNext", "true", false)
    dofile(timbert_GoToNext)
    reaper.DeleteExtState("FILBetterOptions", "GoToNext", false)
    if reaper.GetCursorPosition() == cursorPos then -- no more content stack later in the session
        timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_3")
    else
        timbert.swsCommand("_BR_SAVE_CURSOR_POS_SLOT_3")
    end
    timbert.SetTimeSelectionToAllItemsInVerticalStack(true)
    itemsPre = timbert.MakeItemArraySortByLane()
    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
    reaper.GetSet_LoopTimeRange(true, true, reaper.GetCursorPosition(), reaper.GetProjectLength(0) + 400, true)
    reaper.MoveEditCursor((-previewLength), false)
    -- reaper.SetTempoTimeSigMarker(0, -1, metronomePos -  (60 /  reaper.Master_GetTempo() *3), -1, -1, reaper.Master_GetTempo(), 4, 4, false)
    reaper.SetMediaTrackInfo_Value(reaper.GetSelectedTrack(0, 0), "C_ALLLANESPLAY", 0) -- unsolo all Lanes
    timbert.smartRecord()
    timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_3")
    ExpandOnStop()
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. 

reaper.set_action_options(1 | 2)
main()

reaper.UpdateArrange()

reaper.Undo_EndBlock(script_name, -1) -- End of the undo block.

reaper.PreventUIRefresh(-1)
