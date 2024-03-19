-- @description FILBetter (Better Track Fixed Item Lanes)
-- @author Thomas Imbert
-- @version 1.0pre1.3
-- @changelog 
--   # Updated Record with context and added calls to config var across all scripts, updated Go to previous if called by other script
--   # Updated Lua Utils dependencies, rewrote validation accordingly in all scripts of the suite
--   # Added calls to Config file
--   # Remove recorded item in record with context if stopped before end of preview context time
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

-- Thanks to rxi for the lua and JSON functions, gxray and Daniel Lumertz for the config file explainer
-- Get a Path to save json (using script path)
local info = debug.getinfo(1, 'S');
local ScriptPath = info.source:match [[^@?(.*[\/])[^\/]-$]];

-- Load json file from "./utils.json"
-- Load the json functions
package.path =
    package.path .. ";" .. string.match(({reaper.get_action_context()})[2], "(.-)([^\\/]-%.?([^%.\\/]*))$") .. "?.lua"
local json = require("./utils.json")

-- Save function
function save_json(path, name, var)
    local filepath = path .. "/" .. name .. ".json"
    local file = assert(io.open(filepath, "w+"))

    local serialized = json.encode(var)
    assert(file:write(serialized))

    file:close()
    return true
end

-- Load function
function load_json(path, name)
    local filepath = path .. "/" .. name .. ".json"
    local file = assert(io.open(filepath, "rb"))

    local raw_text = file:read("*all")
    file:close()

    return json.decode(raw_text)
end

-- If run from action list, expain FILBetter and return
if select(2, reaper.get_action_context()) == debug.getinfo(1, 'S').source:sub(2) then
    reaper.MB(
        "FILBetter is a suite of scripts that expands on the track fixed item lanes functionalities added in reaper 7 \n\nAllows for session navigation, lane solo-ing and previewing based on lanes content, recording with context, and more! \n\nYou can change some script settings by going to your Reaper resource path folder > Scripts > TImbert Scripts > FILBetter, and modifying FILBetterConfig.json, which will generate as soon as you've used one of the scripts once \n\nby Thomas Imbert",
        script_name, 0)
    return
end

FILBetter = {}

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
    makePreviewMarkerAtMouseCursor = true, -- false = make take marker at edit cursor position
    findTakeInPriorityLanePreviewMarkerAtEditCursor = true, -- when makePreviewMarkerAtMouseCursor is false, make take marker in content in priority lane instead of clicked content
    previewMarkerName = "[FILB]",
    recallCursPosWhenTrimOnStop = true -- in Record with context script, TrimOnStop(), recall edit cursor position after trimming last recorded item
}

-- Load FILBETTER.cfg
timbert_FILBetterCFG = reaper.GetResourcePath() .. '/scripts/TImbert Scripts/FILBetter/FILBetterConfig.json'

function FILBetter.LoadFullConfig()
    if not reaper.file_exists(timbert_FILBetterCFG) then
        -- Create default config if it doesn't already exist
        save_json(ScriptPath, "FILBetterConfig", defaultFILBetter)
    end
    -- load configKey value
    local table = load_json(ScriptPath, "FILBetterConfig")

    return table
end

function FILBetter.LoadConfig(configKeyString)
    if not reaper.file_exists(timbert_FILBetterCFG) then
        -- Create default config if it doesn't already exist
        save_json(ScriptPath, "FILBetterConfig", defaultFILBetter)
    end
    -- load configKey value
    local loadedValue = load_json(ScriptPath, "FILBetterConfig")
    return loadedValue[configKeyString]
end
