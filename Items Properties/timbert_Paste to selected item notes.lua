-- @about Paste stored content to selected item notes
-- @description Paste stored notes from ProjExtState "vascReaper" "vascNotes" to selected item.
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @version 1.0 
-- @author Thomas Imbert
-- @changelog
--   # Initial Release (2022-10-13)

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

if reaper.CountSelectedMediaItems( 0 ) > 0 then -- Check that an item is selected
	local selItem = reaper.GetSelectedMediaItem( 0 , 0 )
	retval, itemNotes = reaper.GetProjExtState( 0, "vascReaper", "vascNotes")
	reaper.GetSetMediaItemInfo_String(selItem , "P_NOTES", itemNotes, true)
end

reaper.UpdateArrange()

reaper.Undo_EndBlock("Paste stored notes to selected item", - 1) -- End of the undo block. Leave it at the bottom of your main function.

reaper.PreventUIRefresh(-1)
