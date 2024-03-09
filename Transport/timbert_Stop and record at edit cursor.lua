-- @description Stop and record at edit cursor
-- @author Thomas Imbert
-- @version 1.0
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about Records at edit cursor wether reaper is already recording or not.
-- @changelog 
--   # intial release

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

function main()
	reaper.Main_OnCommand(1016, 0) -- Transport: Stop
	reaper.Main_OnCommand(1013, 0) -- Transport: Record
end


reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block.

main()

reaper.UpdateArrange()

reaper.Undo_EndBlock(script_name, -1 ) -- End of the undo block.

reaper.PreventUIRefresh(-1)