-- @description Move all but first takes to Alt tracks and assemble in one file
-- @author Thomas Imbert
-- @version 1.0
-- @about
--      To be used with an Alt folder track like the template provided in my "timbert_VASC_AltFolder_default.RTrackTemplate".
--
--		Select all the items of the same dialog take before using this script. The takes will be automatically organized vertically and move to the Alt takes folder.
--
--		Note that this version of the script glues the takes together in the process to allow for a ProTools like punch record, found in my cycle actions "Record Punch PT Like" and "VASC Record Punch PT Like"
--
--		This script was generated using Lokasenna's "Generate script from custom action" and uses many actions found in various repositories, details found here "https://github.com/ThomasImbert/REAPER-ReaScripts/blob/master/README.md"
-- @metapackage
-- @provides
--   [main=mediaexplorer] .
-- @changelog
--   #Initial Release

local function main()
  reaper.PreventUIRefresh(1)
  reaper.Undo_BeginBlock()

  reaper.Main_OnCommand(54561, 0)
  reaper.Main_OnCommand(53168, 0)
  reaper.Main_OnCommand(40297, 0)
  reaper.Main_OnCommand(55865, 0)
  reaper.Main_OnCommand(40290, 0)
  reaper.Main_OnCommand(55841, 0)
  reaper.Main_OnCommand(55916, 0)
  reaper.Main_OnCommand(40931, 0)
  reaper.Main_OnCommand(40420, 0)
  reaper.Main_OnCommand(54562, 0)
  reaper.Main_OnCommand(55866, 0)
  reaper.Main_OnCommand(40625, 0)
  reaper.Main_OnCommand(40718, 0)
  reaper.Main_OnCommand(40297, 0)
  reaper.Main_OnCommand(58374, 0)
  reaper.Main_OnCommand(55867, 0)
  reaper.Main_OnCommand(55868, 0)
  reaper.Main_OnCommand(55869, 0)
  reaper.Main_OnCommand(55840, 0)
  reaper.Main_OnCommand(54578, 0)
  reaper.Main_OnCommand(53922, 0)
  reaper.Main_OnCommand(53178, 0)
  reaper.Main_OnCommand(54577, 0)

  reaper.Undo_EndBlock('Move all but first takes to Alt tracks and assemble in one file', 0)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.UpdateTimeline()
end

main()