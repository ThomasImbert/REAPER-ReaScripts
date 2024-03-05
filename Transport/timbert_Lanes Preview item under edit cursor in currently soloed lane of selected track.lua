-- @description Preview item under edit cursor in currently soloed lane of selected track
-- @author Thomas Imbert
-- @version 1.2
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about Preview item under edit cursor in currently soloed lane of selected track
-- @changelog 
--   # Reworked array functions
-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1, ({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath() .. '/scripts/TImbert Scripts/Development/timbert_Lua Utilities.lua'
if reaper.file_exists(timbert_LuaUtils) then
    dofile(timbert_LuaUtils);
    if not timbert or timbert.version() < 1.921 then
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
    -- Return if fixed Lanes isn't enable on selected track
    local track = reaper.GetSelectedTrack(0, 0)
    if reaper.GetMediaTrackInfo_Value(track, "I_FREEMODE") ~= 2 then
        timbert.msg(
            "Fixed item lanes isn't enable on selected track, right click on it or go to Track Menu to enable it",
            script_name)
        return
    end
    local safeLane = nil
    local isCompLane = false
    local items, lastLane = timbert.MakeItemArraySortByLane()
    
    -- Identify if Lane is a Comping lane (containing multiple items generally)
    local _, laneName = reaper.GetSetMediaTrackInfo_String(track, "P_LANENAME:" .. tostring(items[1].laneIndex), "laneName",
    false)
    if string.find(laneName, "C") == 1 then 
        isCompLane = true
        safeLane = items[1].laneIndex
    end

    local laneIndex = timbert.GetActiveTrackLane(track) or safeLane or lastLane

    -- If laneIndex is greater than last lane containing item, set laneIndex to that lane
    if laneIndex > lastLane then
        if isCompLane then
            laneIndex = items[1].laneIndex
        else
            laneIndex = lastLane
        end
    end
    
    reaper.SetMediaTrackInfo_Value(track, "C_LANEPLAYS:" .. tostring(laneIndex), 1)

    if isCompLane then
        timbert.swsCommand("_BR_SAVE_CURSOR_POS_SLOT_1")
        timbert.swsCommand("_SWS_SAVETIME1")
        reaper.Main_OnCommand(40290, 0) -- Time selection: Set time selection to items
        reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
        reaper.Main_OnCommand(40718, 0) -- Item: Select all items on selected tracks in current time selection
        local compItems = timbert.GetSelectedItemsInLaneInfo(laneIndex)
        reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items

        -- if comp lane has multiple items, glue on a temporary lane, preview then remove glued item + lane
        if #compItems > 1 then
            timbert.PreviewMultipleItems(compItems, compItems[1].itemPosition, track,
                false, true)
        else
            reaper.SetMediaItemSelected(compItems[1].item, true)
            timbert.swsCommand("_SWS_PREVIEWTRACK") -- Xenakios/SWS: Preview selected media item through track
        end
        timbert.swsCommand("_SWS_RESTTIME1")
        timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_1")
        return
    end

    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
    reaper.SetMediaItemSelected(items[laneIndex].item, true)

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

main()

reaper.UpdateArrange()

reaper.Undo_EndBlock("Preview item under edit cursor in currently soloed lane of selected track", -1) -- End of the undo block. Leave it at the bottom of your main function.

reaper.PreventUIRefresh(-1)
