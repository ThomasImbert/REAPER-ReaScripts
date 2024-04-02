-- @noindex
-- Get this script's name
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local reaper = reaper

reaImGui = reaper.GetResourcePath() .. '/UserPlugins/reaper_imgui-x64.dll'
if not reaper.file_exists(reaImGui) then
    reaper.MB(
        "This script requires the ReaImGui extension! Please install it here:\n\nExtensions > ReaPack > Browse Packages > 'ReaImGui: ReaScript binding for Dear ImGui'",
        script_name, 0)
    return
end

-- Load lua utilities
timbert_LuaUtils = reaper.GetResourcePath() .. '/scripts/TImbert Scripts/Development/timbert_Lua Utilities.lua'
if not reaper.file_exists(timbert_LuaUtils) then
    reaper.MB(
        "This script requires TImbert Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'TImbert Lua Utilities'",
        script_name, 0)
    return
end
dofile(timbert_LuaUtils)
if not timbert or timbert.version() < 1.926 then
    reaper.MB(
        "This script requires a newer version of TImbert Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages",
        script_name, 0)
    return
end

-- Load Config
timbert_FILBetter = reaper.GetResourcePath() ..
                        '/scripts/TImbert Scripts/FILBetter/timbert_FILBetter (Better Track Fixed Item Lanes).lua'
dofile(timbert_FILBetter)

---------------------------
reaper.set_action_options(1)

-- Dummy config load to make sure FILBetterCFG.json is generated--
local dummyConfig = FILBetter.LoadConfig("goToNextSnapToLastContent")

local ImGui = {}
for name, func in pairs(reaper) do
    name = name:match('^ImGui_(.+)$')
    if name then
        ImGui[name] = func
    end
end

local ctx
local FLT_MIN, FLT_MAX = ImGui.NumericLimits_Float()
local filbGUI = {
    open = true,

    menu = {
        enabled = true,
        f = 0.5,
        n = 0,
        b = true
    },

    -- Window flags (accessible from the "Configuration" section)
    no_titlebar = false,
    no_menu = true,
    no_resize = true,
    no_collapse = true
}

local cache = {}
local reset, filbCfg, filbSettings, filbNewCfg, filbSettings, delay, app
local filb = {}

local title = reaper.ImGui_CreateFont('Verdana1', 20, reaper.ImGui_FontFlags_Bold())
local sans_serif = reaper.ImGui_CreateFont('Verdana1', 16)

function filbGUI.loop()
    filbGUI.PushStyle()
    filbGUI.open = filbGUI.ShowFILBWindow(true)
    filbGUI.PopStyle()

    if filbGUI.open then
        reaper.defer(filbGUI.loop)
    end
end

if select(2, reaper.get_action_context()) == debug.getinfo(1, 'S').source:sub(2) then
    ctx = ImGui.CreateContext('FILBetter Settings')
    reaper.ImGui_Attach(ctx, sans_serif)
    reaper.ImGui_Attach(ctx, title)
    reaper.defer(filbGUI.loop)
end

-------------------------------------------------------------------------------
-- [SECTION] Helpers
-------------------------------------------------------------------------------

-- Helper to display a little (?) mark which shows a tooltip when hovered.
function filbGUI.HelpMarker(desc)
    ImGui.TextDisabled(ctx, '(?)')
    if ImGui.IsItemHovered(ctx, ImGui.HoveredFlags_DelayShort()) and ImGui.BeginTooltip(ctx) then
        ImGui.PushTextWrapPos(ctx, ImGui.GetFontSize(ctx) * 30.0)
        ImGui.Spacing(ctx)
        ImGui.Text(ctx, desc)
        ImGui.PopTextWrapPos(ctx)
        ImGui.Spacing(ctx)
        ImGui.EndTooltip(ctx)
    end
end

function filbGUI.Link(url)
    if not reaper.CF_ShellExecute then
        ImGui.Text(ctx, url)
        return
    end

    local color = ImGui.GetStyleColor(ctx, ImGui.Col_CheckMark())
    ImGui.TextColored(ctx, color, url)
    if ImGui.IsItemClicked(ctx) then
        reaper.CF_ShellExecute(url)
    elseif ImGui.IsItemHovered(ctx) then
        ImGui.SetMouseCursor(ctx, ImGui.MouseCursor_Hand())
    end
end

function filbGUI.EachEnum(enum)
    local enum_cache = cache[enum]
    if not enum_cache then
        enum_cache = {}
        cache[enum] = enum_cache

        for func_name, func in pairs(reaper) do
            local enum_name = func_name:match(('^ImGui_%s_(.+)$'):format(enum))
            if enum_name then
                table.insert(enum_cache, {func(), enum_name})
            end
        end
        table.sort(enum_cache, function(a, b)
            return a[1] < b[1]
        end)
    end

    local i = 0
    return function()
        i = i + 1
        if not enum_cache[i] then
            return
        end
        return table.unpack(enum_cache[i])
    end
end

function filbGUI.ShowFILBWindow(open)

    reaper.ImGui_PushFont(ctx, title)
    local rv = nil

    local window_flags = ImGui.WindowFlags_None()
    if filbGUI.no_titlebar then
        window_flags = window_flags | ImGui.WindowFlags_NoTitleBar()
    end
    if not filbGUI.no_menu then
        window_flags = window_flags | ImGui.WindowFlags_MenuBar()
    end
    if filbGUI.no_resize then
        window_flags = window_flags | ImGui.WindowFlags_NoResize()
    end
    if filbGUI.no_collapse then
        window_flags = window_flags | ImGui.WindowFlags_NoCollapse()
    end

    local main_viewport = ImGui.GetMainViewport(ctx)
    local work_pos = {ImGui.Viewport_GetWorkPos(main_viewport)}
    ImGui.SetNextWindowPos(ctx, work_pos[1] + 20, work_pos[2] + 20, ImGui.Cond_FirstUseEver())
    ImGui.SetNextWindowSize(ctx, 600, 680)

    if filbGUI.set_dock_id then
        ImGui.SetNextWindowDockID(ctx, filbGUI.set_dock_id)
        filbGUI.set_dock_id = nil
    end

    -- Main body of the window starts here.
    rv, open = ImGui.Begin(ctx, 'FILBetter settings', open, window_flags)
    ImGui.Spacing(ctx)
    ImGui.Spacing(ctx)
    ImGui.PushItemWidth(ctx, -ImGui.GetWindowWidth(ctx) * 0.75)

    filbGUI.UpdateFILBSettings()
    filbGUI.ShowStyleEditor()
    ImGui.PopItemWidth(ctx)
    ImGui.End(ctx)

    reaper.ImGui_PopFont(ctx)
    return open
end

-- Return the first index with the given value (or nil if not found).
local function indexOf(table, value)
    for k, v in pairs(table) do
        if v == value then
            return k
        end
    end
    return nil
end

function filbGUI.UpdateFILBSettings()
    reaper.ImGui_PushFont(ctx, sans_serif)

    local rv
    delay = delay

    if not filbCfg then
        delay = 0
        filbCfg = {}
        filbNewCfg = {}
        filbSettings = {}
        for k, v in pairs(FILBetter.LoadFullConfig()) do
            filbCfg[k] = v
        end
        filbSettings.clickedApply = 0
        filbSettings.clickedReset = 0
        filbSettings.curMarkerLocation = indexOf(FILBetter.previewMarkerLocation, filbCfg["previewMarkerLocation"]) - 1
        filbSettings.curMarkerLane = indexOf(FILBetter.previewMarkerContentLane, filbCfg["previewMarkerContentLane"]) -
                                         1
        filbSettings.curItemLaneCombo = indexOf(FILBetter.LanePriorities, filbCfg["lanePriority"]) - 1
        filbSettings.curItemCompCombo = indexOf(FILBetter.LanePriorities, filbCfg["compLanePriority"]) - 1
        filbSettings.curTimeSelectMode = indexOf(FILBetter.timeSelectModes, filbCfg["goToContentTimeSelectionMode"]) - 1
        filbSettings.curSeekPlaybackRetriggCurPos = indexOf(FILBetter.seekPlaybackRetriggCurPos,
            filbCfg["seekPlaybackRetriggCurPos"]) - 1
        filbSettings.curSeekPlaybackEndCurPos = indexOf(FILBetter.seekPlaybackEndCurPos,
            filbCfg["seekPlaybackEndCurPos"]) - 1
    end

    if reset == true then
        reset = false
        delay = 0
        filbCfg = {}
        filbNewCfg = {}
        filbSettings = {}
        for k, v in pairs(FILBetter.defaultFILBetter) do
            filbCfg[k] = FILBetter.defaultFILBetter[k]
        end
        filbSettings.clickedApply = 0
        filbSettings.clickedReset = 1
        filbSettings.curMarkerLocation = indexOf(FILBetter.previewMarkerLocation, filbCfg["previewMarkerLocation"]) - 1
        filbSettings.curMarkerLane = indexOf(FILBetter.previewMarkerContentLane, filbCfg["previewMarkerContentLane"]) -
                                         1
        filbSettings.curItemLaneCombo = indexOf(FILBetter.LanePriorities, filbCfg["lanePriority"]) - 1
        filbSettings.curItemCompCombo = indexOf(FILBetter.LanePriorities, filbCfg["compLanePriority"]) - 1
        filbSettings.curTimeSelectMode = indexOf(FILBetter.timeSelectModes, filbCfg["goToContentTimeSelectionMode"]) - 1
        filbSettings.curSeekPlaybackRetriggCurPos = indexOf(FILBetter.seekPlaybackRetriggCurPos,
            filbCfg["seekPlaybackRetriggCurPos"]) - 1
        filbSettings.curSeekPlaybackEndCurPos = indexOf(FILBetter.seekPlaybackEndCurPos,
            filbCfg["seekPlaybackEndCurPos"]) - 1
    end

    -- NAVIGATION
    ImGui.SeparatorText(ctx, 'Navigation (Go to previous / next content)')
    rv, filbCfg["goToPreviousSnapTofirstContent"] = ImGui.Checkbox(ctx, 'Snap forward to first content',
        filbCfg["goToPreviousSnapTofirstContent"])
    ImGui.SameLine(ctx, 0, 90)
    rv, filbCfg["goToNextSnapToLastContent"] = ImGui.Checkbox(ctx, 'Snap back to last content',
        filbCfg["goToNextSnapToLastContent"])
    ImGui.SameLine(ctx)
    filbGUI.HelpMarker(
        'Changes the behaviour when the edit cursor is positioned before the first content or after the last content of the track.')
    rv, filbCfg["moveEditCurToStartOfContent"] = ImGui.Checkbox(ctx, 'Move edit cursor to start of item in lane',
        filbCfg["moveEditCurToStartOfContent"])
    ImGui.SameLine(ctx)
    filbGUI.HelpMarker(
        'Especially useful when the content in lanes is not vertically aligned. Allows the user to start playback at the start of content.')
    ImGui.PushItemWidth(ctx, 80)
    do
        local navTimeSelectMode = 'clear\0recall\0content\0'
        rv, filbSettings.curTimeSelectMode = ImGui.Combo(ctx, 'Time selection', filbSettings.curTimeSelectMode,
            navTimeSelectMode)
    end

    -- PREVIEW
    ImGui.SeparatorText(ctx, 'Preview')
    rv, filbCfg["previewOnLaneSelection"] = ImGui.Checkbox(ctx, 'Preview on lane selection change',
        filbCfg["previewOnLaneSelection"])
    ImGui.SameLine(ctx)
    filbGUI.HelpMarker(
        'You can still preview the lane content with "Preview content under edit cursor in currently soloed lane" when set to off.')
    rv, filbCfg["previewMarkerName"] = ImGui.InputTextWithHint(ctx, 'Preview marker name', filbCfg["previewMarkerName"],
        filbCfg["previewMarkerName"])
    ImGui.PushItemWidth(ctx, 130)
    do
        local markerLocation = 'mouse cursor\0edit cursor\0'
        rv, filbSettings.curMarkerLocation = ImGui.Combo(ctx, 'Target location for preview marker creation',
            filbSettings.curMarkerLocation, markerLocation)
    end
    ImGui.PushItemWidth(ctx, 130)
    do
        local markerLane = 'priority lane\0active lane\0'
        rv, filbSettings.curMarkerLane = ImGui.Combo(ctx, 'Target lane when creating marker at edit cursor',
            filbSettings.curMarkerLane, markerLane)
    end
    ImGui.SameLine(ctx);
    filbGUI.HelpMarker('active lane = soloed lane')

    -- SEEK PLAYBACK
    ImGui.SeparatorText(ctx, 'Seek Playback (Play from current content)')
    ImGui.PushItemWidth(ctx, 100)
    do
        local seekPlaybackRetriggCurPos = 'current\0previous\0origin\0last\0'
        rv, filbSettings.curSeekPlaybackRetriggCurPos = ImGui.Combo(ctx, 'Cursor position when retriggered',
            filbSettings.curSeekPlaybackRetriggCurPos, seekPlaybackRetriggCurPos)
    end
    ImGui.PushItemWidth(ctx, 100)
    do
        local seekPlaybackEndCurPos = 'last\0after last\0'
        rv, filbSettings.curSeekPlaybackEndCurPos = ImGui.Combo(ctx, 'Cursor position when playback finishes',
            filbSettings.curSeekPlaybackEndCurPos, seekPlaybackEndCurPos)
    end
    ImGui.SameLine(ctx)
    filbGUI.HelpMarker(
        '"Stop/repeat playback at end of project" should be turned off in Preferences > Playback > Playback settings.')

    -- RECORDING
    ImGui.SeparatorText(ctx, 'Recording')
    rv, filbCfg["recordingBellOn"] = ImGui.Checkbox(ctx, 'Enable recording bell', filbCfg["recordingBellOn"])
    ImGui.SameLine(ctx)
    filbGUI.HelpMarker(
        'The recording bell uses the metronome tick sound. In Metronome setting, allow run during recording. Try Primary beat = 250Hz, 100ms duration and sine soft start for a gentle bell sound.')
    rv, filbCfg["recallCursPosWhenRetriggRec"] = ImGui.Checkbox(ctx,
        'Recall cursor position when retriggering Record in place / with context',
        filbCfg["recallCursPosWhenRetriggRec"])
    rv, filbCfg["scrollViewToEditCursorOnStopRecording"] = ImGui.Checkbox(ctx, 'Scroll view to edit cursor on stop',
        filbCfg["scrollViewToEditCursorOnStopRecording"])
    rv, filbCfg["pushNextContentTime"] = ImGui.InputInt(ctx, '"Push next content when recording" amount in seconds',
        filbCfg["pushNextContentTime"])

    -- LANE PRIORITY
    ImGui.SeparatorText(ctx, 'Lane Priority')
    rv, filbCfg["prioritizeCompLaneOverLastLane"] = ImGui.Checkbox(ctx, 'Prioritize comp lanes over last lane',
        filbCfg["prioritizeCompLaneOverLastLane"])

    do
        local lanePriority = 'first\0last\0'
        rv, filbSettings.curItemLaneCombo = ImGui.Combo(ctx, 'Lane priority', filbSettings.curItemLaneCombo,
            lanePriority)
    end
    ImGui.SameLine(ctx, 0, 20)
    do
        local compPriority = 'first\0last\0'
        rv, filbSettings.curItemCompCombo = ImGui.Combo(ctx, 'Comp lane priority', filbSettings.curItemCompCombo,
            compPriority)
    end

    -- ERROR MESSAGES
    ImGui.SeparatorText(ctx, 'Error Messages')
    rv, filbCfg["showValidationErrorMsg"] = ImGui.Checkbox(ctx,
        'Display error messages when user selection is incorrect', filbCfg["showValidationErrorMsg"])

    -- APPLY / RESET
    ImGui.SeparatorText(ctx, '')

    if ImGui.Button(ctx, 'Apply settings') then
        filbSettings.clickedApply = filbSettings.clickedApply + 1
        for k, v in pairs(filbCfg) do
            filbNewCfg[k] = v
        end
        filbNewCfg["previewMarkerLocation"] = FILBetter.previewMarkerLocation[filbSettings.curMarkerLocation + 1]
        filbNewCfg["previewMarkerContentLane"] = FILBetter.previewMarkerContentLane[filbSettings.curMarkerLane + 1]
        filbNewCfg["lanePriority"] = FILBetter.LanePriorities[filbSettings.curItemLaneCombo + 1]
        filbNewCfg["compLanePriority"] = FILBetter.LanePriorities[filbSettings.curItemCompCombo + 1]
        filbNewCfg["goToContentTimeSelectionMode"] = FILBetter.timeSelectModes[filbSettings.curTimeSelectMode + 1]
        filbNewCfg["seekPlaybackRetriggCurPos"] =
            FILBetter.seekPlaybackRetriggCurPos[filbSettings.curSeekPlaybackRetriggCurPos + 1]
        filbNewCfg["seekPlaybackEndCurPos"] = FILBetter.seekPlaybackEndCurPos[filbSettings.curSeekPlaybackEndCurPos + 1]
        FILBetter.save_json(FILBetter.scriptPath, "FILBetterConfig", filbNewCfg)
    end

    ImGui.SameLine(ctx, 0, 350)
    if ImGui.Button(ctx, 'Reset to defaults') then
        filbSettings.clickedReset = filbSettings.clickedReset + 1
        reset = true
    end

    if filbSettings.clickedApply & 1 ~= 0 then
        ImGui.Text(ctx, 'Changes applied to Config files!')
        delay = delay + 1
        if delay == 20 then
            filbSettings.clickedApply = 0
            delay = 0
        end
    end

    if filbSettings.clickedReset & 1 ~= 0 then
        ImGui.Text(ctx, 'Settings set to default!')
        delay = delay + 1
        if delay == 20 then
            filbSettings.clickedReset = 0
            delay = 0
        end
    end

    reaper.ImGui_PopFont(ctx)
end

function filbGUI.ShowStyleEditor()
    local rv

    if not app then
        app = {
            style = filbGUI.GetStyleData(),
            push_count = 0
        }
    end

    app.style.vars[ImGui['StyleVar_WindowRounding']()] = 8
    app.style.vars[ImGui['StyleVar_WindowPadding']()] = {20, 0}
    app.style.vars[ImGui['StyleVar_WindowTitleAlign']()] = {0.04, 0.5}
end

function filbGUI.GetStyleData()
    local data = {
        vars = {},
        colors = {}
    }
    local vec2 = {'ButtonTextAlign', 'SelectableTextAlign', 'CellPadding', 'ItemSpacing', 'ItemInnerSpacing',
                  'FramePadding', 'WindowPadding', 'WindowMinSize', 'WindowTitleAlign', 'SeparatorTextAlign',
                  'SeparatorTextPadding'}

    for i, name in filbGUI.EachEnum('StyleVar') do
        local rv = {ImGui.GetStyleVar(ctx, i)}
        local is_vec2 = false
        for _, vec2_name in ipairs(vec2) do
            if vec2_name == name then
                is_vec2 = true
                break
            end
        end
        data.vars[i] = is_vec2 and rv or rv[1]
    end
    for i in filbGUI.EachEnum('Col') do
        data.colors[i] = ImGui.GetStyleColor(ctx, i)
    end
    return data
end

function filbGUI.PushStyle()
    local rv

    if app then
        app.push_count = app.push_count + 1
        for i, value in pairs(app.style.vars) do
            if type(value) == 'table' then
                ImGui.PushStyleVar(ctx, i, table.unpack(value))
            else
                ImGui.PushStyleVar(ctx, i, value)
            end
        end
        for i, value in pairs(app.style.colors) do
            ImGui.PushStyleColor(ctx, i, value)
        end
    end

end

function filbGUI.PopStyle()
    if app and app.push_count > 0 then
        app.push_count = app.push_count - 1
        ImGui.PopStyleColor(ctx, #cache['Col'])
        ImGui.PopStyleVar(ctx, #cache['StyleVar'])
    end
end

local public, public_functions = {}, {'ShowFILBWindow', 'ShowStyleEditor', 'PushStyle', 'PopStyle'}
for _, fn in ipairs(public_functions) do
    public[fn] = function(user_ctx, ...)
        ctx = user_ctx
        filbGUI[fn](...)
    end
    return public
end
