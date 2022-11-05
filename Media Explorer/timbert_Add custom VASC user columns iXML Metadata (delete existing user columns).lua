-- @description VASC iXML Metadata Columns (delete existing user columns)
-- @author Thomas Imbert
-- @version 1.0
-- @about
--      Create metadata columns for specific VASC and ASWG fields in the Media explorer.
--
--      Derived from acendan Soundminer iXML script
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
iXML["IXML:USER:Embedder"]      = "Embedder"      

iXML["ASWG:session"]            = "Session"
iXML["ASWG:recEngineer"]        = "RecEngineer"
iXML["ASWG:originatorStudio"]   = "Company"
iXML["ASWG:recStudio"]          = "StudioRoom"
iXML["ASWG:micType"]            = "Microphone"
iXML["ASWG:director"]           = "Director"

iXML["ASWG:text"]               = "Text"
iXML["ASWG:efforts"]            = "Efforts"
iXML["ASWG:effortType"]         = "EffortType"
iXML["ASWG:projection"]         = "Projection"
iXML["ASWG:language"]           = "Lang"
iXML["ASWG:timingRestriction"]  = "Timing"
iXML["ASWG:characterName"]      = "CharName"
iXML["ASWG:characterGender"]    = "CharGender"
iXML["ASWG:characterAge"]       = "CharAge"
iXML["ASWG:characterRole"]      = "Role"
iXML["ASWG:actorName"]          = "ActorName"
iXML["ASWG:actorGender"]        = "ActorGender"
iXML["ASWG:direction"]          = "Direction"
iXML["ASWG:fxUsed"]             = "FxUsed"
iXML["ASWG:usageRights"]        = "Rights"
iXML["ASWG:isUnion"]            = "Union"
iXML["ASWG:accent"]             = "Accent"
iXML["ASWG:emotion"]            = "Emotion"
iXML["IXML:USER:AnswerFile"]    = "AnswerFile"    
iXML["IXML:USER:Interlocutor"]  = "Interlocutor"  

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
    -- Delete all user columns! Do back them up!
    local ret,val = reaper.BR_Win32_GetPrivateProfileString(ini_section,"user" .. tostring(i) .. "_key","",ini_file)
    reaper.BR_Win32_WritePrivateProfileString(ini_section,"user" .. tostring(i) .. "_key","",ini_file)
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
    
    reaper.MB("All ASWG Dialog iXML metadata columns are already set up!\n\nIf you don't see them, try right clicking on a Media Explorer column and checking whether your User Columns at the bottom of the menu are enabled/visible.","Media Explorer Metadata",0)
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

