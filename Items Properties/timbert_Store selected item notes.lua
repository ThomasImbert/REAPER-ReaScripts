-- @description Stores the selected item's notes
-- @author Thomas Imbert
-- @version 1.0
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about Copies the content of the notes from a single item into ProjExtState "vascReaper" "vascNotes".
-- @changelog
--   # Initial Release (2022-10-13)

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

if reaper.CountSelectedMediaItems( 0 ) > 0 then -- Check that an item is selected
	local selItem = reaper.GetSelectedMediaItem( 0 , 0 )
	local itemNotes = ""
	local boolean, itemNotes = reaper.GetSetMediaItemInfo_String(selItem , "P_NOTES", itemNotes, false)
	reaper.DeleteExtState( "vascReaper", "vascNotes", false )
	reaper.SetProjExtState( 0, "vascReaper", "vascNotes", tostring(itemNotes)) 
end 

reaper.UpdateArrange()

reaper.Undo_EndBlock("Store selected item notes", - 1) -- End of the undo block. Leave it at the bottom of your main function.

reaper.PreventUIRefresh(-1)
