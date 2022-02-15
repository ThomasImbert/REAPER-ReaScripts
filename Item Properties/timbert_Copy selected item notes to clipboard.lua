-- @description Copy selected item notes to clipboard
-- @author Thomas Imbert
-- @version 1.0 
-- @metapackage
-- @provides
--   [main] . > timbert_Copy selected item notes to clipboard.lua
-- @link 
-- @about 
-- @changelog
--   # Initial Release (2022-02-13)

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

reaper.CF_SetClipboard( "" ) -- Prepare clipboard by clearing its content

if reaper.CountSelectedMediaItems( 0 ) > 0 then -- Check that an item is selected
	local selItem = reaper.GetSelectedMediaItem( 0 , 0 )
	
	local itemNotes = ""

	hasText, itemNotes = reaper.GetSetMediaItemInfo_String(selItem , "P_NOTES", itemNotes, false)
	reaper.CF_SetClipboard( itemNotes ) -- Copy itemNotes to clipboard
end

reaper.UpdateArrange()

reaper.Undo_EndBlock("Copy selected item notes to clipboard", - 1) -- End of the undo block. Leave it at the bottom of your main function.

reaper.PreventUIRefresh(-1)
