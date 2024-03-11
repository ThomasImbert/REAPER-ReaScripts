-- @description FILBetter (Better Track Fixed Item Lanes)
-- @author Thomas Imbert
-- @version 1.0pre1.1
-- @changelog 
--   # Initial release
-- @link 
--      GitHub repository: https://github.com/ThomasImbert/REAPER-ReaScripts
--      Website: https://thomasimbert.wixsite.com/audio
-- @about 
--      # FILBetter is a suite of scripts that expands on the track fixed item lanes functionalities added in reaper 7
--
--      Allows for session navigation, lane solo-ing and previewing based on lanes content, recording with context, and more!
-- 
--      by Thomas Imbert
-- @provides
--      [main] *.Lua
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
reaper.MB(
    "FILBetter is a suite of scripts that expands on the track fixed item lanes functionalities added in reaper 7\n\nAllows for session navigation, lane solo-ing and previewing based on lanes content, recording with context, and more!\n\nby Thomas Imbert",
    script_name, 0)