-- @description VASC Record with context of previous line
-- @author Thomas Imbert
-- @version 1.2
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about Record and immediately preview the previous media item on the same track or in the project.
-- @changelog 
--   # Fixed Alt takes previewing and removed remaining clutter

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath()..'/scripts/Thomas Imbert/Development/timbert_Lua Utilities.lua'
if reaper.file_exists( timbert_LuaUtils ) then dofile( timbert_LuaUtils ); if not timbert or timbert.version() < 1.4 then timbert.msg('This script requires a newer version of TImbert Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"TImbert Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires TImbert Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'TImbert Lua Utilities'"); return end

function main()
	timbert.swsCommand("_SWS_SAVETIME1")
	timbert.swsCommand("_BR_SAVE_CURSOR_POS_SLOT_1")
	timbert.getGuideTrackInfo()
	timbert.selectTrack("Guide")
	timbert.selectTrack("Alt")
	timbert.swsCommand("_SWS_TOGTRACKSEL")
	reaper.Main_OnCommand(40416, 0) -- Item navigation: Select and move to previous item 
	reaper.Main_OnCommand(40290, 0) -- Time selection: Set time selection to items 
	timbert.swsCommand("_SWS_PREVIEWTRACK") -- Xenakios/SWS: Preview selected media item through track
	timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_1") -- SWS/BR: Restore edit cursor position, slot 01 
	timbert.moveTimeSelectionToCursor()
	timbert.moveEditCursor_LeftByTimeSelLength(0) 
	timbert.swsCommand("_SWS_RESTORESEL")
	timbert.swsCommand("_SWS_RESTTIME1")
	reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of all items)
	timbert.smartRecord()
	timbert.swsCommand("_BR_RESTORE_CURSOR_POS_SLOT_1")
	if timbert.getGuideTrackInfo() == true then
		timbert.selectStoredGuideTrackItem()
	end
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

main() -- call main function 

reaper.UpdateArrange()

reaper.Undo_EndBlock("VASC Record with context of previous line", -1 ) -- End of the undo block. Leave it at the bottom of your main function.

reaper.PreventUIRefresh(-1)