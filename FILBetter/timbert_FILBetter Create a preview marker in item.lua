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

-- Load 'Solo priority lane with content under edit cursor in selected track' script
timbert_SoloLanePriority = reaper.GetResourcePath() ..
                               '/scripts/TImbert Scripts/FILBetter/timbert_FILBetter Solo priority lane with content under edit cursor in selected track.lua'
if not reaper.file_exists(timbert_SoloLanePriority) then
    reaper.MB(
        "This script requires 'Solo priority lane with content under edit cursor in selected track'! Please install it here:\n\nExtensions > ReaPack > Browse Packages > 'FILBetter (Better Track Fixed Item Lanes)'",
        script_name, 0)
    return
end

-- Load Config
timbert_FILBetter = reaper.GetResourcePath() ..
                        '/scripts/TImbert Scripts/FILBetter/timbert_FILBetter (Better Track Fixed Item Lanes).lua'
dofile(timbert_FILBetter)

-- USERSETTING Loaded from FILBetterCFG.json--
local showValidationErrorMsg = FILBetter.LoadConfig("showValidationErrorMsg")
local makePreviewMarkerAtMouseCursor = FILBetter.LoadConfig("makePreviewMarkerAtMouseCursor")
local findTakeInPriorityLanePreviewMarkerAtEditCursor = FILBetter.LoadConfig(
    "findTakeInPriorityLanePreviewMarkerAtEditCursor")
local previewMarkerName = FILBetter.LoadConfig("previewMarkerName") -- default "[FILB]"
---------------

local function ResetUserSelection(track, cursPos, startTime, endTime, selectedItemsStart, activeTrackLane)
    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
    for i = 1, #selectedItemsStart do
        reaper.SetMediaItemSelected(selectedItemsStart[i], true)
    end
    reaper.GetSet_LoopTimeRange(true, false, startTime, endTime, false)
    reaper.SetEditCurPos(cursPos, false, false)
    if activeTrackLane ~= nil then
        reaper.SetMediaTrackInfo_Value(track, "C_ALLLANESPLAY", 0) -- DeActivate all lanes
        reaper.SetMediaTrackInfo_Value(track, "C_LANEPLAYS:" .. tostring(activeTrackLane), 1)
    end
end

local function FindTakeMarkerIndex(take)
    local markerName, index, _
    -- Check if previewMarkerName take Marker already exists 
    if reaper.GetNumTakeMarkers(take) > 0 then
        for i = 0, reaper.GetNumTakeMarkers(take) - 1 do
            _, markerName, _ = reaper.GetTakeMarker(take, i)
            if markerName == previewMarkerName then
                index = i
                break
            end
        end
    end
    return index
end

local function MakeMarker(takeFound, sameItem, item, index, targetPosition)
    if takeFound ~= nil then
        if sameItem == true then
            -- already exists, move it to mouse cursor pos
            reaper.SetTakeMarker(reaper.GetActiveTake(item), index, previewMarkerName, targetPosition)
        else
            -- already exists on diffent item in content, delete 
            reaper.DeleteTakeMarker(takeFound, index)
            -- and create it at mouse cursor pos
            reaper.SetTakeMarker(reaper.GetActiveTake(item), -1, previewMarkerName, targetPosition)
        end

    else
        -- create a new take marker at mouse cursor pos
        reaper.SetTakeMarker(reaper.GetActiveTake(item), -1, previewMarkerName, targetPosition)
    end
end

local function MarkerExists(items, item)
    local markerName, index, takeFound, indexFound, take, _
    local takeInput = reaper.GetActiveTake(item)

    for i = 1, #items do
        take = reaper.GetActiveTake(items[i].item)
        index = FindTakeMarkerIndex(take)
        if index ~= nil then
            takeFound = take
            indexFound = index
            break
        end
    end
    if takeFound == takeInput then
        return takeFound, true, indexFound
    else
        return takeFound, false, indexFound
    end
end

function main()
    -- Validate track selection
    local track, error = timbert.ValidateLanesPreviewScriptsSetup()
    if track == nil then
        if showValidationErrorMsg == true then
            timbert.msg(error, script_name)
        end
        return
    end

    local activeTrackLane = timbert.GetActiveTrackLane(track)

    local cursPos = reaper.GetCursorPosition()
    local startTime, endTime = reaper.GetSet_LoopTimeRange(false, false, startTime, endTime, false)
    local selectedItemsStart = {}
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        table.insert(selectedItemsStart, reaper.GetSelectedMediaItem(0, i))
        reaper.GetSelectedMediaItem(0, i)
    end

    local item, index, itemLane, items, takeFound, sameItem, targetPosition, takeRate

    if makePreviewMarkerAtMouseCursor == true then
        local _, _, details = reaper.BR_GetMouseCursorContext()
        -- return if mouse not on an item
        if details ~= "item" then
            return
        end

        item = reaper.BR_GetMouseCursorContext_Item()
        itemLane = reaper.GetMediaItemInfo_Value(item, "I_FIXEDLANE")
        reaper.SetEditCurPos(reaper.GetMediaItemInfo_Value(item, "D_POSITION"), false, false)
        timbert.SetTimeSelectionToAllItemsInVerticalStack(true)
        items = timbert.GetSelectedItemsInLaneInfo(itemLane)
        reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items

        takeFound, sameItem, index = MarkerExists(items, item)
        takeRate = reaper.GetMediaItemTakeInfo_Value(reaper.GetActiveTake(item), "D_PLAYRATE")
        targetPosition =
            (reaper.BR_GetMouseCursorContext_Position() - reaper.GetMediaItemInfo_Value(item, "D_POSITION")) * takeRate +
                reaper.GetMediaItemTakeInfo_Value(reaper.GetActiveTake(item), "D_STARTOFFS")

        MakeMarker(takeFound, sameItem, item, index, targetPosition)
    else -- if makePreviewMarkerAtMouseCursor == false, make take marker at edit cursor position on content in priority lane

        if timbert.ValidateItemsUnderEditCursorOnSelectedTracks() == false then
            ResetUserSelection(track, cursPos, startTime, endTime, selectedItemsStart, activeTrackLane)
            return
        end

        -- create marker at edit cursor on content in priority lane
        local items = {}
        local priorityLaneAtCursor
        if findTakeInPriorityLanePreviewMarkerAtEditCursor == true then
            dofile(timbert_SoloLanePriority) --  Solo priority lane
            local priorityLaneAtCursor = timbert.GetActiveTrackLane(track)
            timbert.swsCommand("_XENAKIOS_SELITEMSUNDEDCURSELTX") -- Xenakios/SWS: Select items under edit cursor on selected tracks
            items = timbert.GetSelectedItemsInLaneInfo(priorityLaneAtCursor)

            if items == nil or #items < 1 then
                ResetUserSelection(track, cursPos, startTime, endTime, selectedItemsStart, activeTrackLane)
                return
            end

            item = items[1].item
            timbert.SetTimeSelectionToAllItemsInVerticalStack(true)
            items = timbert.GetSelectedItemsInLaneInfo(priorityLaneAtCursor)
            reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
            reaper.SetEditCurPos(cursPos, false, false)
        else
            local _, _, details = reaper.BR_GetMouseCursorContext()
            -- return if mouse not on an item
            if details ~= "item" then
                ResetUserSelection(track, cursPos, startTime, endTime, selectedItemsStart, activeTrackLane)
                return
            end

            item = reaper.BR_GetMouseCursorContext_Item()
            table.insert(items, {
                item = item
            })
        end

        takeFound, sameItem, index = MarkerExists(items, item)
        takeRate = reaper.GetMediaItemTakeInfo_Value(reaper.GetActiveTake(item), "D_PLAYRATE")
        targetPosition = (reaper.GetCursorPosition() - reaper.GetMediaItemInfo_Value(item, "D_POSITION")) * takeRate +
                             reaper.GetMediaItemTakeInfo_Value(reaper.GetActiveTake(item), "D_STARTOFFS")

        MakeMarker(takeFound, sameItem, item, index, targetPosition)
    end
    ResetUserSelection(track, cursPos, startTime, endTime, selectedItemsStart, activeTrackLane)
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block.

main()

reaper.UpdateArrange()

reaper.Undo_EndBlock(script_name, -1) -- End of the undo block.

reaper.PreventUIRefresh(-1)
