-- @description Preview item under edit cursor in next lane of selected track
-- @author Thomas Imbert
-- @version 1.1
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about Preview item under edit cursor in next lane of selected track
-- @changelog 
--   # Added Comp Lane support
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

local function CycleLaneIndexFoward(laneIndex, lastLane, items, hasCompLane, compLanes, offset) -- Guard against laneIndex outside possible laneIndex with content
    if laneIndex > lastLane then
        if hasCompLane == true then
            laneIndex = compLanes[1] -- go to first complane
            timbert.dbg("CANNOT CYCLE FORWARD, HasComplane, laneIndex = " .. laneIndex)
        end
        if hasCompLane == false then
            laneIndex = items[1].laneIndex
            timbert.dbg("CANNOT CYCLE FORWARD, NOT HasComplane, laneIndex = " .. laneIndex)
        end
        return laneIndex
    end

    if laneIndex < items[1].laneIndex or laneIndex == items[#items].laneIndex then
        laneIndex = items[1].laneIndex
        timbert.dbg("END OF CYCLE, laneIndex = " .. laneIndex)
        return laneIndex
    end

    if items[laneIndex + 1].laneIndex > items[#items].laneIndex then
        laneIndex = items[1].laneIndex
        timbert.dbg("items[laneIndex+1].laneIndex +1 > #items " .. items[laneIndex + 1].laneIndex + 1)
        return laneIndex
    end

    laneIndex = items[laneIndex + 2 - offset].laneIndex -- goes to next lane with content, +1 for items table starting at 1, +1 again to go to next
    timbert.dbg(" CAN CYCLE FORWARD, laneIndex = " .. laneIndex)
    return laneIndex
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

    local items, lastLane = timbert.MakeItemArraySortByLane()
    local hasCompLane, compLanes = timbert.GetCompLanes(items, track)
    timbert.dbg("hasCompLane = " .. tostring(hasCompLane))

    local laneIndex = timbert.GetActiveTrackLane(track) or lastLane + 1
    timbert.dbg("laneIndex init= " .. laneIndex)

    laneIndex = CycleLaneIndexFoward(laneIndex, lastLane, items, hasCompLane, compLanes, items[1].laneIndex)

    reaper.SetMediaTrackInfo_Value(reaper.GetSelectedTrack(0, 0), "C_LANEPLAYS:" .. tostring(laneIndex), 1) -- solos last lane
    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items

    -- if laneIndex + 1 > #items then
    -- laneIndex = items[1].laneIndex
    -- reaper.SetMediaTrackInfo_Value(reaper.GetSelectedTrack(0, 0), "C_LANEPLAYS:" .. tostring(laneIndex), 1) -- solos last lane
    -- reaper.SetMediaItemSelected(items[laneIndex].item, true) -- +1 since items[i].item starts at 1 and laneIndex starts at 0
    -- timbert.swsCommand("_SWS_PREVIEWTRACK") -- Xenakios/SWS: Preview selected media item through track
    -- return
    -- end
    local itemIndex
    for i = 1, #items do
        if items[i].laneIndex == laneIndex then
            itemIndex = i
            break
        end
    end
    reaper.SetMediaItemSelected(items[itemIndex].item, true) -- +1 since items[i].item starts at 1 and laneIndex starts at 0
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

reaper.Undo_EndBlock("Preview item under edit cursor in next lane of selected track", -1) -- End of the undo block. Leave it at the bottom of your main function.

reaper.PreventUIRefresh(-1)
