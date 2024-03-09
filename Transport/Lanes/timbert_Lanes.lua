-- @description timbert_Lanes
-- @author Thomas Imbert
-- @version 1.0pre1
-- @link 
--      GitHub repository: https://github.com/ThomasImbert/REAPER-ReaScripts
--      
--      Website: https://thomasimbert.wixsite.com/audio
-- 
-- @about 
--      # Thomas Imbert's Lanes suite of scripts
--
--      Expands on the lanes functionality added in reaper 7
--
--      Allows for session navigation, lane solo-ing and previewing based on lanes content, recording with context, and more!
-- @provides
--      [main] *.lua
-- @changelog 
--   # Initial release
-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1, ({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath() .. '/scripts/TImbert Scripts/Development/timbert_Lua Utilities.lua'
if reaper.file_exists(timbert_LuaUtils) then
    dofile(timbert_LuaUtils);
    if not timbert or timbert.version() < 1.921 then
        timbert.msg(
            'This script requires a newer version of TImbert Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages',
            "TImbert Lua Utilities");
        return
    end
else
    reaper.ShowConsoleMsg(
        "This script requires TImbert Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'TImbert Lua Utilities'");
    return
end

timbert.msg(
    "Thomas Imbert's Lanes suite of scripts\n\nExpands on the lanes functionality added in reaper 7\nAllows for session navigation, lane solo-ing and previewing based on lanes content, recording with context, and more!",
    script_name)
