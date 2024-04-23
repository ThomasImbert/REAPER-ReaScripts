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
local showValidationErrorMsg = FILBetter.LoadConfig("showValidationErrorMsg")
local lanePriority = FILBetter.LoadConfig("lanePriority")
local prioritizeCompLaneOverLastLane = FILBetter.LoadConfig("prioritizeCompLaneOverLastLane")
local compLanePriority = FILBetter.LoadConfig("compLanePriority")
---------------

local function CorrectLaneIndex(laneIndex, lastLane, items, hasCompLane, compLanes)
    local laneOutsideComp
    if hasCompLane == true and prioritizeCompLaneOverLastLane == true then
        if compLanePriority == "first" then
            laneIndex = compLanes[1] -- go to first complane
        else
            laneIndex = compLanes[#compLanes] -- go to last complane
        end
    else
        if lanePriority == "last" then
            if hasCompLane == false then
                laneIndex = items[#items].laneIndex
            else
                -- Get last lane outside of compLanes
                for i = #items, 1, -1 do
                    for j = 1, #compLanes do
                        if items[i].laneIndex == compLanes[j] then
                            laneOutsideComp = false
                            break
                        else
                            laneOutsideComp = true
                        end
                    end
                    if laneOutsideComp == true then
                        laneIndex = items[i].laneIndex
                        break
                    end
                end
            end
        elseif hasCompLane == true then
            -- Get first lane with content outside of compLanes
            for i = 1, #items do
                for j = 1, #compLanes do
                    if items[i].laneIndex == compLanes[j] then
                        laneOutsideComp = false
                        break
                    else
                        laneOutsideComp = true
                    end
                end
                if laneOutsideComp == true then
                    laneIndex = items[i].laneIndex
                    break
                end
            end
        else
            laneIndex = items[1].laneIndex
        end
    end
    return laneIndex
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

    if timbert.ValidateItemsUnderEditCursorOnSelectedTracks() == false then
        return
    end

    local cursPos = reaper.GetCursorPosition()
    local startTime, endTime = reaper.GetSet_LoopTimeRange(false, false, startTime, endTime, false)
    timbert.SetTimeSelectionToAllItemsInVerticalStack()
    local items, lastLane = timbert.MakeItemArraySortByLane()
    local hasCompLane, compLanes = timbert.GetCompLanes(items, track)
    local laneIndex = lastLane

    laneIndex = CorrectLaneIndex(laneIndex, lastLane, items, hasCompLane, compLanes)
    reaper.SetMediaTrackInfo_Value(reaper.GetSelectedTrack(0, 0), "C_LANEPLAYS:" .. tostring(laneIndex), 1)

    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of all items)
    reaper.Main_OnCommand(40635, 0) -- Time selection: Remove (unselect) time selection

    reaper.GetSet_LoopTimeRange(true, false, startTime, endTime, false)
    reaper.SetEditCurPos(cursPos, false, false)
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block.

main()

reaper.UpdateArrange()

reaper.Undo_EndBlock(script_name, -1) -- End of the undo block.

reaper.PreventUIRefresh(-1)
