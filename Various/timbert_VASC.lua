-- @description VASC (Voice Acting Spreadsheet Connect)
-- @author Thomas Imbert
-- @version 0.1
-- @link GitHub repository https://github.com/ThomasImbert/REAPER-ReaScripts
-- @about
--      Voice Acting Spreadsheet Connect launches the VASC web interface allowing users to import spreadsheet to make their Reaper session smarter.
--
--      The tool allows for Recording session preparation with a guide track that includes data from the spreadsheet, as well as metadata markers for embedding at export.
--
--      Multiple scripts are found in this repo to make Dialog recording more efficient and less prone to errors.
--
--      This tool wouldn't have been possible without following Aaron Cendan's work on UCS Renaming tool as a template. Thanks Aaron!
--
--   ### Useful Resources
--   * Forum post: 
--   * Tutorial vid: 
--   * ASWG iXML specs: https://github.com/Sony-ASWG/iXML-Extension/blob/main/ASWG-G006%20-%20iXML%20Extension%20Specification%20v1.0.pdf
--
-- @metapackage
-- @provides
--   [main] . > timbert_VASC.lua
-- @changelog
--   #Initial Pre-Alpha Release


-- GLOBAL VARS FROM WEB INTERFACE 

-- Retrieve stored projextstate data set by web interface
local ret_fileName, vasc_fileName = {}, {}
local ret_actorName, vasc_actorName = {}, {}
local ret_charName, vasc_charName = {}, {}
local ret_text, vasc_text = {}, {}
local ret_direction, vasc_direction = {}, {}
local ret_notes, vasc_notes = {}, {}

local ret_timing, vasc_timing = {}, {}
local ret_efforts, vasc_efforts = {}, {}
local ret_effortType, vasc_effortType = {}, {}
local ret_projection, vasc_projection = {}, {}
local ret_language, vasc_language = {}, {}
local ret_accent, vasc_accent = {}, {}
local ret_emotion, vasc_emotion = {}, {}

local ret_charGender, vasc_charGender = {}, {}
local ret_charAge, vasc_charAge = {}, {}
local ret_charRole, vasc_charRole = {}, {}
local ret_actorGender, vasc_actorGender = {}, {}

local ret_usageRights, vasc_usageRights = {}, {}
local ret_isUnion, vasc_isUnion = {}, {}

local ret_answerFile, vasc_answerFile = {} , {} -- custom vasc ixlm extension containing the file name of the file this take is answering to
local ret_interlocutor, vasc_interlocutor = {} , {} -- custom vasc ixlm extension containing name the the character the take is speaking to (can be self)

local ret_iter, vasc_iter = false, 0

local debug = false


-- METADATA 

local iXML = {}
local iXMLMarkerTbl = {}
-- Fields from VASC interface

iXML["IXML:USER:Embedder"]        = "Embedder"        -- REAPER VASC Tool
iXML["ASWG:contentType"]          = "ASWGcontentType"
iXML["ASWG:project"]              = "ASWGproject"
iXML["ASWG:director"]             = "ASWGdirector"
iXML["ASWG:recEngineer"]          = "ASWGrecEngineer"
iXML["ASWG:originatorStudio"]     = "ASWGoriginatorStudio"
iXML["ASWG:recStudio"]            = "ASWGrecStudio"
iXML["ASWG:micType"]              = "Microphone"

-- Duplicates of existing fields
iXML["ASWG:library"]              = "ASWGproject"

--region ASWG
iXML["ASWG:notes"] = "ASWGnotes"
iXML["ASWG:text"] = "ASWGtext"
iXML["ASWG:efforts"] = "ASWGefforts"
iXML["ASWG:effortType"] = "ASWGeffortType"
iXML["ASWG:projection"] = "ASWGprojection"
iXML["ASWG:language"] = "ASWGlanguage"
iXML["ASWG:timingRestriction"] = "ASWGtimingRestriction"
iXML["ASWG:characterName"] = "ASWGcharacterName"
iXML["ASWG:characterGender"] = "ASWGcharacterGender"
iXML["ASWG:characterAge"] = "ASWGcharacterAge"
iXML["ASWG:characterRole"] = "ASWGcharacterRole"
iXML["ASWG:actorName"] = "ASWGactorName"
iXML["ASWG:actorGender"] = "ASWGactorGender"
iXML["ASWG:direction"] = "ASWGdirection"
iXML["ASWG:accent"] = "ASWGaccent"
iXML["ASWG:emotion"] = "ASWGemotion"
iXML["ASWG:usageRights"] = "ASWGusageRights"
iXML["ASWG:isUnion"] = "ASWGisUnion"
iXML["IXML:USER:AnswerFile"]     = "AnswerFile"      
iXML["IXML:USER:Interlocutor"]   = "Interlocutor"       
iXML["ASWG:fxUsed"] = "ASWGfxUsed"
iXML["ASWG:fxChainName"] = "ASWGfxChainName"
iXML["ASWG:session"] = "ASWGsession"
--endregion


-- Main function to prepare recording, sets up the Reaper session with empty items, regions and tracks
function PrepareRecording()

  reaper.Undo_BeginBlock()
	reaper.PreventUIRefresh(1)

  reaper.SetProjExtState(0,"VASC_WebInterface", "isReaperReady","false")

  if debug == true then reaper.ShowConsoleMsg("PrepareRecording".." \n") end

	ret_iter,             vasc_iter               = reaper.GetProjExtState( 0, "VASC_WebInterface", "Iteration" )
  
  ret_aswg_project,     aswg_project            = reaper.GetProjExtState( 0, "VASC_WebInterface", "ASWGproject")
  -- ret_aswg_session,     aswg_session            = reaper.GetProjExtState( 0, "VASC_WebInterface", "ASWG:session")
  ret_aswg_director,    aswg_director           = reaper.GetProjExtState( 0, "VASC_WebInterface", "ASWGdirector")
  ret_aswg_recEngineer, aswg_recEngineer        = reaper.GetProjExtState( 0, "VASC_WebInterface", "ASWGrecEngineer")
  ret_aswg_origStudio,  aswg_origStudio         = reaper.GetProjExtState( 0, "VASC_WebInterface", "ASWGoriginatorStudio")
  ret_aswg_recStudio,   aswg_recStudio          = reaper.GetProjExtState( 0, "VASC_WebInterface", "ASWGrecStudio")
  ret_mic,              vasc_mic                = reaper.GetProjExtState( 0, "VASC_WebInterface", "MetaMic")

  -- ret_ixml,             vasc_ixml               = reaper.GetProjExtState( 0, "VASC_WebInterface", "iXMLMetadata")
  -- ret_meta,             vasc_meta               = reaper.GetProjExtState( 0, "VASC_WebInterface", "ExtendedMetadata")
  ret_dir,              vasc_dir                = reaper.GetProjExtState( 0, "VASC_WebInterface", "RenderDirectory")

  for i = 1,vasc_iter do
    ret_fileName[i],      vasc_fileName[i]      = reaper.GetProjExtState( 0, "VASC_WebInterface", "fileName"..tostring(i))
    ret_actorName[i],     vasc_actorName[i]     = reaper.GetProjExtState( 0, "VASC_WebInterface", "actorName"..tostring(i))
    ret_charName[i],      vasc_charName[i]      = reaper.GetProjExtState( 0, "VASC_WebInterface", "charName"..tostring(i))
    ret_text[i],          vasc_text[i]          = reaper.GetProjExtState( 0, "VASC_WebInterface", "text"..tostring(i))
    ret_direction[i],     vasc_direction[i]     = reaper.GetProjExtState( 0, "VASC_WebInterface", "direction"..tostring(i))
    ret_notes[i],         vasc_notes[i]         = reaper.GetProjExtState( 0, "VASC_WebInterface", "notes"..tostring(i))
    ret_timing[i],        vasc_timing[i]        = reaper.GetProjExtState( 0, "VASC_WebInterface", "timing"..tostring(i))
    ret_efforts[i],       vasc_efforts[i]       = reaper.GetProjExtState( 0, "VASC_WebInterface", "efforts"..tostring(i))
    ret_effortType[i],    vasc_effortType[i]    = reaper.GetProjExtState( 0, "VASC_WebInterface", "effortType"..tostring(i))
    ret_projection[i],    vasc_projection[i]    = reaper.GetProjExtState( 0, "VASC_WebInterface", "projection"..tostring(i))
    ret_language[i],      vasc_language[i]      = reaper.GetProjExtState( 0, "VASC_WebInterface", "language"..tostring(i))
    ret_accent[i],        vasc_accent[i]        = reaper.GetProjExtState( 0, "VASC_WebInterface", "accent"..tostring(i))
    ret_emotion[i],       vasc_emotion[i]       = reaper.GetProjExtState( 0, "VASC_WebInterface", "emotion"..tostring(i))
    ret_charGender[i],    vasc_charGender[i]    = reaper.GetProjExtState( 0, "VASC_WebInterface", "charGender"..tostring(i))
    ret_charAge[i],       vasc_charAge[i]       = reaper.GetProjExtState( 0, "VASC_WebInterface", "charAge"..tostring(i))
    ret_charRole[i],      vasc_charRole[i]      = reaper.GetProjExtState( 0, "VASC_WebInterface", "charRole"..tostring(i))
    ret_actorGender[i],   vasc_actorGender[i]   = reaper.GetProjExtState( 0, "VASC_WebInterface", "actorGender"..tostring(i))
    ret_usageRights[i],   vasc_usageRights[i]   = reaper.GetProjExtState( 0, "VASC_WebInterface", "usageRights"..tostring(i))
    ret_isUnion[i],       vasc_isUnion[i]       = reaper.GetProjExtState( 0, "VASC_WebInterface", "isUnion"..tostring(i))
    ret_answerFile[i],    vasc_answerFile[i]    = reaper.GetProjExtState( 0, "VASC_WebInterface", "answerFile"..tostring(i))
    ret_interlocutor[i],  vasc_interlocutor[i]  = reaper.GetProjExtState( 0, "VASC_WebInterface", "interlocutor"..tostring(i))
  end        

  -- Display array in console
  if debug == true then
    for index, value in ipairs(vasc_fileName) do
      reaper.ShowConsoleMsg("Display vacs_fileName: ")
      reaper.ShowConsoleMsg("Index: "..tostring(index).." - Value:"..tostring(value).."\n")
    end
  end

  -- Create time selection following user input for Take and Region length
  local userLengthSet, userLength = reaper.GetUserInputs( "Length between takes?", 1, "Value in seconds", "60" )
  if not userLengthSet then 
    reaper.SetProjExtState(0,"VASC_WebInterface", "isReaperReady","false")
    return end 

  reaper.SetProjExtState(0,"VASC_WebInterface", "isReaperReady","true")
  if debug == true then
      reaper.ShowConsoleMsg("VASC_WebInterface / isReaperReady / true ")
  end

  -- Create Smaller array containing a single instance of each charNameacter name for track creation 
  local hash = {}
  local trackNames = {}
  
  for _,v in ipairs(vasc_charName) do
      if (not hash[v]) then
          trackNames[#trackNames+1] = v
          hash[v] = true
      end
  end

  -- Create Tracks for each charNameacters
  for i,_ in ipairs(trackNames) do
    if tostring(trackNames[i]) ~= "" then
    reaper.InsertTrackAtIndex( i-1, true )
    reaper.GetSetMediaTrackInfo_String(reaper.GetTrack( 0, i-1 ), "P_NAME", tostring(trackNames[i]), true )
    end
  end

  reaper.InsertTrackAtIndex( 0, true )
  reaper.GetSetMediaTrackInfo_String(reaper.GetTrack( 0, 0 ), "P_NAME", "VASC_GUIDE", true )
  reaper.SetEditCurPos( 0, true, false )
  reaper.SetOnlyTrackSelected( reaper.GetTrack( 0, 0 ) )
  local itemStartPos = 0
  
  -- Create empty items with data from spreadsheet in notes
  for j = 1,vasc_iter do
    local cursorPos = reaper.GetCursorPosition()
    local timeSelectStart, timeSelectEnd = reaper.GetSet_LoopTimeRange2( 0, true, false, cursorPos, (cursorPos + userLength - 1 ), false )
    reaper.Main_OnCommandEx( 40142, 0, 0 )
    local itemId = reaper.GetMediaItem( 0, j-1 )
    local itemNotes = "Character: "..vasc_charName[j].." \n"
                .."Direction: "..vasc_direction[j].." \n".."Text: "..vasc_text[j] -- "File: "..vasc_fileName[j].." \n"..
    reaper.GetSetMediaItemInfo_String( itemId, "P_NOTES", itemNotes, true )
    reaper.AddProjectMarker2(0, true, timeSelectStart, (timeSelectEnd), vasc_fileName[j], -1, 0)
    iXMLMarkers(cursorPos,j)  -- create values for the mega_marker and META marker for the associated index
    iXMLMarkersEngage(j) -- insert the pair of marker at index
    reaper.SetEditCurPos( (timeSelectEnd + 1), true, true )
  end

  iXMLSetup()
  reaper.SetEditCurPos( 0, true, false )
  reaper.Main_OnCommandEx( 40020, 0, 0 )
  reaper.Main_OnCommandEx( 40289, 0, 0 )

  
  reaper.Undo_EndBlock("VASC", -1)
end

-- iXML Setup -- 

function iXMLSetup()
  -- Copied directly from acendan_Set up SoundMiner iXML metadata markers in project render metadata settings.lua
  -- Sets up Project Render Metadata window with iXML marker values
  for k, v in pairs(iXML) do
    if v == "ReleaseDate" then
      local ret, str = reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|$date", true)
    elseif v == "Embedder" then
      local ret, str = reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|REAPER VASC Tool", true)
    elseif v == "ASWGproject" then
      local ret, str = reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|" .. aswg_project, true)
    elseif v == "ASWGsession" then
      local ret, str = reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|$project", true)
    elseif v == "ASWGdirector" then
      local ret, str = reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|" .. aswg_director, true)
    elseif v == "ASWGrecEngineer" then
      local ret, str = reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|" .. aswg_recEngineer, true)
    elseif v == "ASWGoriginatorStudio" then
      local ret, str = reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|" .. aswg_origStudio, true)
    elseif v == "ASWGrecStudio" then
      local ret, str = reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|" .. aswg_recStudio, true)
    elseif v == "Microphone" then
      local ret, str = reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|" .. vasc_mic, true)
    else
      local ret, str = reaper.GetSetProjectInfo_String( 0, "RENDER_METADATA", k .. "|$marker(" .. v .. ")[;]", true )
    end
  end
end

-- Builds table of markers to setup at location with appropriate iXML info
function iXMLMarkers(position,index)
  local i = index
  local mega_marker = {}
    mega_marker[i] = "META"..tostring(i)
    -- ASWG
    -- mega_marker[i] = mega_marker .. ";" .. "ASWGfxChainName=" .. aswg_fxChainName[i]
    -- mega_marker[i] = mega_marker[i] .. ";" .. "ASWGfxUsed=" .. aswg_fxUsed[i]
    mega_marker[i] = mega_marker[i].. ";" .. "ASWGnotes=" .. vasc_notes[i]
    mega_marker[i] = mega_marker[i].. ";" .. "ASWGtext=" .. vasc_text[i]
    mega_marker[i] = mega_marker[i].. ";" .. "ASWGefforts=" .. vasc_efforts[i]
    mega_marker[i] = mega_marker[i].. ";" .. "ASWGeffortType=" .. vasc_effortType[i]
    mega_marker[i] = mega_marker[i].. ";" .. "ASWGprojection=" .. vasc_projection[i]
    mega_marker[i] = mega_marker[i].. ";" .. "ASWGlanguage=" .. vasc_language[i]
    mega_marker[i] = mega_marker[i].. ";" .. "ASWGtimingRestriction=" .. vasc_timing[i]
    mega_marker[i] = mega_marker[i].. ";" .. "ASWGcharacterName=" .. vasc_charName[i]
    mega_marker[i] = mega_marker[i].. ";" .. "ASWGcharacterGender=" .. vasc_charGender[i]
    mega_marker[i] = mega_marker[i].. ";" .. "ASWGcharacterAge=" .. vasc_charAge[i]
    mega_marker[i] = mega_marker[i].. ";" .. "ASWGcharacterRole=" .. vasc_charRole[i]
    mega_marker[i] = mega_marker[i].. ";" .. "ASWGactorName=" .. vasc_actorName[i]
    mega_marker[i] = mega_marker[i].. ";" .. "ASWGactorGender=" .. vasc_actorGender[i]
    mega_marker[i] = mega_marker[i].. ";" .. "ASWGdirection=" .. vasc_direction[i]
    mega_marker[i] = mega_marker[i] .. ";" .. "ASWGusageRights=" .. vasc_usageRights[i]
    mega_marker[i] = mega_marker[i] .. ";" .. "ASWGisUnion=" .. vasc_isUnion[i]
    mega_marker[i] = mega_marker[i] .. ";" .. "ASWGaccent=" .. vasc_accent[i]
    mega_marker[i] = mega_marker[i] .. ";" .. "ASWGemotion=" .. vasc_emotion[i]
    mega_marker[i] = mega_marker[i] .. ";" .. "AnswerFile=" .. vasc_answerFile[i]
    mega_marker[i] = mega_marker[i] .. ";" .. "Interlocutor=" .. vasc_interlocutor[i]
    
    iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position, mega_marker[i], i}
    iXMLMarkerTbl[#iXMLMarkerTbl+1] = {position + 0.001, "META", i}
end

-- Imports iXML Markers after processing
function iXMLMarkersEngage(index)
  local megaMarkerIndex = (index*2)-1
  local markerMetaIndex = index*2

  local positionMegaMarker = iXMLMarkerTbl[megaMarkerIndex][1]
  local valueMegaMarker = iXMLMarkerTbl[megaMarkerIndex][2]
  local idxMegaMarker = iXMLMarkerTbl[megaMarkerIndex][3]
  reaper.AddProjectMarker( 0, 0, positionMegaMarker, positionMegaMarker, valueMegaMarker, idxMegaMarker )

  local positionMeta = iXMLMarkerTbl[markerMetaIndex][1]
  local valueMeta = iXMLMarkerTbl[markerMetaIndex][2]
  local ixdMeta = iXMLMarkerTbl[markerMetaIndex][3]
  reaper.AddProjectMarker( 0, 0, positionMeta, positionMeta, valueMeta, ixdMeta )
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~ Rets to Bools ~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
function ucsRetsToBool()
  if ret_dir  == 1 then ret_dir  = true else ret_dir  = false end
  
  -- ASWG
  if ret_aswg_project == 1 then ret_aswg_project = true else ret_aswg_project = false end
  if ret_aswg_origStudio == 1 then ret_aswg_origStudio = true else ret_aswg_origStudio = false end
  if ret_aswg_notes == 1 then ret_aswg_notes = true else ret_aswg_notes = false end
  if ret_aswg_fxChainName == 1 then ret_aswg_fxChainName = true else ret_aswg_fxChainName = false end
  if ret_aswg_recEngineer == 1 then ret_aswg_recEngineer = true else ret_aswg_recEngineer = false end
  if ret_aswg_recStudio == 1 then ret_aswg_recStudio = true else ret_aswg_recStudio = false end
  if ret_aswg_text == 1 then ret_aswg_text = true else ret_aswg_text = false end
  if ret_aswg_efforts == 1 then ret_aswg_efforts = true else ret_aswg_efforts = false end
  if ret_aswg_effortType == 1 then ret_aswg_effortType = true else ret_aswg_effortType = false end
  if ret_aswg_projection == 1 then ret_aswg_projection = true else ret_aswg_projection = false end
  if ret_aswg_language == 1 then ret_aswg_language = true else ret_aswg_language = false end
  if ret_aswg_timingRestriction == 1 then ret_aswg_timingRestriction = true else ret_aswg_timingRestriction = false end
  if ret_aswg_characterName == 1 then ret_aswg_characterName = true else ret_aswg_characterName = false end
  if ret_aswg_characterGender == 1 then ret_aswg_characterGender = true else ret_aswg_characterGender = false end
  if ret_aswg_characterAge == 1 then ret_aswg_characterAge = true else ret_aswg_characterAge = false end
  if ret_aswg_characterRole == 1 then ret_aswg_characterRole = true else ret_aswg_characterRole = false end
  if ret_aswg_actorName == 1 then ret_aswg_actorName = true else ret_aswg_actorName = false end
  if ret_aswg_actorGender == 1 then ret_aswg_actorGender = true else ret_aswg_actorGender = false end
  if ret_aswg_direction == 1 then ret_aswg_direction = true else ret_aswg_direction = false end
  if ret_aswg_director == 1 then ret_aswg_director = true else ret_aswg_director = false end
  if ret_aswg_fxUsed == 1 then ret_aswg_fxUsed = true else ret_aswg_fxUsed = false end
  if ret_aswg_usageRights == 1 then ret_aswg_usageRights = true else ret_aswg_usageRights = false end
  if ret_aswg_isUnion == 1 then ret_aswg_isUnion = true else ret_aswg_isUnion = false end
  if ret_aswg_accent == 1 then ret_aswg_accent = true else ret_aswg_accent = false end
  if ret_aswg_emotion == 1 then ret_aswg_emotion = true else ret_aswg_emotion = false end
end


-- Open Web Interface
function openVASCWebInterface()
  local web_int_settings = getWebInterfaceSettings()
  local localhost = "http://localhost:"
  local vasc_path = ""
  
  for _, line in pairs(web_int_settings) do
    if line:find("timbert_VASC.html") then
      local port = getPort(line)
      vasc_path = localhost .. port
    end
  end
  
  if vasc_path ~= "" then
    openURL(vasc_path)
  else
    local response = reaper.MB("VASC not found in Reaper Web Interface settings!\n\nWould you like to open the installation tutorial video?","Open VASC Tool",4)
    if response == 6 then end
  end
end

-- Open a webpage or file directiontory
function openURL(path)
  reaper.CF_ShellExecute(path)
end

-- Get web interface info from REAPER.ini // returns Table
function getWebInterfaceSettings()
  local ini_file = reaper.get_ini_file()
  local ret, num_webs = reaper.BR_Win32_GetPrivateProfileString( "reaper", "csurf_cnt", "", ini_file )
  local t = {}
  if ret then
    for i = 0, num_webs do
      local ret, web_int = reaper.BR_Win32_GetPrivateProfileString( "reaper", "csurf_" .. i, "", ini_file )
      table.insert(t, web_int)
    end
  end
  return t
end

-- Get localhost port from reaper.ini file line
function getPort(line)
  local port = line:sub(line:find(" ")+3,line:find("'")-2)
  return port
end

function main() -- Run tests to ensure the web interface is properly used before preparing the reaper session with PrepareRecording()
  if not reaper.JS_Dialog_BrowseForSaveFile then
    reaper.MB("Please install the JS_ReaScriptAPI REAPER extension, available in ReaPack, under the ReaTeam Extensions repository.\n\nExtensions > ReaPack > Browse Packages\n\nFilter for 'JS_ReascriptAPI'. Right click to install."
      , "VASC Tool", 0)
    return
  end

  if not reaper.HasExtState("VASC_WebInterface", "runFromWeb") then
    -- NO EXTSTATE FOUND, OPEN INTERFACE
    if debug == true then reaper.ShowConsoleMsg("Break01 : has ExtState? " ..reaper.HasExtState("VASC_WebInterface", "runFromWeb") .. " \n") end
    openVASCWebInterface()
    return
  end

  if reaper.GetExtState("VASC_WebInterface", "runFromWeb") == "false" then
    -- NO EXTSTATE FOUND, OPEN INTERFACE
    if debug == true then reaper.ShowConsoleMsg("Break01 : runFromWeb ? " ..reaper.GetExtState("VASC_WebInterface", "runFromWeb") .. " \n") end
    openVASCWebInterface()
    return
  end

  -- RUN FROM WEB INTERFACE, EXECUTE SCRIPT
  if debug == true then reaper.ShowConsoleMsg("Break01 : runFromWeb ? " .. reaper.GetExtState("VASC_WebInterface", "runFromWeb") .. " \n") end
  reaper.SetExtState("VASC_WebInterface", "runFromWeb", "false", true)


  if not reaper.HasExtState("VASC_WebInterface", "inputTableExists") then
    -- NO EXTSTATE FOUND
    if debug == true then reaper.ShowConsoleMsg("Break02 : no ExtState inputTableExists " .. " \n") end
    return
  end

  if reaper.GetExtState("VASC_WebInterface", "inputTableExists") == "false" then
    -- INPUT TABLE IS NOT IMPORTED, DO
    if debug == true then reaper.ShowConsoleMsg("Break02 : inputTableExists? "..reaper.GetExtState("VASC_WebInterface", "inputTableExists") .. " \n") end
    return
  end

  if debug == true then  reaper.ShowConsoleMsg("Break02 : inputTableExists? "..reaper.GetExtState("VASC_WebInterface", "inputTableExists") .. " \n") end

  if not reaper.HasExtState("VASC_WebInterface", "conformTableRows") then
    -- NO EXTSTATE FOUND
    if debug == true then reaper.ShowConsoleMsg("Break03 : no ExtState conformTableRows " .. " \n") end
    return
  end

  if reaper.GetExtState("VASC_WebInterface", "conformTableRows") == "false" then
    -- INPUT TABLE IS NOT IMPORTED, DO
    if debug == true then reaper.ShowConsoleMsg("Break03 : conformTableRows? "..reaper.GetExtState("VASC_WebInterface", "conformTableRows") .. " \n") end
    return
  end

  if debug == true then reaper.ShowConsoleMsg("Break03 : conformTableRows? "..reaper.GetExtState("VASC_WebInterface", "conformTableRows") .. " \n") end
  PrepareRecording()
  reaper.SetExtState( "UCS_WebInterface", "conformTableRows", "false", true )
end

if debug == true then 
  reaper.ShowConsoleMsg("")
  reaper.ShowConsoleMsg("Start of Script".." \n") 
end

main()

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
