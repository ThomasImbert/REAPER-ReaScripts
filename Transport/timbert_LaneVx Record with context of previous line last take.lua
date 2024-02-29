-- @description LaneVx Record with context of previous line's last take
-- @author Thomas Imbert
-- @version 1.0
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about Record and immediately preview the previous media item on the same track or in the project.
-- @changelog 
--   # initial release

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath()..'/scripts/Thomas Imbert Scripts/Development/timbert_Lua Utilities.lua'
if reaper.file_exists( timbert_LuaUtils ) then dofile( timbert_LuaUtils ); if not timbert or timbert.version() < 1.9 then timbert.msg('This script requires a newer version of TImbert Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"TImbert Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires TImbert Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'TImbert Lua Utilities'"); return end

function main()
	reaper.Main_OnCommand(40416, 0) -- Item navigation: Select and move to previous item 
	timbert.swsCommand("_XENAKIOS_SELITEMSUNDEDCURSELTX")  -- Xenakios/SWS: Select items under edit cursor on selected tracks
	reaper.Main_OnCommand(40290, 0) -- Time selection: Set time selection to items 
	timbert.swsCommand("_SWS_SAVETIME1")
	reaper.SetMediaItemSelected( reaper.GetSelectedMediaItem( 0, reaper.CountSelectedMediaItems( 0 ) -1 ), true )  -- select only last selected items
	reaper.Main_OnCommand(40290, 0) -- Time selection: Set time selection to items 
	timbert.swsCommand("_SWS_SAVETIME2")
	timbert.swsCommand("_SWS_PREVIEWTRACK") -- Xenakios/SWS: Preview selected media item through track
	timbert.swsCommand("_SWS_RESTTIME1") -- Restore time selection as long as the longest lane take
	timbert.moveEditCursor_LeftByTimeSelLength(0,true)  -- Move right by that time selection length
	reaper.Main_OnCommand(40682, 32060) -- Navigate: Move edit cursor right one measure
	timbert.moveTimeSelectionToCursor()
	timbert.swsCommand("_SWS_SAVETIME1")
	timbert.swsCommand("_SWS_RESTTIME2") -- restore time selection of length = last line's lane
	timbert.moveEditCursor_LeftByTimeSelLength(0,true) 
	timbert.swsCommand("_SWS_RESTTIME1")
	reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of all items)
	timbert.smartRecord()
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

main() -- call main function 

reaper.UpdateArrange()

reaper.Undo_EndBlock("LaneVx Record with context of previous line's last take", -1 ) -- End of the undo block. Leave it at the bottom of your main function.

reaper.PreventUIRefresh(-1)