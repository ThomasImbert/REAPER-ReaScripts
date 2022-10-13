-- @description VASC Record Punch PT like with notes
-- @author Thomas Imbert
-- @version 1.0
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about A record punch similar to ProTool's, intended to work with VASC. it copies notes from the Guide track item onto the recorded take.
-- @changelog 
--   # Initial Release (2022-10-14)

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
local vasc_selectGuideTrack = reaper.NamedCommandLookup("_RS09aad089649d67d41b3553419bbc062570f69fe7")
-- Get computer specific ID of "_SWS_RESTORESEL"
local sws_restoreTrackSelection = reaper.NamedCommandLookup("_SWS_RESTORESEL")  
-- Get computer specific ID of "timbert_Store selected item notes.lua"
local vasc_storeItemNotes = reaper.NamedCommandLookup("_RS71a88093363c7138ff37c985534487b02a6738d4") 
-- Get computer specific ID of "Script: timbert_Paste to selected item notes.lua"
local vasc_pasteItemNotes = reaper.NamedCommandLookup("_RS465de87b16682226804d7b9d85cf79e17e6d92e7") 
-- Get computer specific ID of "_XENAKIOS_SELITEMSUNDEDCURSELTX"
local sws_selectItems_editCursor_onSelectedTracks = reaper.NamedCommandLookup("_XENAKIOS_SELITEMSUNDEDCURSELTX") 
-- Get computer specific ID of "_SWS_SAVEALLSELITEMS1"
local sws_saveSelectedItems = reaper.NamedCommandLookup("_SWS_SAVEALLSELITEMS1") 
-- Get computer specific ID of "_SWS_RESTALLSELITEMS1"
local sws_restoreSelectedItems = reaper.NamedCommandLookup("_SWS_RESTALLSELITEMS1") 

function recordStart()
	-- timbert_VASC Select Guide track exclusively.lua
	reaper.Main_OnCommand(vasc_selectGuideTrack, 0)
	-- _XENAKIOS_SELITEMSUNDEDCURSELTX
	reaper.Main_OnCommand(sws_selectItems_editCursor_onSelectedTracks, 0)
	-- timbert_Store selected item notes.lua
	reaper.Main_OnCommand(vasc_storeItemNotes, 0)
	-- _SWS_RESTORESEL
	reaper.Main_OnCommand(sws_restoreTrackSelection, 0)
	-- Transport: Record
	reaper.Main_OnCommand(1013, 0)	
end

function recordPunch()
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

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

reaper.Main_OnCommand(sws_saveCurrentTrackSelection, 0)

-- If "Transport: Record" state is "ON"
if record_command_state == 1 then
	reaper.defer(recordPunch)
else
	reaper.defer(recordStart)
end

reaper.UpdateArrange()

reaper.Undo_EndBlock("VASC Record Punch with notes", - 1) -- End of the undo block. Leave it at the bottom of your main function.

reaper.PreventUIRefresh(-1)