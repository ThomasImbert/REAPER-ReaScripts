-- @description VASC Store region position for sync
-- @author Thomas Imbert
-- @version 1.0
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about 
--   Get the region at current cursor position and stores it in Proj Ext State 
--
--   This script is intended to work with VASC web interface and is called from it.  
-- @changelog 
--   # Initial Release (2022-11-03)

local function main() 
    reaper.ShowConsoleMsg("")
    local cursPos = reaper.GetCursorPositionEx( 0 )
    local markeridx, regionidx = reaper.GetLastMarkerAndCurRegion( 0, cursPos )
    retval, isrgn, pos, rgnend, regionName, markrgnindexnumber = reaper.EnumProjectMarkers2( 0, regionidx )
    reaper.SetProjExtState( 0 , "VASC_WebInterface", "SyncRegion", regionName )
    -- reaper.ShowConsoleMsg(regionName)
end

reaper.Undo_BeginBlock()

reaper.PreventUIRefresh(1)

main()

reaper.PreventUIRefresh(-1)

reaper.Undo_EndBlock("VASC Store region position for sync", -1)

reaper.UpdateArrange()
