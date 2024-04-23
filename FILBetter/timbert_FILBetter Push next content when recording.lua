-- @noindex
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
if not timbert or timbert.version() < 1.926 then
    reaper.MB(
        "This script requires a newer version of TImbert Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages",
        script_name, 0)
    return
end

-- Load Config
timbert_FILBetter = reaper.GetResourcePath() ..
                        '/Scripts/TImbert Scripts/FILBetter/timbert_FILBetter (Better Track Fixed Item Lanes).lua'
dofile(timbert_FILBetter)

-- USERSETTING Loaded from FILBetterCFG.json--
local timeThreshold = FILBetter.LoadConfig("pushNextContentTime")
---------------

local _, _, sectionID, cmdID, _, _, _ = reaper.get_action_context()
local nextContentPos, currentContentEndPos, playPos, timeStart, timeEnd, track, item, itemPosition, isSetup
local tracks, itemsToPush = {}, {}

function Exit()
    reaper.SetToggleCommandState(sectionID, cmdID, 0)
end

local function InsertItemsInTable()
    -- Make table of all items to push forward
    itemsToPush = {}
    for i = 0, reaper.CountMediaItems(0) - 1 do
        if reaper.GetMediaItemInfo_Value(reaper.GetMediaItem(0, i), "D_POSITION") > currentContentEndPos and
            reaper.GetMediaItemInfo_Value(reaper.GetMediaItem(0, i), "C_LOCK") ~= 1 then
            item = reaper.GetMediaItem(0, i)
            table.insert(itemsToPush, item)
        end
    end
end

function main()
    if reaper.GetPlayState() & 4 ~= 4 then -- if not recording
        isSetup = false
        return reaper.defer(main)
    end

    -- if Recording, DO ONCE
    if isSetup == false then

        reaper.PreventUIRefresh(1)
        local hasRecArmedTracks
        for i = 0, reaper.GetNumTracks() - 1 do
            if reaper.GetMediaTrackInfo_Value(reaper.GetTrack(0, i), "I_RECARM") == 1 then
                hasRecArmedTracks = true
                break
            end
            if hasRecArmedTracks == false then
                return reaper.defer(main)
            end
        end
        timeStart, timeEnd = reaper.GetSet_LoopTimeRange(false, false, _, _, false) -- Save TimeSelect at time of recording
        reaper.Main_OnCommand(40635, 0) -- Time selection: Remove (unselect) time selection
        timbert.SetTimeSelectionToAllItemsInVerticalStack()
        _, currentContentEndPos = reaper.GetSet_LoopTimeRange(false, false, _, _, false)
        if currentContentEndPos == 0 then
            currentContentEndPos = reaper.GetCursorPosition()+0.1
        end
        reaper.GetSet_LoopTimeRange(true, false, timeStart, timeEnd, false) -- reset timeselection to initial state
        isSetup = true
        reaper.PreventUIRefresh(-1)
    end

    -- DO EAcH TICK
    InsertItemsInTable()
    if #itemsToPush == 0 then
        reaper.Undo_EndBlock(script_name, 0)
        reaper.PreventUIRefresh(-1)
        reaper.defer(main)
        return
    end

    nextContentPos = reaper.GetMediaItemInfo_Value(itemsToPush[1], "D_POSITION")
    playPos = reaper.GetPlayPosition()
    if nextContentPos - playPos > timeThreshold or playPos < currentContentEndPos then
        reaper.Undo_EndBlock(script_name, 0)
        reaper.PreventUIRefresh(-1)
        reaper.defer(main)
        return
    end

    reaper.Undo_BeginBlock()
    for i = 1, #itemsToPush do
        itemPosition = reaper.GetMediaItemInfo_Value(itemsToPush[i], "D_POSITION")
        reaper.SetMediaItemInfo_Value(itemsToPush[i], "D_POSITION", itemPosition + timeThreshold)
        nextContentPos = nextContentPos + timeThreshold
    end
    reaper.defer(main)
    reaper.Undo_EndBlock(script_name, 0)
end

reaper.set_action_options(1)
reaper.SetToggleCommandState(sectionID, cmdID, 1)
reaper.RefreshToolbar2(sectionID, cmdID)
reaper.defer(main)
reaper.atexit(Exit)
