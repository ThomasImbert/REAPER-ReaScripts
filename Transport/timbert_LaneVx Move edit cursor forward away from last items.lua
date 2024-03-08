-- @description LaneVx Move edit cursor forward away from last items
-- @author Thomas Imbert
-- @version 1.0pre1
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about Moves the edit cursor forward away from last block of items / take
-- @changelog 
--   # intial release

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath()..'/scripts/TImbert Scripts/Development/timbert_Lua Utilities.lua'
if reaper.file_exists( timbert_LuaUtils ) then dofile( timbert_LuaUtils ); if not timbert or timbert.version() < 1.9 then timbert.msg('This script requires a newer version of TImbert Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"TImbert Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires TImbert Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'TImbert Lua Utilities'"); return end


function main()
	timbert.swsCommand("_XENAKIOS_SELITEMSUNDEDCURSELTX")-- Xenakios/SWS: Select items under edit cursor on selected tracks
	reaper.Main_OnCommand(41174, 0) -- Item navigation: Move cursor to end of items
	reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
	reaper.Main_OnCommand(41042, 0) -- Move edit cursor forward one measure
	-- ADD functionality to go to next item block
end


reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

main() -- call main function 

reaper.UpdateArrange()

reaper.Undo_EndBlock("LaneVx Record with context of previous line's last take", -1 ) -- End of the undo block. Leave it at the bottom of your main function.

reaper.PreventUIRefresh(-1)