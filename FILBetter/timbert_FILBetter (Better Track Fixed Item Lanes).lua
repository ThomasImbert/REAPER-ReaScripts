-- @description FILBetter (Better Track Fixed Item Lanes)
-- @author Thomas Imbert
-- @version 1.0pre2.3
-- @changelog 
--   # FILBetter.LoadConfig() can now generate new config key at load time, init at default value
--   # Settings script now loads each config key and generates new one following this change
--   # New setting: recordPunchInAtNextContentIfAny, false by default
--   # Updated Record with context to use new setting
--   # Added Set edit cursor in between... script
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
--      [main] *.lua
--      [nomain] utils/json.lua
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

FILBetter = {}

-- Thanks to rxi for the lua and JSON functions, gxray and Daniel Lumertz for the config file explainer
-- Get a Path to save json (using script path)
local info = debug.getinfo(1, 'S');
local ScriptPath = info.source:match [[^@?(.*[\/])[^\/]-$]];
FILBetter.scriptPath = ScriptPath

-- Load json file from "./utils.json"
-- Load the json functions
package.path =
    package.path .. ";" .. string.match(({reaper.get_action_context()})[2], "(.-)([^\\/]-%.?([^%.\\/]*))$") .. "?.lua"
local json = require("./utils.json")

-- Save function
function FILBetter.save_json(path, name, var)
    local filepath = path .. "/" .. name .. ".json"
    local file = assert(io.open(filepath, "w+"))

    local serialized = json.encode(var)
    assert(file:write(serialized))

    file:close()
    return true
end

-- Load function
function FILBetter.load_json(path, name)
    local filepath = path .. "/" .. name .. ".json"
    local file = assert(io.open(filepath, "rb"))

    local raw_text = file:read("*all")
    file:close()

    return json.decode(raw_text)
end

-- If run from action list, explain FILBetter and return
if select(2, reaper.get_action_context()) == debug.getinfo(1, 'S').source:sub(2) then
    local response = reaper.MB(
        "FILBetter is a suite of scripts that expands on the track fixed item lanes functionalities added in reaper 7 \n\nAllows for session navigation, lane solo-ing and previewing based on lanes content, recording with context, and more!\n\nby Thomas Imbert\n\nWould you like to open the tutorials playlist on youtube?",
        script_name, 4)
    if response == 6 then
        reaper.CF_ShellExecute("https://www.youtube.com/playlist?list=PLSGyZ2r1eeOm8TQ_a4v7eFk3odHGxZNcb")
    end
    return
end

local defaultFILBetter = {
    recordingBellOn = false,
    goToContentTimeSelectionMode = "clear", -- "clear", "recall" or "content"
    goToNextSnapToLastContent = true, -- When triggered after last content, goes back to last content
    goToPreviousSnapTofirstContent = true, -- When triggered before first content, goes forward to first content
    prioritizeCompLaneOverLastLane = true, -- change this setting to be a general priority selector, comp, last lane, top/first, bottom/last 
    compLanePriority = "first", -- "first" or "last" // when selecting comp lanes
    lanePriority = "last", -- "first" or "last" // when selecting priority lane outside of compLanes
    previewOnLaneSelection = true,
    showValidationErrorMsg = true,
    pushNextContentTime = 3,
    moveEditCurToStartOfContent = false, -- When going to next / previous lane 
    previewMarkerLocation = "mouse cursor",
    previewMarkerContentLane = "priority lane", -- "active lane"
    previewMarkerName = "[FILB]",
    seekPlaybackRetriggCurPos = "current", -- "previous", "origin", "last"
    seekPlaybackEndCurPos = "last", -- "after last"
    recallCursPosWhenRetriggRec = true, -- in Record with context script, TrimOnStop(), recall edit cursor position after trimming last recorded item
    scrollViewToEditCursorOnStopRecording = true, 
    recordPunchInAtNextContentIfAny = false
}

FILBetter.timeSelectModes = {"clear", "recall", "content"}
FILBetter.LanePriorities = {"first", "last"}
FILBetter.seekPlaybackRetriggCurPos = {"current", "previous", "origin", "last"}
FILBetter.seekPlaybackEndCurPos = {"last", "after last"}
FILBetter.previewMarkerLocation = {"mouse cursor", "edit cursor"}
FILBetter.previewMarkerContentLane = {"priority lane", "active lane"}

FILBetter.defaultFILBetter = defaultFILBetter

-- Load FILBetterConfig.json
timbert_FILBetterCFG = reaper.GetResourcePath() .. '/scripts/TImbert Scripts/FILBetter/FILBetterConfig.json'

function FILBetter.LoadFullConfig()
    if not reaper.file_exists(timbert_FILBetterCFG) then
        -- Create default config if it doesn't already exist
        FILBetter.save_json(ScriptPath, "FILBetterConfig", defaultFILBetter)
    end
    -- load configKey values, creating new ones if necessary, init at default value
    for k, v in pairs(defaultFILBetter) do
        FILBetter.LoadConfig(k)
    end
    local table = FILBetter.load_json(ScriptPath, "FILBetterConfig")

    return table
end

function FILBetter.LoadConfig(configKeyString)
    if not reaper.file_exists(timbert_FILBetterCFG) then
        -- Create default config if it doesn't already exist
        FILBetter.save_json(ScriptPath, "FILBetterConfig", defaultFILBetter)
    end
    -- load configKey value
    local loadedValue = FILBetter.load_json(ScriptPath, "FILBetterConfig")

    if loadedValue[configKeyString] == nil then
        local filepath = ScriptPath .. "/" .. "FILBetterConfig" .. ".json"
        local file = assert(io.open(filepath, "r+")) -- open in append mode
        file:seek("end", -1)
        local serialized = ',"'..configKeyString..'":'..tostring(defaultFILBetter[configKeyString]).."}"
        assert(file:write(serialized))
        file:close()
        return defaultFILBetter[configKeyString]
    end
    return loadedValue[configKeyString]
end
