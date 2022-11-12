-- @description VASC Record Punch PT like with notes
-- @author Thomas Imbert
-- @version 1.6
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about A record punch similar to ProTool's, intended to work with VASC. Copies notes from the Guide track item onto the recorded take.
-- @changelog 
--   # Moved Extend Guide logic outside of script

-- USER SETTINGS:
local autoExtendToggle = true -- set it to false to turn off the Auto Extend feature

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath()..'/scripts/Thomas Imbert/Development/timbert_Lua Utilities.lua'
if reaper.file_exists( timbert_LuaUtils ) then dofile( timbert_LuaUtils ); if not timbert or timbert.version() < 1.3 then timbert.msg('This script requires a newer version of TImbert Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"TImbert Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires TImbert Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'TImbert Lua Utilities'"); return end

local cursPos, regionPos, regionEnd, nameRegion, color, regionidx

function main()
	local isRecording = reaper.GetToggleCommandState(1013)
	local isGuideTrackInfo = timbert.getGuideTrackInfo()

	if (isGuideTrackInfo == false and isRecording == 0 ) then
		reaper.Main_OnCommand(1013, 0) -- Transport: Record   
		-- timbert.dbg("No GuideTrackInfo and not recording")
	return end
	
	if (isGuideTrackInfo == false and isRecording == 1 ) then
		reaper.Main_OnCommand(40666, 0) -- Record: Start new files during recording  
		reaper.Main_OnCommand(40670, 0) -- Record: Add recorded media to project
		-- timbert.dbg("No GuideTrackInfo and recording")
	return end

	if (isGuideTrackInfo == true and isRecording == 1) then
		reaper.Main_OnCommand(40666, 0) -- Record: Start new files during recording
		reaper.Main_OnCommand(40670, 0) -- Record: Add recorded media to project
		timbert.pasteNotes()
		reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of all items)
		timbert.selectStoredGuideTrackItem()
		-- timbert.dbg("GuideTrackInfo and recording")
	return end
	
	-- timbert.dbg("GuideTrackInfo and not recording")
	reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of all items)
	timbert.selectStoredGuideTrackItem() 
	reaper.Main_OnCommand(1013, 0) -- Transport: Record   
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

main() -- call main function 

reaper.UpdateArrange()

reaper.Undo_EndBlock("VASC Record Punch with notes", -1 ) -- End of the undo block. Leave it at the bottom of your main function.

reaper.PreventUIRefresh(-1)