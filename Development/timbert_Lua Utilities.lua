-- @description TImbert Lua Utilities
-- @author Thomas Imbert
-- @version 1.921
-- @metapackage
-- @provides
--   [main] .
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about
--   # Lua Utilities
-- @changelog
--   # Added MakeItemArraySortByLane, ValidateLanesPreviewScriptsSetup, GetCompLanes, PreviewLaneContent, SelectOnlyFirstItemPerLaneInSelection and reworked tables scripts added in 1.92, Fixed GetActiveLane isFirst mode
--[[

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath()..'/scripts/TImbert Scripts/Development/timbert_Lua Utilities.lua'
if reaper.file_exists( timbert_LuaUtils ) then dofile( timbert_LuaUtils ); if not timbert or timbert.version() < 1.921 then timbert.msg('This script requires a newer version of timbert Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"timbert Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires timbert Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'timbert Lua Utilities'"); return end

]] timbert = {}

function timbert.version()
    local file = io.open(
        (reaper.GetResourcePath() .. '/scripts/TImbert Scripts/Development/timbert_Lua Utilities.lua'):gsub('\\', '/'),
        "r")
    local vers_header = "-- @version "
    io.input(file)
    local t = 0
    for line in io.lines() do
        if line:find(vers_header) then
            t = line:gsub(vers_header, "")
            break
        end
    end
    io.close(file)
    return tonumber(t)
end

-- Deliver messages and add new line in console
function timbert.dbg(dbg)
    reaper.ShowConsoleMsg(tostring(dbg) .. "\n")
end

-- Deliver messages using message box
function timbert.msg(msg, title)
    local title = title or "timbert Info"
    reaper.MB(tostring(msg), title, 0)
end

-- Rets to bools // returns Boolean
function timbert.retToBool(ret)
    if ret == 1 then
        return true
    else
        return false
    end
end

-- sws local command ID

function timbert.swsCommand(nameSWS)
    swsID = reaper.NamedCommandLookup(nameSWS)
    -- timbert.dbg(swsID.." is "..nameSWS)
    reaper.Main_OnCommand(swsID, 0)
end

---

function timbert.storeNotes()
    if reaper.CountSelectedMediaItems(0) > 0 then -- Check that an item is selected
        local selItem = reaper.GetSelectedMediaItem(0, 0)
        local itemNotes = ""
        local itemCount = reaper.CountSelectedMediaItems(0)
        boolean, itemNotes = reaper.GetSetMediaItemInfo_String(selItem, "P_NOTES", itemNotes, false)
        reaper.DeleteExtState("vascReaper", "vascNotes", false)
        reaper.SetProjExtState(0, "vascReaper", "vascNotes", tostring(itemNotes))
    end
end

function timbert.pasteNotes()
    if reaper.CountSelectedMediaItems(0) > 0 then -- Check that an item is selected
        local itemCount = reaper.CountSelectedMediaItems(0)
        local selItem
        for i = 1, itemCount do
            selItem = reaper.GetSelectedMediaItem(0, i - 1)
            retval, itemNotes = reaper.GetProjExtState(0, "vascReaper", "vascNotes")
            reaper.GetSetMediaItemInfo_String(selItem, "P_NOTES", itemNotes, true)
        end
    end
end

--[[Track selection functions starts here]]
-- This script was generated by Lokasenna_Select tracks by name.lua
local settings = {matchmultiple, search, selchildren, selparents, selsiblings, matchonlytop}

local function trackSelectionSettings(trackName) -- call this function to setup settings
    settings = {}
    if trackName == "Guide" then
        settings = {
            matchmultiple = false,
            search = "VASC_GUIDE",
            selchildren = false,
            selparents = false,
            selsiblings = false,
            matchonlytop = false
        }
    end
    if trackName == "Alt" then
        settings = {
            selparents = false,
            search = "ALT_",
            selchildren = true,
            matchonlytop = false,
            selsiblings = false,
            add_selection = true,
            matchmultiple = true
        }
    end
    if trackName == "Reference" then
        settings = {
            selparents = false,
            search = "VASC_REF",
            selchildren = false,
            matchonlytop = false,
            selsiblings = false,
            add_selection = true,
            matchmultiple = false
        }
    end
    return settings
end

-- local info = debug.getinfo(1,'S');
-- script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
-- local script_filename = ({reaper.get_action_context()})[2]:match("([^/\\]+)$")
-- 
-- Search Functions --

-- Returns true if the individual words of str_b all appear in str_a
local function fuzzy_match(str_a, str_b)

    if not (str_a and str_b) then
        return
    end
    str_a, str_b = string.lower(tostring(str_a)), string.lower(tostring(str_b))

    -- Msg("\nfuzzy match, looking for:\n\t" .. str_b .. "\nin:\n\t" .. str_a .. "\n")

    for word in string.gmatch(str_b, "[^%s]+") do
        -- Msg( tostring(word) .. ": " .. tostring( string.match(str_a, word) ) )
        if not string.match(str_a, word) then
            return
        end
    end
    return true
end

local function is_match(str, tr_name, tr_idx)
    if str:sub(1, 1) == "#" then
        -- Force an integer until/unless I come up with some sort of multiple track syntax
        str = tonumber(str:sub(2, -1))
        return str and (math.floor(tonumber(str)) == tr_idx)

    elseif tostring(str) then
        return fuzzy_match(tr_name, tostring(str))
    end
end

local function merge_tables(...)

    local tables = {...}

    local ret = {}
    for i = #tables, 1, -1 do
        if tables[i] then
            for k, v in pairs(tables[i]) do
                if v then
                    ret[k] = v
                end
            end
        end
    end

    return ret

end

-- Returns an array of MediaTrack == true for all parents of the given MediaTrack
local function recursive_parents(track)
    if reaper.GetTrackDepth(track) == 0 then
        return {
            [track] = true
        }
    else
        local ret = recursive_parents(reaper.GetParentTrack(track))
        ret[track] = true
        return ret
    end
end

local function get_children(tracks)
    local children = {}
    for idx in pairs(tracks) do

        local tr = reaper.GetTrack(0, idx - 1)
        local i = idx + 1
        while i <= reaper.CountTracks(0) do
            children[i] = recursive_parents(reaper.GetTrack(0, i - 1))[tr] == true
            if not children[i] then
                break
            end
            i = i + 1
        end
    end
    return children
end

local function get_parents(tracks)
    local parents = {}
    for idx in pairs(tracks) do

        local tr = reaper.GetTrack(0, idx - 1)
        for tr in pairs(recursive_parents(tr)) do
            parents[math.floor(reaper.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER"))] = true
        end
    end
    return parents
end

local function get_top_level_tracks()
    local top = {}
    for i = 1, reaper.CountTracks() do
        if reaper.GetTrackDepth(reaper.GetTrack(0, i - 1)) == 0 then
            top[i] = true
        end
    end
    return top
end

local function get_siblings(tracks)
    local siblings = {}
    for idx in pairs(tracks) do

        local tr = reaper.GetTrack(0, idx - 1)
        local sibling_depth = reaper.GetTrackDepth(tr)

        if sibling_depth > 0 then
            local parent = reaper.GetParentTrack(tr)

            local children = get_children({
                [reaper.GetMediaTrackInfo_Value(parent, "IP_TRACKNUMBER")] = true
            })
            for child_idx in pairs(children) do

                -- Can't use siblings[idx] = ___ here because we don't want to set existing
                -- siblings to false
                if reaper.GetTrackDepth(reaper.GetTrack(0, child_idx - 1)) == sibling_depth then
                    siblings[child_idx] = true
                end
            end
        else
            -- Find all top-level tracks
            siblings = merge_tables(siblings, get_top_level_tracks())
        end
    end
    return siblings
end

local function get_tracks_to_sel(settings)
    --[[
     settings = {
      search = str,

      matchmultiple = bool,
      matchonlytop = bool,
      selchildren = bool,
      selparents = bool,

      mcp = bool,
      tcp = bool
     }
    ]] --
    local matches = {}

    -- Find all matches
    for i = 1, reaper.CountTracks(0) do

        local tr = reaper.GetTrack(0, i - 1)
        local _, name = reaper.GetTrackName(tr, "")
        local idx = math.floor(reaper.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER"))
        local ischild = reaper.GetTrackDepth(tr) > 0

        if is_match(settings.search, name, idx) and not (ischild and settings.matchonlytop) then
            matches[idx] = true
            if not settings.matchmultiple then
                break
            end
        end
    end
    -- Hacky way to check if length of a hash table == 0
    for k in pairs(matches) do
        if not k then
            return {}
        end
    end

    local parents = settings.selparents and get_parents(matches)
    local children = settings.selchildren and get_children(matches)
    local siblings = settings.selsiblings and get_siblings(matches)

    return merge_tables(matches, parents, children, siblings)
end

local function set_selection(tracks, settings)
    if not tracks then
        return
    end
    -- if not tracks or #tracks == 0 then return end

    for i = 1, reaper.CountTracks(0) do

        local tr = reaper.GetTrack(0, i - 1)
        local keep = settings.add_selection and reaper.IsTrackSelected(tr)
        reaper.SetTrackSelected(tr, not not (tracks[i] or keep))
    end
    reaper.TrackList_AdjustWindows(false)
end

function timbert.selectTrack(trackName)
    local tracks = get_tracks_to_sel(trackSelectionSettings(trackName))
    if tracks then
        set_selection(tracks, settings)
        return
    end
end

--[[Track selection functions ends here]]

function timbert.moveTimeSelectionToCursor()
    local start_time, end_time = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    if start_time == end_time then
        return
    end
    local length = end_time - start_time
    local cursor = reaper.GetCursorPosition()
    reaper.GetSet_LoopTimeRange(true, false, cursor, cursor + length, false)
end

function timbert.moveEditCursor_LeftByTimeSelLength(proj, invert) -- PPP_EditCur_MoveLeftByTimeSelLen converted into lua
    local ts_beg, ts_end, ts_len
    local ec_pos = reaper.GetCursorPositionEx(proj)
    ts_beg, ts_end = reaper.GetSet_LoopTimeRange2(proj, 0, 0, ts_beg, ts_end, 0)
    ts_len = ts_end - ts_beg

    if (invert == nil or invert == false) then
        reaper.SetEditCurPos2(proj, ec_pos - ts_len, 0, 0)
        return
    end
    if (invert == true) then
        reaper.SetEditCurPos2(proj, ec_pos + ts_len, 0, 0)
        return
    end
end

function timbert.smartRecord() -- amagalma_Smart automatic record mode converted into .lua
    local cursorPos
    if reaper.GetPlayState() == 4 then -- Return if already recording
        cursorPos = reaper.GetPlayPosition()
        return
    end
    local timeExists, ItemExists = 0, 0
    cursorPos = reaper.GetCursorPosition()
    local timeStart, timeEnd = reaper.GetSet_LoopTimeRange(0, 0, timeStart, timeEnd, 0)
    if (timeStart ~= timeEnd and timeStart >= cursorPos) then
        timeExists = 1
    end

    local itemStart
    if reaper.CountSelectedMediaItems(0) > 0 then
        local item = reaper.GetSelectedMediaItem(0, 0)
        itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        if itemStart >= cursorPos then
            ItemExists = 1
        end
    end

    if timeExists ~= 1 then
        reaper.Main_OnCommand(40252, 0) -- Set record mode to normal
        reaper.Main_OnCommand(40046, 0) -- Transport: Start/stop recording at edit cursor
        return
    end
    if ItemExists ~= 1 then
        reaper.Main_OnCommand(40076, 0) -- Set record mode to time auto-punch
        reaper.Main_OnCommand(40046, 0) -- Transport: Start/stop recording at edit cursor
        return
    end
    if itemStart < timeStart then
        reaper.Main_OnCommand(40076, 0) -- Set record mode to time auto-punch
        reaper.Main_OnCommand(40046, 0) -- Transport: Start/stop recording at edit cursor
        return
    end
    reaper.Main_OnCommand(40253, 0) -- Set record mode to item auto-punch
    reaper.Main_OnCommand(40046, 0) -- Transport: Start/stop recording at edit cursor
end

function timbert.getGuideTrackInfo()
    reaper.PreventUIRefresh(1)
    local isGuideTrackInfo = true
    timbert.swsCommand("_SWS_SAVESEL") -- Save current track selection
    timbert.swsCommand("_SWS_SAVESELITEMS1") -- Save selected track's selected item(s)
    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of all items)
    timbert.selectTrack("Guide") -- Select Guide track exclusively
    timbert.swsCommand("_XENAKIOS_SELITEMSUNDEDCURSELTX") -- _XENAKIOS_SELITEMSUNDEDCURSELTX

    if reaper.CountSelectedMediaItems(0) ~= 1 then
        isGuideTrackInfo = false
        timbert.swsCommand("_SWS_RESTORESEL") -- Restore track selection
        timbert.swsCommand("_SWS_RESTSELITEMS1") -- Restore current track's selected item(s)
        -- timbert.dbg(isGuideTrackInfo)
        return isGuideTrackInfo
    end

    timbert.storeNotes()
    timbert.swsCommand("_SWS_SAVESELITEMS1") -- Store the Guide Track item selection to get recalled after this function using selectStoredGuideTrackItem()
    timbert.swsCommand("_SWS_RESTORESEL") -- SWS: Toggle between current and saved track selection
    isGuideTrackInfo = true
    -- timbert.dbg(isGuideTrackInfo)
    reaper.PreventUIRefresh(-1)
    return isGuideTrackInfo
end

function timbert.selectStoredGuideTrackItem()
    reaper.PreventUIRefresh(1)
    timbert.swsCommand("_SWS_SAVESEL") -- Save current track selection
    timbert.selectTrack("Guide")
    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of all items)
    timbert.swsCommand("_SWS_RESTSELITEMS1") -- Restore Guide Track item selection
    timbert.swsCommand("_SWS_RESTORESEL") -- Restore track selection
    reaper.PreventUIRefresh(-1)
end

function timbert.colorStoredGuideSegment(color, validationTag)
    timbert.swsCommand("_SWS_SAVESEL") -- Save current track selection
    timbert.selectTrack("Guide")
    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of all items)
    timbert.swsCommand("_SWS_RESTSELITEMS1") -- Restore Guide Track item selection
    timbert.swsCommand("_SWS_RESTSELITEMS1") -- Restore current track's selected item(s)
    timbert.swsCommand("_SWS_ITEMCUSTCOL" .. color) -- SWS: Set selected take(s) to custom color
    local item = reaper.GetSelectedMediaItem(0, 0)
    reaper.GetSetMediaItemInfo_String(item, "P_EXT:VASC_Validation", validationTag, true)
    timbert.swsCommand("_SWS_RESTORESEL") -- Restore track selection
end

function timbert.MakeItemArrayByLaneIndex()
    -- all selected items must be on the same track
    local itemArray, laneIndexes = {}, {}
    local item, itemLane, lastLane
    if reaper.CountSelectedMediaItems(0) == 0 then
        return
    end
    -- timbert.dbg("Item Count: "..reaper.CountSelectedMediaItems( 0 ))
    for i = 1, reaper.CountSelectedMediaItems(0) do
        item = reaper.GetSelectedMediaItem(0, i - 1)
        itemLane = reaper.GetMediaItemInfo_Value(item, "I_FIXEDLANE")
        itemArray[itemLane] = item
        laneIndexes[i] = itemLane

        if i == 1 then
            lastLane = itemLane
        else
            if itemLane > lastLane then
                lastLane = itemLane
            end
        end
    end
    table.sort(laneIndexes)
    return itemArray, lastLane, laneIndexes
end

function timbert.GetTableLength(table)
    local length = 0
    for n in pairs(table) do
        length = length + 1
    end
    return length
end

function timbert.MakeItemArraySortByLane()
    if reaper.CountSelectedMediaItems(0) == 0 then
        return
    end
    local lastLane, item, laneIndex
    local items = {}

    for i = 1, reaper.CountSelectedMediaItems(0) do
        item = reaper.GetSelectedMediaItem(0, i - 1)
        laneIndex = reaper.GetMediaItemInfo_Value(item, "I_FIXEDLANE")
        table.insert(items, {
            item = item,
            laneIndex = laneIndex
        })

        if i == 1 then
            lastLane = laneIndex
        else
            if laneIndex > lastLane then
                lastLane = laneIndex
            end
        end
    end

    table.sort(items, function(a, b)
        return a.laneIndex < b.laneIndex
    end)
    return items, lastLane
end

function timbert.GetActiveTrackLane(track, isFirst)
    local isFirst = isFirst or false
    local activeTrackLane
    local trackLaneAmount = reaper.GetMediaTrackInfo_Value(track, "I_NUMFIXEDLANES")

    if trackLaneAmount == 0 then
        return nil
    end

    for i = 0, trackLaneAmount - 1 do
        if isFirst == false and reaper.GetMediaTrackInfo_Value(track, "C_LANEPLAYS:" .. tostring(i)) ~= 0 then
            activeTrackLane = i
        end
        if isFirst == true and reaper.GetMediaTrackInfo_Value(track, "C_LANEPLAYS:" .. tostring(i)) ~= 0 then
            activeTrackLane = i
            break
        end
    end
    return activeTrackLane
end

function timbert.GetKeyOfValueInTable(table, value)
    local key
    for k, v in pairs(table) do
        if v == value then
            key = k
            break
        end
    end
    return key
end

function timbert.FindIndex(table, value) -- for simple arrays
    local index
    for i = 1, #table do
        if table[i] == value then
            index = i
            break
        end
    end
    return index
end

function timbert.GetKeysArray(table)
    local keyset = {}
    local n = 0

    for k, v in pairs(table) do
        n = n + 1
        keyset[n] = k
    end
    return keyset
end

function timbert.GetSelectedItemsInLaneInfo(laneIndex)
    if reaper.CountSelectedTracks(0) == 0 then
        timbert.msg("Please select a track first", "TImbert Lua Utilities")
        return
    end
    if reaper.CountSelectedMediaItems(0) == 0 then
        timbert.msg("Please select items first", "TImbert Lua Utilities")
        return
    end

    local item, itemLength, itemPosition
    local items = {}
    for i = 1, reaper.CountSelectedMediaItems(0) do
        item = reaper.GetSelectedMediaItem(0, i - 1)
        if reaper.GetMediaItemInfo_Value(item, "I_FIXEDLANE") == laneIndex then
            itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            itemPosition = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            table.insert(items, {
                item = item,
                itemLength = itemLength,
                itemPosition = itemPosition
            })
        end
    end
    table.sort(items, function(a, b)
        return a.itemPosition < b.itemPosition
    end)
    return items
end

function timbert.PreviewMultipleItems(items, track, isSourceDeleted, getLength)
    local itemLength = nil
    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
    local originPosition = items[1].itemPosition
    -- timbert.msg("Position : "..originPosition)
    local originLane = reaper.GetMediaItemInfo_Value(items[1].item, "I_FIXEDLANE")
    for i = 1, #items do
        reaper.SetMediaItemSelected(items[i].item, true)
    end
    reaper.Main_OnCommand(40698, 0) -- Edit: Copy items
    reaper.Main_OnCommand(42432, 0) -- Item: Glue items within time selection
    if getLength then
        itemLength = reaper.GetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0, 0), "D_LENGTH")
    end
    timbert.swsCommand("_SWS_PREVIEWTRACK") -- Xenakios/SWS: Preview selected media item through track

    if isSourceDeleted then
        timbert.swsCommand("_S&M_DELTAKEANDFILE2") -- SWS/S&M: Delete selected items' takes and source files (no undo)
    else
        reaper.DeleteTrackMediaItem(track, reaper.GetSelectedMediaItem(0, 0))
    end

    reaper.Main_OnCommand(40042, 0) -- Transport: Go to start of project
    reaper.MoveEditCursor(originPosition, false)
    reaper.Main_OnCommand(42398, 0) -- Item: Paste items/tracks
    items = timbert.MakeItemArraySortByLane()
    for i = 1, #items do
        reaper.SetMediaItemInfo_Value(items[i].item, "I_FIXEDLANE", originLane)
    end

    if itemLength ~= nil then
        return itemLength
    end
end

function timbert.GetCompLanes(items, track) -- items[i].laneIndex must exist, items created with timbert.MakeItemArraySortByLane() 
    local hasCompLane = false
    local laneName, _
    local compLanes = {}
    -- Identify if a Lane is a Comping lane (containing multiple items generally) by name starting with "C"
    for i = 1, #items do
        _, laneName = reaper.GetSetMediaTrackInfo_String(track, "P_LANENAME:" .. tostring(items[i].laneIndex),
            "laneName", false)
        if string.find(laneName, "C") == 1 then
            table.insert(compLanes, items[i].laneIndex)
        end
    end
    if #compLanes >= 1 then
        hasCompLane = true
    end
    return hasCompLane, compLanes
end

function timbert.ValidateLanesPreviewScriptsSetup(script_name)
    if reaper.CountSelectedTracks(0) == 0 then
        timbert.msg("Please select a track first", script_name)
        return
    end

    if reaper.CountSelectedTracks(0) > 1 then
        timbert.msg("Please only select one track", script_name)
        return
    end

    local track = reaper.GetSelectedTrack(0, 0)
    -- Return if fixed Lanes isn't enable on selected track
    if reaper.GetMediaTrackInfo_Value(track, "I_FREEMODE") ~= 2 then
        timbert.msg(
            "Fixed item lanes isn't enable on selected track, right click on it or go to Track Menu to enable it",
            script_name)
        return
    end

    timbert.swsCommand("_BR_SAVE_CURSOR_POS_SLOT_1")
    timbert.swsCommand("_SWS_SAVETIME1")

    timbert.swsCommand("_XENAKIOS_SELITEMSUNDEDCURSELTX") -- Xenakios/SWS: Select items under edit cursor on selected tracks
    reaper.Main_OnCommand(40290, 0) -- Time selection: Set time selection to items
    reaper.Main_OnCommand(40718, 0) -- Item: Select all items on selected tracks in current time selection
    if reaper.CountSelectedMediaItems(0) < 1 then
        timbert.msg("Please place your cursor on items first", script_name)
        return
    end
    return track
end

function timbert.SelectOnlyFirstItemPerLaneInSelection(items)
    if #items < 2 then
        return items
    end
    local indexesToRemove = {}
    for i = 2, #items do
        if items[i].laneIndex == items[i - 1].laneIndex and reaper.GetMediaItemInfo_Value(items[i].item, "D_POSITION") >
            reaper.GetMediaItemInfo_Value(items[i - 1].item, "D_POSITION") then
            table.insert(indexesToRemove, i)
        end
    end
    for i = #indexesToRemove, 1, -1 do
        table.remove(items, indexesToRemove[i])
    end
    return items
end

function timbert.PreviewLaneContent(track, laneIndex)
    local items = timbert.GetSelectedItemsInLaneInfo(laneIndex)
    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
    -- if comp lane has multiple items, glue on a temporary lane, preview then remove glued item + lane
    if #items > 1 then
        local start_time, end_time = reaper.GetSet_ArrangeView2(0, false, 0, 0)
        timbert.PreviewMultipleItems(items, track, false)
        reaper.GetSet_ArrangeView2(0, true, 0, 0, start_time, end_time)
    else
        reaper.SetMediaItemSelected(items[1].item, true)
        timbert.swsCommand("_SWS_PREVIEWTRACK") -- Xenakios/SWS: Preview selected media item through track
    end
end