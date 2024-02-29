-- @description VASC Play/Stop/Pause with notes
-- @author Thomas Imbert
-- @version 1.2
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about Play/Stop command that pastes stored VASC Guide info in selected item.
-- @changelog 
--   # Clean code by loading lua Utilites and moved ExtendGuide to another script. Added User settings for the play / stop / pause mode

-- USER SETTINGS:
local playMode = "PlayStop" 
	-- Options are:
	-- "PlayStop" : When executing this script during play, keep edit cursor position
	-- "PlayPause" When executing this script during play, move edit cursor to play cursor 
-- END OF USER SETTINGS --

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath()..'/scripts/TImbert Scripts/Development/timbert_Lua Utilities.lua'
if reaper.file_exists( timbert_LuaUtils ) then dofile( timbert_LuaUtils ); if not timbert or timbert.version() < 1.8 then timbert.msg('This script requires a newer version of TImbert Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"TImbert Lua Utilities"); return end else reaper.ShowConsoleMsg("This script requires TImbert Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'TImbert Lua Utilities'"); return end

-- Get User Setting 
local playCommandSwitch
if playMode == "PlayStop" then playCommandSwitch = 40044 end
if playMode == "PlayPause" then playCommandSwitch = 40073 end

-- Record state
local recordState = reaper.GetToggleCommandState(1013) 
local playState = reaper.GetToggleCommandState(1007) 

function main()  
	if playState == 0 then -- If transport is stopped
		reaper.Main_OnCommand(playCommandSwitch, 0) -- Transport: playMode (user defined)
		if timbert.getGuideTrackInfo() then 
			timbert.selectStoredGuideTrackItem() 
		end
	return end 

	if recordState == 0 then -- If Record is off
		if timbert.getGuideTrackInfo() then 
			reaper.Main_OnCommand(playCommandSwitch, 0) -- Transport: playMode (user defined)
			timbert.selectStoredGuideTrackItem() 
		return end
		reaper.Main_OnCommand(playCommandSwitch, 0) -- Transport: playMode (user defined)
	return end

	if timbert.getGuideTrackInfo() then 
		reaper.Main_OnCommand(playCommandSwitch, 0) -- Transport: playMode (user defined)
		timbert.pasteNotes()
	else
		reaper.Main_OnCommand(playCommandSwitch, 0) -- Transport: playMode (user defined)
	end
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() 

main()

reaper.UpdateArrange()

reaper.Undo_EndBlock("VASC Play/Stop/Pause with notes", -1 )

reaper.PreventUIRefresh(-1)