-- @description ASWG General iXML Metadata Columns
-- @author Thomas Imbert
-- @version 1.0
-- @about
--      Create metadata columns for ASWG General, Format and Recording Categories in the Media explorer.
--
--      Derived from acendan Soundminer iXML script.
--
--      Find the ASWG iXML specs here: https://github.com/Sony-ASWG/iXML-Extension/blob/main/ASWG-G006%20-%20iXML%20Extension%20Specification%20v1.0.pdf
-- @metapackage
-- @provides
--   [main=mediaexplorer] .
-- @changelog
--   #Initial Release

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Table of iXML Columns
local iXML = {}
iXML["ASWG:contentType"]            = "ASWG-Content"
iXML["ASWG:project"]                = "ASWG-Project"
iXML["ASWG:originator"]             = "ASWG-Designer"
iXML["ASWG:originatorStudio"]       = "ASWG-DesignStudio"
iXML["ASWG:notes"]                  = "ASWG-Notes"
iXML["ASWG:session"]                = "SessionName"
iXML["ASWG:state"]                  = "FileState"
iXML["ASWG:editor"]                 = "ASWG-Editor"
iXML["ASWG:mixer"]                  = "ASWG-Mixer"
iXML["ASWG:fxChainName"]            = "fxChain"
iXML["ASWG:channelConfig"]          = "ChanConfig"
iXML["ASWG:ambisonicFormat"]        = "AmbiFormat"
iXML["ASWG:ambisonicChnOrder"]      = "AmbiChanOrder"
iXML["ASWG:ambisonicNorm"]          = "AmbiNorm"
iXML["ASWG:micType"]                = "ASWG-Mic"
iXML["ASWG:micConfig"]              = "ASWG-MicConfig"
iXML["ASWG:micDistance"]            = "ASWG-MicDistance"
iXML["ASWG:recordingLoc"]           = "ASWG-RecLocation"
iXML["ASWG:isDesigned"]             = "isDesigned"
iXML["ASWG:recEngineer"]            = "ASWG-RecEngineer"
iXML["ASWG:recStudio"]              = "ASWG-RecStudio"
iXML["ASWG:impulseLocation"]        = "ASWG-IRLocation"

-- Other globals
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))
local ini_section = "reaper_explorer"
local dbg = false

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()
  local reaper_version = tonumber(reaper.GetAppVersion():sub(1,4))
  if reaper_version >= 6.29 then
    AddIXML()
  else
    -- ~~~~~~~~~ PRE-RELEASE BUILDS ONLY
    if dbg then AddIXML() else
    -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    reaper.MB("This script requires Reaper v6.29 or greater! Please update Reaper.","ERROR: Update Reaper!",0) end
  end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Adds the IXML columns to the Media Explorer
function AddIXML()
  local ini_file = reaper.get_ini_file()
  local i = 0
  repeat 
    -- Check .ini file for custom user columns
    local ret,val = reaper.BR_Win32_GetPrivateProfileString(ini_section,"user" .. tostring(i) .. "_key","",ini_file)
    -- Check if custom user column is already in table
    if tableContainsKey(iXML,val) then
      if dbg then reaper.ShowConsoleMsg("Found existing entry for: " .. iXML[val] .. "\n") end
      iXML[val] = nil
    end
    i = i+1
  until ret == 0
  
  i = i-1
  
  -- Loop through iXML metadata table  
  if tableLength(iXML) > 0 then 
    for k, v in pairs(iXML) do
      local ret = reaper.BR_Win32_WritePrivateProfileString(ini_section,"user" .. tostring(i) .. "_key",k,ini_file)
      local ret2 = reaper.BR_Win32_WritePrivateProfileString(ini_section,"user" .. tostring(i) .. "_desc",v,ini_file)
      if ret and ret2 then 
        if dbg then reaper.ShowConsoleMsg("Succesfully added entry: " .. k .. " - " .. v .. "\n") end
      else
        reaper.ShowConsoleMsg("ERROR! Failed to add entry: " .. k .. " - " .. v .. "\n")
      end
      i = i + 1
    end
    
    -- Force refresh the media explorer
    reaper.Main_OnCommand(50124,0) -- Show/hide media explorer
    reaper.Main_OnCommand(50124,0) -- Show/hide media explorer
    reaper.OpenMediaExplorer("",false)
    
    reaper.MB("Succesfully updated Media Explorer metadata columns!\n\nTo populate new columns: select your file(s), right click, and run 'Re-read metadata from media'.","Media Explorer Metadata",0)
  else
    -- Force refresh the media explorer
    reaper.Main_OnCommand(50124,0) -- Show/hide media explorer
    reaper.Main_OnCommand(50124,0) -- Show/hide media explorer
    reaper.OpenMediaExplorer("",false)
    
    reaper.MB("All ASWG General iXML metadata columns are already set up!\n\nIf you don't see them, try right clicking on a Media Explorer column and checking whether your User Columns at the bottom of the menu are enabled/visible.","Media Explorer Metadata",0)
  end
end

-- Check if a table contains a key // returns Boolean
function tableContainsKey(table, key)
    return table[key] ~= nil
end

-- Get table length for non numeric keys (unlike # or table.getn function)
function tableLength(table)
  local i = 0
  for _ in pairs(table) do i = i + 1 end
  return i
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()

