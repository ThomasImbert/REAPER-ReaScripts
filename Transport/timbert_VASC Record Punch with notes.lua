-- @description VASC Record Punch PT like with notes
-- @author Thomas Imbert
-- @version 1.2
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about A record punch similar to ProTool's, intended to work with VASC. Copies notes from the Guide track item onto the recorded take.
-- @changelog 
--   # Corrected the command ID for vasc custom scripts

-- #local declarations#

-- Record state
local record_command_state = reaper.GetToggleCommandState(1013) 
-- Get computer specific ID of "SWS: Save Selected track(s) selected item(s), slot 1"
local save_item_slot_1_ID = reaper.NamedCommandLookup("_SWS_SAVESELITEMS1") 
-- Get computer specific ID of "SWS: Restore Selected track(s) selected item(s), slot 1"
local restore_item_slot_1_ID = reaper.NamedCommandLookup("_SWS_RESTSELITEMS1") 
-- Get computer specific ID of "_SWS_SAVESEL"
local sws_saveCurrentTrackSelection = reaper.NamedCommandLookup("_SWS_SAVESEL") 
-- Get computer specific ID of "timbert_VASC Select Guide track exclusively.lua"
local vasc_selectGuideTrack = reaper.NamedCommandLookup("_RS09e4c88661415e92899d61b0602828ac39dd57b0") 
-- Get computer specific ID of "_SWS_RESTORESEL"
local sws_restoreTrackSelection = reaper.NamedCommandLookup("_SWS_RESTORESEL")  
-- Get computer specific ID of "timbert_Store selected item notes.lua"
local vasc_storeItemNotes = reaper.NamedCommandLookup("_RSe0a325343212afb2446fd4aadf4ca7f7aeff0910") 
-- Get computer specific ID of "Script: timbert_Paste to selected item notes.lua"
local vasc_pasteItemNotes = reaper.NamedCommandLookup("_RScd71bd425b4a290215cef09d7a6b49754aaf970d") 
-- Get computer specific ID of "_XENAKIOS_SELITEMSUNDEDCURSELTX"
local sws_selectItems_editCursor_onSelectedTracks = reaper.NamedCommandLookup("_XENAKIOS_SELITEMSUNDEDCURSELTX") 
-- Get computer specific ID of "_SWS_SAVEALLSELITEMS1"
local sws_saveSelectedItems = reaper.NamedCommandLookup("_SWS_SAVEALLSELITEMS1") 
-- Get computer specific ID of "_SWS_RESTALLSELITEMS1"
local sws_restoreSelectedItems = reaper.NamedCommandLookup("_SWS_RESTALLSELITEMS1") 
-- Guide item present
local isGuideItemPresent = true

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

function main()
	reaper.Main_OnCommand(sws_saveCurrentTrackSelection, 0)
	
	-- If "Transport: Record" state is "ON"
	if record_command_state == 1 then
		-- Record: Start new files during recording
		reaper.Main_OnCommand(40666, 0)  
		-- Record: Add recorded media to project
		reaper.Main_OnCommand(40670, 0)
		-- Save current track selection
		reaper.Main_OnCommand(sws_saveCurrentTrackSelection, 0)
		-- Save selected item(s)
		reaper.Main_OnCommand(sws_saveSelectedItems, 0)
		-- Item: Unselect (clear selection of all items)
		reaper.Main_OnCommand(40289, 0)
		-- timbert_VASC Select Guide track exclusively.lua
		reaper.Main_OnCommand(vasc_selectGuideTrack, 0)
		-- _XENAKIOS_SELITEMSUNDEDCURSELTX
		reaper.Main_OnCommand(sws_selectItems_editCursor_onSelectedTracks, 0)
			if reaper.CountSelectedMediaItems( 0 ) == 0 then
				isGuideItemPresent = false
			do return end -- Return if there is no Guide track information
			else
				-- timbert_Store selected item notes.lua 
				reaper.Main_OnCommand(vasc_storeItemNotes, 0)
				-- SWS: Save Selected track(s) selected item(s), slot 1
				reaper.Main_OnCommand(save_item_slot_1_ID, 0)
				-- _SWS_RESTORESEL
				reaper.Main_OnCommand(sws_restoreTrackSelection, 0)
				-- _SWS_RESTALLSELITEMS1
				reaper.Main_OnCommand(sws_restoreSelectedItems, 0)
				-- Script: timbert_Paste to selected item notes.lua
				reaper.Main_OnCommand(vasc_pasteItemNotes, 0)
				-- Item: Unselect (clear selection of all items)
				reaper.Main_OnCommand(40289, 0)
				-- timbert_VASC Select Guide track exclusively.lua
				reaper.Main_OnCommand(vasc_selectGuideTrack, 0)
				-- _SWS_RESTSELITEMS1
				reaper.Main_OnCommand(restore_item_slot_1_ID, 0)
				-- _SWS_RESTORESEL
				reaper.Main_OnCommand(sws_restoreTrackSelection, 0)
			end
	else
		-- timbert_VASC Select Guide track exclusively.lua
		reaper.Main_OnCommand(vasc_selectGuideTrack, 0)
		-- _XENAKIOS_SELITEMSUNDEDCURSELTX
		reaper.Main_OnCommand(sws_selectItems_editCursor_onSelectedTracks, 0)
			if reaper.CountSelectedMediaItems( 0 ) == 0 then
				isGuideItemPresent = false
				-- Transport: Record
				reaper.Main_OnCommand(1013, 0)	
			do return end -- Just record if no Guide Track info, then return
			else
				-- timbert_Store selected item notes.lua
				reaper.Main_OnCommand(vasc_storeItemNotes, 0)
				-- _SWS_RESTORESEL
				reaper.Main_OnCommand(sws_restoreTrackSelection, 0)
			end
				-- Transport: Record
				reaper.Main_OnCommand(1013, 0)	
	end
end

main() -- call main function 

reaper.UpdateArrange()

reaper.Undo_EndBlock("VASC Record Punch with notes", 0 ) -- End of the undo block. Leave it at the bottom of your main function.

reaper.PreventUIRefresh(-1)