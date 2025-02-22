-- @noindex
----------------------------
-- Get this script's name
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
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
if not timbert or timbert.version() < 1.929 then
    reaper.MB(
        "This script requires a newer version of TImbert Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages",
        script_name, 0)
    return
end

-- Load 'Solo priority lane with content under edit cursor in selected track' script
timbert_SoloLanePriority = reaper.GetResourcePath() ..
                               '/Scripts/TImbert Scripts/FILBetter/timbert_FILBetter Solo priority lane with content under edit cursor in selected track.lua'
if not reaper.file_exists(timbert_SoloLanePriority) then
    reaper.MB(
        "This script requires 'Solo priority lane with content under edit cursor in selected track'! Please install it here:\n\nExtensions > ReaPack > Browse Packages > 'FILBetter (Better Track Fixed Item Lanes)'",
        script_name, 0)
    return
end

-- Load lua 'Go to previous item stack in currently selected track fixed lanes' script
timbert_GoToNext = reaper.GetResourcePath() ..
                       '/Scripts/TImbert Scripts/FILBetter/timbert_FILBetter Go to next content in fixed lanes of currently selected track.lua'
if not reaper.file_exists(timbert_GoToNext) then
    reaper.ShowConsoleMsg(
        "This script requires 'Go to next content in fixed lanes of currently selected track'! Please install it here:\n\nExtensions > ReaPack > Browse Packages > 'FILBetter (Better Track Fixed Item Lanes)'");
    return
end

-- Load Config
timbert_FILBetter = reaper.GetResourcePath() ..
                        '/Scripts/TImbert Scripts/FILBetter/timbert_FILBetter (Better Track Fixed Item Lanes).lua'
dofile(timbert_FILBetter)

-- USERSETTING Loaded from FILBetterCFG.json--
local showValidationErrorMsg = FILBetter.LoadConfig("showValidationErrorMsg")
local makeRegionsForExport = FILBetter.LoadConfig("makeRegionsForExport")
local regionNameLeadingZero = FILBetter.LoadConfig("regionNameLeadingZero")
local regionNameTrailingZero = FILBetter.LoadConfig("regionNameTrailingZero")
local exportTrackNameAppend = FILBetter.LoadConfig("exportTrackNameAppend")
local exportTrackAppendMode = FILBetter.LoadConfig("exportTrackAppendMode")
---------------
local function GetSelectedTracks()
    local error
    if reaper.CountSelectedTracks(0) == 0 then
        error = "Please select at least one track first"
        return nil, error
    end
    local tracks = {}
    for i = 0, reaper.CountSelectedTracks(0) - 1 do

        local track = reaper.GetSelectedTrack(0, i)
        local _, trackName = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
        -- Return if fixed Lanes isn't enable on selected track
        if reaper.GetMediaTrackInfo_Value(track, "I_FREEMODE") ~= 2 then
            if trackName == "" then
                trackName = "track " .. math.floor(reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")) ..
                                " (no name)"
            end
            error = "Some of the selected tracks don't contain Fixed Item Lanes \nTrack: " .. trackName
            break
            return nil, error
        end
        table.insert(tracks, {
            track = track,
            trackName = trackName
        })
    end

    return tracks, error
end

local function AddLeadingZero(int)
    local leadingAmount = math.abs(regionNameLeadingZero)
    local string = ""
    local isBroke, amount
    if leadingAmount == 0 then
        string = string .. tostring(int)
        return string
    end
    for i = leadingAmount, 1, -1 do
        local modulo = int - (int % 10 ^ i)
        if modulo == (10 ^ i) or modulo / (modulo / 10) == 10 then
            string = string.rep("0", leadingAmount - i)
            amount = i
            break
        end
        string = string.rep("0", leadingAmount)
    end
    string = string .. tostring(int)

    return string
end

local function AddTrailingZero()
    local trailAmount = math.abs(regionNameTrailingZero)
    local string = ""
    string = string .. string.rep("0", trailAmount)
    return string
end

function main()
    -- Validate track selection
    local tracks, error = GetSelectedTracks()
    if error ~= nil then
        if showValidationErrorMsg == true then
            timbert.msg(error, script_name)
        end
        return
    end

    local firstItemPosition, prevCurPos
    local contents = {}
    for i = 1, #tracks do
        if reaper.CountTrackMediaItems(tracks[i].track) ~= 0 then

            reaper.SetOnlyTrackSelected(tracks[i].track)
            reaper.SetEditCurPos(reaper.GetMediaItemInfo_Value(reaper.GetTrackMediaItem(tracks[i].track, 0),
                "D_POSITION"), false, false)
            firstItemPosition = reaper.GetCursorPosition()
            repeat
                prevCurPos = reaper.GetCursorPosition()
                if firstItemPosition == prevCurPos then
                    dofile(timbert_SoloLanePriority)
                else
                    dofile(timbert_GoToNext)
                end
                timbert.SetTimeSelectionToAllItemsInVerticalStack(true)
                local items = timbert.GetSelectedItemsInLaneInfo(timbert.GetActiveTrackLane(tracks[i].track))
                table.insert(contents, items)
                if firstItemPosition == prevCurPos then
                    reaper.MoveEditCursor(0.1, false)
                end
            until prevCurPos == reaper.GetCursorPosition()
            table.remove(contents, #contents)

            reaper.InsertTrackAtIndex(reaper.GetNumTracks(), false)
            if exportTrackAppendMode == "prefix" then
                reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(0, reaper.GetNumTracks() - 1), "P_NAME",
                    exportTrackNameAppend .. tracks[i].trackName, true)
            else -- == "suffix"
                reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(0, reaper.GetNumTracks() - 1), "P_NAME",
                    tracks[i].trackName .. exportTrackNameAppend, true)
            end

            for j = 1, #contents do
                for k = 1, #contents[j] do
                    local _, itemChunk = reaper.GetItemStateChunk(contents[j][k].item, '')
                    local newMedia = reaper.AddMediaItemToTrack(reaper.GetTrack(0, reaper.GetNumTracks() - 1))
                    reaper.SetItemStateChunk(newMedia, itemChunk)
                end

                if makeRegionsForExport == true then
                    local color = reaper.GetMediaTrackInfo_Value(tracks[i].track, "I_CUSTOMCOLOR")
                    local regionindex = reaper.AddProjectMarker2(0, true, contents[j][1].itemPosition,
                        contents[j][#contents[j]].itemPosition + contents[j][#contents[j]].itemLength, tracks[i]
                            .trackName .. AddLeadingZero(j) .. AddTrailingZero(), 1, color)
                    reaper.SetRegionRenderMatrix(0, regionindex, reaper.GetTrack(0, reaper.GetNumTracks() - 1), 1)
                end
            end
            contents = {}
        end
    end

    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
    reaper.Main_OnCommand(40635, 0) -- Time selection: Remove (unselect) time selection
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. 

main()

reaper.UpdateArrange()

reaper.PreventUIRefresh(-1)

reaper.Undo_EndBlock(script_name, -1) -- End of the undo block
