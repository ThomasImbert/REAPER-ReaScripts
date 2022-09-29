-- @description Move all takes but one (under mouse cursor) to Alt tracks and assemble in one file
-- @author Thomas Imbert
-- @version 1.0
-- @about
--      To be used with an Alt folder track like the template provided in my "timbert_VASC_AltFolder_default.RTrackTemplate".
--
--		Select all the items of the same dialog take before using this script AND place the mouse cursor on your favorite take. The takes will be automatically organized vertically and move to the Alt takes folder, with the favorite take on the top track colored in SWS custom color 01.
--
--		Note that this version of the script glues the takes together in the process to allow for a ProTools like punch record, found in my cycle actions "Record Punch PT Like" and "VASC Record Punch PT Like"
--
--		This script was generated using Lokasenna's "Generate script from custom action" and uses many actions found in various repositories, details found here "https://github.com/ThomasImbert/REAPER-ReaScripts/blob/master/README.md"
-- @changelog
--   #Initial Release

local function main()
  reaper.PreventUIRefresh(1)
  reaper.Undo_BeginBlock()

  reaper.Main_OnCommand(54564, 0)
  reaper.Main_OnCommand(53168, 0)
  reaper.Main_OnCommand(40513, 0)
  reaper.Main_OnCommand(54562, 0)
  reaper.Main_OnCommand(40297, 0)
  reaper.Main_OnCommand(55865, 0)
  reaper.Main_OnCommand(53787, 0)
  reaper.Main_OnCommand(40290, 0)
  reaper.Main_OnCommand(55841, 0)
  reaper.Main_OnCommand(55916, 0)
  reaper.Main_OnCommand(40931, 0)
  reaper.Main_OnCommand(40420, 0)
  reaper.Main_OnCommand(54563, 0)
  reaper.Main_OnCommand(54578, 0)
  reaper.Main_OnCommand(40289, 0)
  reaper.Main_OnCommand(53479, 0)
  reaper.Main_OnCommand(53084, 0)
  reaper.Main_OnCommand(54579, 0)
  reaper.Main_OnCommand(57718, 0)
  reaper.Main_OnCommand(53788, 0)
  reaper.Main_OnCommand(53790, 0)
  reaper.Main_OnCommand(53682, 0)
  reaper.Main_OnCommand(57712, 0)
  reaper.Main_OnCommand(55866, 0)
  reaper.Main_OnCommand(40625, 0)
  reaper.Main_OnCommand(40718, 0)
  reaper.Main_OnCommand(40297, 0)
  reaper.Main_OnCommand(58374, 0)
  reaper.Main_OnCommand(55867, 0)
  reaper.Main_OnCommand(55868, 0)
  reaper.Main_OnCommand(55869, 0)
  reaper.Main_OnCommand(55840, 0)
  reaper.Main_OnCommand(54579, 0)
  reaper.Main_OnCommand(53303, 0)
  reaper.Main_OnCommand(53178, 0)
  reaper.Main_OnCommand(54580, 0)

  reaper.Undo_EndBlock('Move all takes but one (under mouse cursor) to Alt tracks and assemble in one file', 0)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.UpdateTimeline()
end

main()