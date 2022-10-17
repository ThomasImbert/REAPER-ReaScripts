-- @description TImbert Lua Utilities
-- @author Thomas Imbert
-- @version 1.0
-- @metapackage
-- @provides
--   [main] .
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about
--   # Lua Utilities
-- @changelog
--   # Initial Release

--[[

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath()..'/scripts/timbert Scripts/Development/timbert_Lua Utilities.lua'
if reaper.file_exists( timbert_LuaUtils ) then dofile( timbert_LuaUtils ); if not timbert or timbert.version() < 4.4 then timbert.msg('This script requires a newer version of timbert Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"timbert Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires timbert Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'timbert Lua Utilities'"); return end


]]


timbert = {}

function timbert.version()
  local file = io.open((reaper.GetResourcePath()..'/scripts/Thomas Imbert/Development/timbert_Lua Utilities.lua'):gsub('\\','/'),"r")
  local vers_header = "-- @version "
  io.input(file)
  local t = 0
  for line in io.lines() do
    if line:find(vers_header) then
      t = line:gsub(vers_header,"")
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
  if ret == 1 then return true else return false end
end

function timbert.storeNotes()
	if reaper.CountSelectedMediaItems( 0 ) > 0 then -- Check that an item is selected
		local selItem = reaper.GetSelectedMediaItem( 0 , 0 )
		local itemNotes = ""
		local boolean, itemNotes = reaper.GetSetMediaItemInfo_String(selItem , "P_NOTES", itemNotes, false)
		reaper.DeleteExtState( "vascReaper", "vascNotes", false )
		reaper.SetProjExtState( 0, "vascReaper", "vascNotes", tostring(itemNotes)) 
	end 
end

function timbert.pasteNotes()     
	if reaper.CountSelectedMediaItems( 0 ) > 0 then -- Check that an item is selected
		local selItem = reaper.GetSelectedMediaItem( 0 , 0 )
		retval, itemNotes = reaper.GetProjExtState( 0, "vascReaper", "vascNotes")
		reaper.GetSetMediaItemInfo_String(selItem , "P_NOTES", itemNotes, true)
	end
end

--[[Track selection functions starts here]]
-- This script was generated by Lokasenna_Select tracks by name.lua

local function trackSelectionSettings(trackName) -- call this function to setup settings
	if trackName == "Guide" then
	settings = {
	  matchmultiple = false,
	  search = "GUIDE",
	  selchildren = false,
	  selparents = false,
	  selsiblings = false,
	  matchonlytop = false,
	}
	end
	if trackName == "Alt" then
	settings = {
	  selparents = false,
	  search = "ALT",
	  selchildren = true,
	  matchonlytop = false,
	  selsiblings = false,
	  add_selection = true,
	  matchmultiple = false,
	}
	end
end 

-- local info = debug.getinfo(1,'S');
-- script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
-- local script_filename = ({reaper.get_action_context()})[2]:match("([^/\\]+)$")
-- 
-- Search Functions --

-- Returns true if the individual words of str_b all appear in str_a
local function fuzzy_match(str_a, str_b)

    if not (str_a and str_b) then return end
    str_a, str_b = string.lower(tostring(str_a)), string.lower(tostring(str_b))

    --Msg("\nfuzzy match, looking for:\n\t" .. str_b .. "\nin:\n\t" .. str_a .. "\n")

    for word in string.gmatch(str_b, "[^%s]+") do
	   --Msg( tostring(word) .. ": " .. tostring( string.match(str_a, word) ) )
	   if not string.match(str_a, word) then return end
    end
    return true
end

local function is_match(str, tr_name, tr_idx)
    if str:sub(1, 1) == "#" then
	   -- Force an integer until/unless I come up with some sort of multiple track syntax
	   str = tonumber(str:sub(2, -1))
	   return str and (math.floor( tonumber(str) ) == tr_idx)

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
			 if v then ret[k] = v end
		  end
	   end
    end

    return ret

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
    ]]--
    local matches = {}

    -- Find all matches
    for i = 1, reaper.CountTracks(0) do

	   local tr = reaper.GetTrack(0, i - 1)
	   local _, name = reaper.GetTrackName(tr, "")
	   local idx = math.floor( reaper.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER") )
	   local ischild = reaper.GetTrackDepth(tr) > 0

	   if is_match(settings.search, name, idx) and not (ischild and settings.matchonlytop) then
		  matches[idx] = true
		  if not settings.matchmultiple then break end
	   end
    end
    -- Hacky way to check if length of a hash table == 0
    for k in pairs(matches) do
	   if not k then return {} end
    end

    return merge_tables(matches)
end

local function set_selection(tracks, settings)
    if not tracks then return end
    --if not tracks or #tracks == 0 then return end

    for i = 1, reaper.CountTracks(0) do

	   local tr = reaper.GetTrack(0, i - 1)
	   local keep = settings.add_selection and reaper.IsTrackSelected(tr)
	   reaper.SetTrackSelected(tr, not not (tracks[i] or keep))
    end
    reaper.TrackList_AdjustWindows(false)
end

function timbert.selectTrack(trackName)
	trackSelectionSettings(selectTrack.trackName)
	local tracks = get_tracks_to_sel(settings)
	if tracks then
		set_selection( tracks, settings )
		return
	end
end

--[[Track selection functions ends here]]