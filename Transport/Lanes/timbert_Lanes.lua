-- @description timbert_Lanes
-- @author Thomas Imbert
-- @version 1.0pre1.1
-- @changelog 
--   # Initial release
-- @link 
--      GitHub repository: https://github.com/ThomasImbert/REAPER-ReaScripts
--      Website: https://thomasimbert.wixsite.com/audio
-- @about 
--      # Thomas Imbert's Lanes suite of scripts
--
--      Expands on the lanes functionality added in reaper 7
--
--      Allows for session navigation, lane solo-ing and previewing based on lanes content, recording with context, and more!
-- @provides
--      [main] *.Lua
-- Load lua utilities
lanes = {}

function lanes.ValidateLuaUtils()
    local error
    timbert_LuaUtils = reaper.GetResourcePath() .. '/scripts/TImbert Scripts/Development/timbert_Lua Utilities.lua'
    if not reaper.file_exists(timbert_LuaUtils) then
        error =
            "This script requires TImbert Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'TImbert Lua Utilities'"
    end
    dofile(timbert_LuaUtils)
    if timbert.version() < 1.922 then
        error =
            "This script requires a newer version of TImbert Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages"
    end
    return error
end
-- timbert.msg(
--     "Thomas Imbert's Lanes suite of scripts\n\nExpands on the track fixed item lanes functionalities added in reaper 7\nAllows for session navigation, lane solo-ing and previewing based on lanes content, recording with context, and more!",
--     "Thomas Imbert's Lanes Suite")
