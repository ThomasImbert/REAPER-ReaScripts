-- @description VASC Record with context of previous line
-- @author Thomas Imbert
-- @version 1.1
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about Record and immediately preview the previous media item on the same track or in the project.
-- @changelog 
--   # Moved functions to timbert_Lua Utilities

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath()..'/scripts/Thomas Imbert/Development/timbert_Lua Utilities.lua'
if reaper.file_exists( timbert_LuaUtils ) then dofile( timbert_LuaUtils ); if not timbert or timbert.version() < 1.1 then timbert.msg('This script requires a newer version of TImbert Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"TImbert Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires TImbert Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'TImbert Lua Utilities'"); return end

-- Record state
-- Get computer specific ID of "_SWS_SAVESEL"
local sws_saveCurrentTrackSelection = reaper.NamedCommandLookup("_SWS_SAVESEL") 
-- Get computer specific ID of "_SWS_RESTORESEL"
local sws_restoreTrackSelection = reaper.NamedCommandLookup("_SWS_RESTORESEL")  
-- Get computer specific ID of "_SWS_SAVEALLSELITEMS1"
local sws_saveSelectedItems = reaper.NamedCommandLookup("_SWS_SAVEALLSELITEMS1") 
-- Get computer specific ID of "_SWS_RESTALLSELITEMS1"
local sws_restoreSelectedItems = reaper.NamedCommandLookup("_SWS_RESTALLSELITEMS1") 
-- Get computer specific ID of "_SWS_SAVETIME1"
local sws_saveTimeSelection01 = reaper.NamedCommandLookup("_SWS_SAVETIME1") 
-- Get computer specific ID of "_SWS_RESTTIME1"
local sws_restoreTimeSelection01 = reaper.NamedCommandLookup("_SWS_RESTTIME1") 
-- Get computer specific ID of "_BR_SAVE_CURSOR_POS_SLOT_1"
local sws_saveCursorPos01 = reaper.NamedCommandLookup("_BR_SAVE_CURSOR_POS_SLOT_1")
-- Get computer specific ID of "_BR_RESTORE_CURSOR_POS_SLOT_1"
local sws_restoreCursorPos01 = reaper.NamedCommandLookup("_BR_RESTORE_CURSOR_POS_SLOT_1") 
-- Get computer specific ID of "_SWS_TOGTRACKSEL"
local sws_invertTrackSelection = reaper.NamedCommandLookup("_SWS_TOGTRACKSEL") 
-- Get computer specific ID of "_SWS_PREVIEWTRACK"
local sws_previewSelectedItemTrack = reaper.NamedCommandLookup("_SWS_PREVIEWTRACK") 

function main()
	reaper.Main_OnCommand(sws_saveTimeSelection01, 0)
	reaper.Main_OnCommand(sws_saveCursorPos01, 0)
	reaper.Main_OnCommand(sws_saveCurrentTrackSelection, 0)
	timbert.selectTrack("Guide")
	reaper.Main_OnCommand(40718, 0) -- Item: Select all items on selected tracks in current time selection
	reaper.Main_OnCommand(sws_saveSelectedItems, 0)
	timbert.selectTrack("Alt")
	reaper.Main_OnCommand(sws_invertTrackSelection, 0)
	reaper.Main_OnCommand(40416, 0) -- Item navigation: Select and move to previous item 
	reaper.Main_OnCommand(40290, 0) -- Time selection: Set time selection to items 
	reaper.Main_OnCommand(sws_previewSelectedItemTrack, 0) -- Xenakios/SWS: Preview selected media item through track
	reaper.Main_OnCommand(sws_restoreCursorPos01, 0) -- SWS/BR: Restore edit cursor position, slot 01 
	timbert.moveTimeSelectionToCursor()
	timbert.moveEditCursor_LeftByTimeSelLength(0) 
	reaper.Main_OnCommand(sws_restoreTrackSelection, 0)
	reaper.Main_OnCommand(sws_restoreTimeSelection01, 0)
	reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of all items)
	-- reaper.Main_OnCommand(1013, 0) -- Transport: Record
	timbert.smartRecord()
	reaper.Main_OnCommand(sws_restoreCursorPos01, 0)
	reaper.Main_OnCommand(sws_restoreSelectedItems, 0)
	timbert.storeNotes()
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

main() -- call main function 

reaper.UpdateArrange()

reaper.Undo_EndBlock("VASC Record with context of previous line", -1 ) -- End of the undo block. Leave it at the bottom of your main function.

reaper.PreventUIRefresh(-1)