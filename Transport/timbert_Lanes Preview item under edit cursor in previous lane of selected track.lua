-- @description Preview item under edit cursor in previous lane of selected track
-- @author Thomas Imbert
-- @version 1.1
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about Preview item under edit cursor in previous lane of selected track
-- @changelog 
--   # Added preview mode for comp lanes 
-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1, ({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath() .. '/scripts/TImbert Scripts/Development/timbert_Lua Utilities.lua'
if reaper.file_exists(timbert_LuaUtils) then
    dofile(timbert_LuaUtils);
    if not timbert or timbert.version() < 1.92 then
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

function main()
    local track = reaper.GetSelectedTrack(0, 0)

    -- Return if fixed Lanes isn't enable on selected track
    if reaper.GetMediaTrackInfo_Value(track, "I_FREEMODE") ~= 2 then
        timbert.msg(
            "Fixed item lanes isn't enable on selected track, right click on it or go to Track Menu to enable it",
            script_name)
        return
    end

    local itemArray, lastLane, laneIndexes = timbert.MakeItemArrayByLaneIndex()
    local laneIndex = timbert.GetActiveTrackLane(track) or lastLane

    -- If laneIndex is greater than last lane containing item, set laneIndex to that lane
    if laneIndex - 1 < laneIndexes[1] or laneIndex > lastLane then
        laneIndex = lastLane
    else
        laneIndex = laneIndexes[(timbert.FindIndex(laneIndexes, laneIndex)) - 1] -- goes to previous lane with content
    end

    reaper.SetMediaTrackInfo_Value(reaper.GetSelectedTrack(0, 0), "C_LANEPLAYS:" .. tostring(laneIndex), 1)
	
	-- Identify if Lane is a Comping lane (containing multiple items generally)
    local _, laneName = reaper.GetSetMediaTrackInfo_String(track, "P_LANENAME:" .. tostring(laneIndex), "laneName",
        false)
    local matchStartIndex, _ = string.find(laneName, "C")
    if matchStartIndex ~= nil and matchStartIndex == 1 then
        timbert.swsCommand("_BR_SAVE_CURSOR_POS_SLOT_1")
        timbert.swsCommand("_SWS_SAVETIME1")
        reaper.Main_OnCommand(40290, 0) -- Time selection: Set time selection to items
        reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
        reaper.Main_OnCommand(40718, 0) -- Item: Select all items on selected tracks in current time selection
        local compItemsArray = timbert.GetSelectedItemsInLaneInfo(laneIndex)
        reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
        table.sort(compItemsArray, function(a, b)
            return a[itemPosition] < b[itemPosition]
        end)

        -- if comp lane has multiple items, glue on a temporary lane, preview then remove glued item + lane
        if timbert.GetTableLength(compItemsArray.item) > 1 then
            timbert.PreviewMultipleItems(compItemsArray.item, compItemsArray.itemPosition[1], track,
                false, true)
        else
            reaper.SetMediaItemSelected(compItemsArray.item[1], true)
            timbert.swsCommand("_SWS_PREVIEWTRACK") -- Xenakios/SWS: Preview selected media item through track
        end
        timbert.swsCommand("_SWS_RESTTIME1")
        timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_1")
        return
    end
	
	-- solos last lane
    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
    reaper.SetMediaItemSelected(itemArray[laneIndex], true)

    timbert.swsCommand("_SWS_PREVIEWTRACK") -- Xenakios/SWS: Preview selected media item through track
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

if reaper.CountSelectedTracks(0) == 0 then
    timbert.msg("Please select a track first", script_name)
    return
end

timbert.swsCommand("_XENAKIOS_SELITEMSUNDEDCURSELTX") -- Xenakios/SWS: Select items under edit cursor on selected tracks
if reaper.CountSelectedMediaItems(0) == 0 then
    timbert.msg("Please place your cursor on items first", script_name)
    return
end

main() -- call main function 

reaper.UpdateArrange()

reaper.Undo_EndBlock("Preview item under edit cursor in previous lane of selected track", -1) -- End of the undo block. Leave it at the bottom of your main function.

reaper.PreventUIRefresh(-1)
