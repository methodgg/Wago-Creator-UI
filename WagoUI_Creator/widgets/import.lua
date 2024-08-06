---@class WagoUICreator
local addon = select(2, ...)
local DF = _G["DetailsFramework"]
local LAP = LibStub:GetLibrary("LibAddonProfiles")
local lapModules = LAP:GetAllModules()
local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")

local importFrame
local feedbackString = ""

local IMPORT_EXPORT_EDIT_MAX_BYTES = 0 --1024000*4 -- 0 appears to be "no limit"

local function findMatchingModule(profileString)
  local genericPKey, genericProfile, genericRaw, genericModuleName = LAP:GenericDecode(profileString)
  for moduleName, module in pairs(lapModules) do
    if module.testImport then
      feedbackString = feedbackString.."Testing import string for "..moduleName.."...\n"
      importFrame.editbox:SetText(feedbackString)
      local profileKey = module.testImport(profileString, genericPKey, genericProfile, genericRaw, genericModuleName)
      coroutine.yield()
      if profileKey then
        return moduleName, module, profileKey
      end
    end
  end
end

local function testImport(profileString)
  local moduleName, module, profileKey = findMatchingModule(profileString)
  if moduleName then
    return moduleName, module, profileKey
  end
end

local function onSuccessfulTest(moduleName, module, profileKey, profileString)
  local isLoaded = module.isLoaded and module.isLoaded()
  local isDuplicate = isLoaded and module.isDuplicate and module.isDuplicate(profileKey)

  local moduleConfig = addon.ModuleFunctions:GetModuleByName(moduleName)
  if isLoaded and moduleConfig.onSuccessfulTestOverride then
    moduleConfig.onSuccessfulTestOverride(profileString, profileKey)
    importFrame:Hide()
    return
  end

  --we expect profileKey to be a string from here
  if type(profileKey) ~= "string" then
    profileKey = ""
  end

  local color = isLoaded and "00FF00" or "FFFF00"
  local notLoadedText = isLoaded and "" or " but the AddOn is not loaded"
  feedbackString = string.format("|cFF%sImport string is %s profile%s|r", color, moduleName, notLoadedText)
  importFrame.editbox:SetText(feedbackString)

  local icon = importFrame.icon
  if isLoaded then icon:Enable() else icon:Disable() end
  icon:Show()
  icon:SetTexture(module.icon)
  icon:SetPushedTexture(module.icon)
  icon:SetDisabledTexture(module.icon)
  icon:SetHighlightAtlas(module.slash and "bags-glow-white" or "")
  icon:SetTooltip(module.slash and "Click to open "..module.moduleName.." options" or nil)
  icon:SetScript("OnClick", function()
    if module.slash then
      addon:FireUnprotectedSlashCommand(module.slash)
    end
  end)

  local confirmButton = importFrame.confirmButton
  if isLoaded then
    confirmButton:Enable()
    confirmButton:SetText("Import Profile")
  else
    confirmButton:Disable()
    confirmButton:SetText("Not Loaded")
  end
  confirmButton:Show()
  confirmButton:SetClickFunction(function(self)
    self:Disable()
    addon:Async(function()
      local tempProfileKey = profileKey
      if module.needProfileKey or isDuplicate and not module.preventRename then
        tempProfileKey = importFrame.profileNameInput:GetText()
      end

      local importClickCallback = function()
        module.importProfile(profileString, tempProfileKey, false)
        feedbackString = string.format("\n\n|cFF00FF00Profile %s successfully imported into %s|r", tempProfileKey,
          moduleName)
        if module.needReloadOnImport then
          feedbackString = feedbackString.."\n\n|cFFFFFF00You need to reload your UI for the changes to take effect|r"
        end
        importFrame.editbox:SetText(feedbackString)
        --editmode hides all frames in UISpecialFrames
        if moduleName == "EditMode" then
          addon:ShowFrame()
          importFrame:Show()
        end
      end
      importClickCallback()
    end, "importFrameConfirmButtonClick")
  end)


  if isDuplicate then
    feedbackString = feedbackString..
        string.format(
          "\n\n|cFFFF0000A profile with name '%s' already exists|r",
          profileKey)
    importFrame.editbox:SetText(feedbackString)
  end

  if module.needProfileKey or (isDuplicate and not module.preventRename) then
    if not isDuplicate then confirmButton:Disable() end
    importFrame.profileNameLabel:Show()
    importFrame.profileNameInput:Show()
    importFrame.profileNameInput:SetText(profileKey)
    importFrame.profileNameInput:SetFocus()
    if isDuplicate then
      profileKey = ""
    end
  else
    importFrame.profileNameLabel:Hide()
    importFrame.profileNameInput:Hide()
    local profileKeyLabel = importFrame.profileKeyLabel
    profileKeyLabel:SetText(profileKey ~= "" and moduleName..": "..profileKey or "")
    profileKeyLabel:Show()
  end
end

local function createImportFrame()
  importFrame = addon:CreateGenericTextFrame(600, 400, "Profile Import")
  local editbox = importFrame.editbox

  local scrollframe = importFrame.scrollframe
  scrollframe:ClearAllPoints()
  scrollframe:SetPoint("TOPLEFT", importFrame, "TOPLEFT", 5, -25)
  scrollframe:SetPoint("BOTTOMRIGHT", importFrame, "BOTTOMRIGHT", -23, 90)

  ---@diagnostic disable-next-line: undefined-field
  local instructionLabel = DF:CreateLabel(importFrame, "Paste any profile string", 26, "grey")
  instructionLabel:SetTextColor(0.5, 0.5, 0.5, 1)
  instructionLabel:SetJustifyH("CENTER")
  instructionLabel:SetPoint("CENTER", importFrame.scrollframe, "CENTER", 0, 0)
  importFrame.instructionLabel = instructionLabel

  local buttonSize = 40

  ---@diagnostic disable-next-line: undefined-field
  local icon = DF:CreateButton(importFrame, nil, 42, 42, "", nil, nil, 134400, nil, nil, nil, nil)
  icon:SetPoint("BOTTOMLEFT", importFrame, "BOTTOMLEFT", 20, 24)
  icon:Hide()
  importFrame.icon = icon

  ---@diagnostic disable-next-line: undefined-field
  local confirmButton = DF:CreateButton(importFrame, nil, 200, buttonSize, "", nil, nil, nil, nil, nil, nil,
    options_dropdown_template)
  confirmButton:SetPoint("LEFT", icon, "RIGHT", 10, 0)
  confirmButton.text_overlay:SetFont(confirmButton.text_overlay:GetFont(), 20)
  confirmButton:Hide()
  importFrame.confirmButton = confirmButton

  ---@diagnostic disable-next-line: undefined-field
  local profileKeyLabel = DF:CreateLabel(importFrame, "", 16, "white")
  profileKeyLabel:SetJustifyH("CENTER")
  profileKeyLabel:SetPoint("LEFT", confirmButton, "RIGHT", 10, 0)
  profileKeyLabel:Hide()
  importFrame.profileKeyLabel = profileKeyLabel

  ---@diagnostic disable-next-line: undefined-field
  local profileNameInput = DF:CreateTextEntry(importFrame, function() end, 200, 30, "UIMProfileNameInput",
    nil, nil, options_dropdown_template)
  profileNameInput:SetPoint("LEFT", confirmButton, "RIGHT", 10, 0)
  profileNameInput:Hide()
  profileNameInput:SetScript("OnTextChanged", function(self, isUserInput)
    if isUserInput then
      local text = self:GetText()
      if text and string.len(text) >= 2 then
        confirmButton:Enable()
      else
        confirmButton:Disable()
      end
    end
  end)
  profileNameInput:HookScript("OnEnterPressed", function(self)
    if confirmButton:IsEnabled() then
      confirmButton:Click()
    end
  end)
  importFrame.profileNameInput = profileNameInput

  ---@diagnostic disable-next-line: undefined-field
  local profileNameLabel = DF:CreateLabel(importFrame, "Profile Name:",
    DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
  profileNameLabel:SetPoint("bottomleft", profileNameInput, "topleft", 0, 2)
  profileNameLabel:Hide()
  importFrame.profileNameLabel = profileNameLabel

  local pasteBuffer, pasteCharCount, isPasting = {}, 0, false

  local function clearBuffer(self)
    self:SetScript('OnUpdate', nil)
    editbox:SetMaxBytes(IMPORT_EXPORT_EDIT_MAX_BYTES)
    isPasting = false
    importFrame.icon:Hide()
    importFrame.confirmButton:Hide()
    importFrame.profileKeyLabel:Hide()
    importFrame.profileNameInput:Hide()
    importFrame.profileNameLabel:Hide()
    if pasteCharCount > 10 then
      local profileString = strtrim(table.concat(pasteBuffer))
      addon:Async(function()
        editbox:Disable()
        editbox:ClearFocus()
        instructionLabel:Hide()
        feedbackString = ""
        editbox:SetText(string.sub(profileString, 1, 2000))
        local moduleName, module, profileKey = testImport(profileString)
        if moduleName then
          onSuccessfulTest(moduleName, module, profileKey, profileString)
        else
          feedbackString = "\n|cFFFF0000Profile string is invalid|r"
          editbox:SetText(feedbackString)
          editbox:SetFocus()
        end
        editbox:Enable()
      end, "importBoxOnTextChanged")
    end
  end

  editbox:SetScript('OnChar', function(self, c)
    if not isPasting then
      if editbox:GetMaxBytes() ~= 1 then -- ensure this for performance!
        editbox:SetMaxBytes(1)
      end
      pasteBuffer, pasteCharCount, isPasting = {}, 0, true
      self:SetScript('OnUpdate', clearBuffer) -- clearBuffer on next frame
    end
    pasteCharCount = pasteCharCount + 1
    pasteBuffer[pasteCharCount] = c
  end)

  editbox:SetScript('OnKeyUp', function(_, key)
    if key == "ESCAPE" then
      importFrame:Hide()
    end
  end)
  addon.importFrame = importFrame
end

function addon:StartProfileImport()
  if not importFrame then createImportFrame() end
  if addon.exportFrame then addon.exportFrame.Close:Click() end
  importFrame:SetPoint("CENTER", addon.frames.mainFrame, "CENTER")
  importFrame:Show()
  importFrame.editbox:SetText("")
  importFrame.editbox:SetFocus()
  importFrame.icon:Hide()
  importFrame.confirmButton:Hide()
  importFrame.profileKeyLabel:Hide()
  importFrame.profileNameLabel:Hide()
  importFrame.profileNameInput:Hide()
  importFrame.instructionLabel:Show()
end
