-- @description Clear clipboard
-- @author Thomas Imbert
-- @version 1.0 
-- @metapackage
-- @provides
--   [main] . > timbert_Clear clipboard.lua
-- @link 
-- @about 
-- @changelog
--   # Initial Release (2022-02-13)

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

reaper.CF_SetClipboard( "" ) -- Empty the clipboard

reaper.UpdateArrange()

reaper.Undo_EndBlock("Clear clipboard", - 1) -- End of the undo block. Leave it at the bottom of your main function.

reaper.PreventUIRefresh(-1)
