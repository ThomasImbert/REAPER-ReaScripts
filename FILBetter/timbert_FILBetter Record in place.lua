-- @noindex
----------------------------
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

-- Load lua 'Move edit cursor forward away from last items on selected track' script
timbert_MoveEditCurAway = reaper.GetResourcePath() ..
                              '/scripts/TImbert Scripts/FILBetter/timbert_FILBetter Move edit cursor forward away from last items on selected track.lua'

-- Load lua 'Move edit cursor in between current and next content on selected track' script
timbert_MoveEditCurBetween = reaper.GetResourcePath() ..
                                 '/scripts/TImbert Scripts/FILBetter/timbert_FILBetter Move edit cursor in between current and next content on selected track.lua'

-- Load Config
timbert_FILBetter = reaper.GetResourcePath() ..
                        '/scripts/TImbert Scripts/FILBetter/timbert_FILBetter (Better Track Fixed Item Lanes).lua'
dofile(timbert_FILBetter)

-- USERSETTING Loaded from FILBetterCFG.json--
local showValidationErrorMsg = FILBetter.LoadConfig("showValidationErrorMsg")
local scrollView = FILBetter.LoadConfig("scrollViewToEditCursorOnStopRecording")
local recallCursPosWhenRetriggRec = FILBetter.LoadConfig("recallCursPosWhenRetriggRec")
local recordingBellOn = FILBetter.LoadConfig("recordingBellOn")
-- In Metronome setting, allow run during recording
-- Try Primary beat = 250Hz and 100ms duration and sine soft start for a gentle rec bell
---------------
local function GetTakes(items)
    if items == nil or #items < 1 then
        return
    end
    local takes = {}
    local take, takeName
    for i = 1, #items do
        take = reaper.GetActiveTake(items[i].item)
        _, takeName = reaper.GetSetMediaItemTakeInfo_String(reaper.GetActiveTake(items[i].item), "P_NAME", "takeName",
            false)
        table.insert(takes, {
            take = take,
            takeName = takeName
        })
    end
    return takes
end

local function FindRecordedItem(takesPre, takesPost)
    local recordedItem, take, takeName
    local foundMatch = false
    for i = 1, #takesPost do
        foundMatch = false
        takeName = takesPost[i].takeName
        for j = 1, #takesPre do
            if takeName == takesPre[j].takeName then
                foundMatch = true
                break
            end
        end
        if foundMatch == false then
            recordedItem = reaper.GetMediaItemTake_Item(takesPost[i].take)
        end
    end
    return recordedItem
end

local track, lane, item, error, recPosition, takesPost, itemsPost, _, recSeriesStarted, cursorRecall

local function RecordLoop(cursorRecall)
    local _, recMode = reaper.GetProjExtState(0, "FILBetter", "Rec_Mode")
    if recMode == "context" then
        return -- interrupt loop if user triggered Record with context script for a new take
    end

    cursorRecall = reaper.GetCursorPosition()

    -- If stopped
    if reaper.GetPlayState() == 0 then

        reaper.PreventUIRefresh(1)
        -- set correct lane active from last recorded item
        item = reaper.GetSelectedMediaItem(0, 0)
        reaper.Main_OnCommand(42938, 0) -- Track lanes: Move items up if possible to minimize lane usage
        _, track = reaper.GetProjExtState(0, "FILBetter", "Rec_Track")
        track = reaper.BR_GetMediaTrackByGUID(0, track)
        lane = reaper.GetMediaItemInfo_Value(item, "I_FIXEDLANE")
        reaper.SetMediaTrackInfo_Value(track, "C_ALLLANESPLAY", 0) -- unsolo all Lanes
        reaper.SetMediaTrackInfo_Value(track, "C_LANEPLAYS:" .. tostring(lane), 1)
        reaper.SetEditCurPos(reaper.GetMediaItemInfo_Value(item, "D_POSITION"), scrollView, false)
        reaper.UpdateArrange()
        reaper.PreventUIRefresh(-1)

        -- reset
        reaper.SetProjExtState(0, "FILBetter", "Rec_Series", "false")
        reaper.SetProjExtState(0, "FILBetter", "Rec_Track", "")
        reaper.SetProjExtState(0, "FILBetter", "Rec_PunchInPos", "")

        local _, moveAwayCall = reaper.GetProjExtState(0, "FILBetter", "MoveEditCurAway")
        if moveAwayCall == "true" then
            reaper.SetProjExtState(0, "FILBetter", "MoveEditCurAway", "false")
            dofile(timbert_MoveEditCurAway)
        end

        local _, moveBetweenCall = reaper.GetProjExtState(0, "FILBetter", "MoveEditCurBetween")
        if moveBetweenCall == "true" then
            reaper.SetProjExtState(0, "FILBetter", "MoveEditCurBetween", "false")
            dofile(timbert_MoveEditCurBetween)
        end
        return
    end
    -- Rerun if not stopped
    reaper.defer(function()
        RecordLoop(cursorRecall)
    end)
end

local function RecordingBell(recPosition, bellMarker)
    -- Enable Metronome tick as recording bell for 1 tick
    if reaper.GetPlayPosition() > recPosition + 0.2 then
        reaper.PreventUIRefresh(1)
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_METROOFF"), 0) -- SWS: Metronome disable
        reaper.DeleteTempoTimeSigMarker(0, bellMarker)
        reaper.UpdateArrange()
        reaper.PreventUIRefresh(-1)
        return
    end
    reaper.defer(function()
        RecordingBell(recPosition, bellMarker)
    end)
end

function main()
    if reaper.GetPlayState() == 0 then
        -- store value once for this recording series
        -- Validate track armed
        local hasArmedTracks = false
        for i = 0, reaper.CountTracks(0) - 1 do
            if reaper.GetMediaTrackInfo_Value(reaper.GetTrack(0, i), "I_RECARM") == 1 then
                track = reaper.GetTrack(0, i)
                hasArmedTracks = true
                break
            end
        end
        if hasArmedTracks == false then
            if showValidationErrorMsg == true then
                timbert.msg("No record armed track", script_name)
            end
            return
        end

        reaper.SetProjExtState(0, "FILBetter", "Rec_Series", "true") -- set to stop when transport is stopped outside of retrigg
        reaper.SetProjExtState(0, "FILBetter", "Rec_Track", reaper.GetTrackGUID(track))

        -- check if content at position, if yes, store content item guid to recall its start pos, if no content, store cursor pos (rounding error)
        timbert.swsCommand("_XENAKIOS_SELITEMSUNDEDCURSELTX") -- Xenakios/SWS: Select items under edit cursor on selected tracks
        if reaper.CountSelectedMediaItems(0) > 0 then
            -- recPosition = reaper.GetSelectedMediaItem(0, 0) -- recPosition = item to calculate each time  reaper.GetMediaItemInfo_Value( recPosition, "D_POSITION" )
            _, recPosition = reaper.GetSetMediaItemInfo_String(reaper.GetSelectedMediaItem(0, 0), "GUID", "", false)
            reaper.SetProjExtState(0, "FILBetter", "Rec_PunchInPos", recPosition)
        else
            recPosition = reaper.GetCursorPosition()
            reaper.SetProjExtState(0, "FILBetter", "Rec_PunchInPos", recPosition)
        end
        reaper.Main_SaveProject(0, false) -- save to store ProjExtStates
    end

    -- Get RecPosition, is timePos if rec was started in empty spot, is item GUID if rec was started at content position
    _, recPosition = reaper.GetProjExtState(0, "FILBetter", "Rec_PunchInPos")
    local itemRecPos = reaper.BR_GetMediaItemByGUID(0, recPosition)
    if itemRecPos ~= nil then
        recPosition = reaper.GetMediaItemInfo_Value(itemRecPos, "D_POSITION")
        reaper.SetEditCurPos(recPosition, false, false)
    end

    if recordingBellOn == true then
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_METROON"), 0) -- SWS: Metronome enable
        local timepos, bellMarker, _
        reaper.SetTempoTimeSigMarker(0, -1, recPosition, -1, -1, reaper.Master_GetTempo(), 4, 4, true)

        for i = 0, reaper.CountTempoTimeSigMarkers(0) - 1 do
            _, timepos, _, _, _, _, _, _ = reaper.GetTempoTimeSigMarker(0, i)
            if math.floor(timepos * 100) / 100 == math.floor(recPosition * 100) / 100 then
                bellMarker = i
                break
            end
        end
        reaper.defer(function()
            RecordingBell(recPosition, bellMarker)
        end)
    end

    if reaper.GetPlayState() >= 4 then
        cursorRecall = cursorRecall or reaper.GetCursorPosition()
        reaper.Main_OnCommand(1016, 0) -- Transport: Stop
        item = reaper.GetSelectedMediaItem(0, 0)
        reaper.Main_OnCommand(42938, 0) -- Track lanes: Move items up if possible to minimize lane usage
        _, track = reaper.GetProjExtState(0, "FILBetter", "Rec_Track")
        track = reaper.BR_GetMediaTrackByGUID(0, track)
        lane = reaper.GetMediaItemInfo_Value(item, "I_FIXEDLANE")
        reaper.SetMediaTrackInfo_Value(track, "C_ALLLANESPLAY", 0) -- unsolo all Lanes
        reaper.SetMediaTrackInfo_Value(track, "C_LANEPLAYS:" .. tostring(lane), 1)
        reaper.SetEditCurPos(reaper.GetMediaItemInfo_Value(item, "D_POSITION"), false, false)
    end

    reaper.Main_OnCommand(1013, 0) -- Transport: Record
    reaper.SetProjExtState(0, "FILBetter", "Rec_Mode", "inPlace")
    RecordLoop()
    if recallCursPosWhenRetriggRec == true and cursorRecall ~= nil then
        reaper.SetEditCurPos(cursorRecall, false, false)
    end
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. 

reaper.set_action_options(1 | 2)

main()

reaper.UpdateArrange()

reaper.PreventUIRefresh(-1)

reaper.Undo_EndBlock(script_name, -1) -- End of the undo block
