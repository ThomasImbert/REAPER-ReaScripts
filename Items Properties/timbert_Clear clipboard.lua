-- @about Simply clears the current content of the clipboard
-- @description Clear clipboard
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @version 1.0 
-- @author Thomas Imbert
-- @changelog
--   # Initial Release (2022-02-13)

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

reaper.CF_SetClipboard( "" ) -- Empty the clipboard

reaper.UpdateArrange()

reaper.Undo_EndBlock("Clear clipboard", - 1) -- End of the undo block. Leave it at the bottom of your main function.

reaper.PreventUIRefresh(-1)
