---@class WagoUICreator
local addon = select(2, ...)
local DF = _G["DetailsFramework"]
local LWF = LibStub("LibWagoFramework")
local LAP = LibStub:GetLibrary("LibAddonProfiles")
local lapModules = LAP:GetAllModules()
local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")

local importFrame
local feedbackString = ""

local IMPORT_EXPORT_EDIT_MAX_BYTES = 0 --1024000*4 -- 0 appears to be "no limit"

---@param profileString string
---@return string | nil moduleName
---@return LibAddonProfilesModule | nil module
---@return string | table | nil profileKey
local function findMatchingModule(profileString)
  local genericPKey, genericProfile, genericRaw, genericModuleName = LAP:GenericDecode(profileString)
  for moduleName, lapModule in pairs(lapModules) do
    if lapModule.testImport then
      feedbackString = feedbackString .. "Testing import string for " .. moduleName .. "...\n"
      importFrame.editbox:SetText(feedbackString)
      local profileKey = lapModule:testImport(profileString, genericPKey, genericProfile, genericRaw, genericModuleName)
      coroutine.yield()
      if profileKey then
        return moduleName, lapModule, profileKey
      end
    end
  end
end

---@param profileString string
---@return string | nil moduleName
---@return LibAddonProfilesModule | nil module
---@return string | table | nil profileKey
local function testImport(profileString)
  local moduleName, module, profileKey = findMatchingModule(profileString)
  if moduleName then
    return moduleName, module, profileKey
  end
end

---@param moduleName string
---@param lapModule LibAddonProfilesModule
---@param profileKey string | table
---@param profileString string
local function onSuccessfulTest(moduleName, lapModule, profileKey, profileString)
  local isLoaded = lapModule:isLoaded()
  local keyType = type(profileKey)
  local isDuplicate = isLoaded and keyType == "string" and lapModule.isDuplicate and lapModule:isDuplicate(profileKey)

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
  if isLoaded then
    icon:Enable()
  else
    icon:Disable()
  end
  icon:Show()
  icon:SetTexture(lapModule.icon)
  icon:SetPushedTexture(lapModule.icon)
  icon:SetDisabledTexture(lapModule.icon)
  icon:SetHighlightAtlas(lapModule.slash and "bags-glow-white" or "")
  icon:SetTooltip(lapModule.slash and "Click to open " .. lapModule.moduleName .. " options" or nil)
  icon:SetScript(
    "OnClick",
    function()
      if lapModule.slash then
        addon:FireUnprotectedSlashCommand(lapModule.slash)
      end
    end
  )

  local confirmButton = importFrame.confirmButton
  if isLoaded then
    confirmButton:Enable()
    confirmButton:SetText("Import Profile")
  else
    confirmButton:Disable()
    confirmButton:SetText("Not Loaded")
  end
  confirmButton:Show()
  confirmButton:SetClickFunction(
    function(self)
      self:Disable()
      addon:Async(
        function()
          local tempProfileKey = profileKey
          if lapModule.needProfileKey or isDuplicate and not lapModule.preventRename then
            tempProfileKey = importFrame.profileNameInput:GetText()
          end

          local importClickCallback = function()
            lapModule:importProfile(profileString, tempProfileKey, false)
            feedbackString =
              string.format("\n\n|cFF00FF00Profile %s successfully imported into %s|r", tempProfileKey, moduleName)
            if lapModule.needReloadOnImport then
              feedbackString =
                feedbackString .. "\n\n|cFFFFFF00You need to reload your UI for the changes to take effect|r"
            end
            importFrame.editbox:SetText(feedbackString)
            --editmode hides all frames in UISpecialFrames
            if moduleName == "EditMode" then
              addon:ShowFrame()
              importFrame:Show()
            end
          end
          importClickCallback()
        end,
        "importFrameConfirmButtonClick"
      )
    end
  )

  if isDuplicate then
    feedbackString =
      feedbackString .. string.format("\n\n|cFFFF0000A profile with name '%s' already exists|r", profileKey)
    importFrame.editbox:SetText(feedbackString)
  end

  if lapModule.needProfileKey or (isDuplicate and not lapModule.preventRename) then
    if not isDuplicate then
      confirmButton:Disable()
    end
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
    profileKeyLabel:SetText(profileKey ~= "" and moduleName .. ": " .. profileKey or "")
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

  local instructionLabel = DF:CreateLabel(importFrame, "Paste any profile string", 26, "grey")
  instructionLabel:SetTextColor(0.5, 0.5, 0.5, 1)
  instructionLabel:SetJustifyH("CENTER")
  instructionLabel:SetPoint("CENTER", importFrame.scrollframe, "CENTER", 0, 0)
  importFrame.instructionLabel = instructionLabel

  local buttonSize = 40

  local icon = DF:CreateButton(importFrame, nil, 42, 42, "", nil, nil, 134400, nil, nil, nil, nil)
  icon:SetPoint("BOTTOMLEFT", importFrame, "BOTTOMLEFT", 20, 24)
  icon:Hide()
  importFrame.icon = icon

  local confirmButton = LWF:CreateButton(importFrame, 200, buttonSize, "", 20)
  confirmButton:SetPoint("LEFT", icon, "RIGHT", 10, 0)
  confirmButton:Hide()
  importFrame.confirmButton = confirmButton

  local profileKeyLabel = DF:CreateLabel(importFrame, "", 16, "white")
  profileKeyLabel:SetJustifyH("CENTER")
  profileKeyLabel:SetPoint("LEFT", confirmButton, "RIGHT", 10, 0)
  profileKeyLabel:Hide()
  importFrame.profileKeyLabel = profileKeyLabel

  local profileNameInput =
    LWF:CreateTextEntry(
    importFrame,
    200,
    20,
    function()
    end
  )
  profileNameInput:SetPoint("LEFT", confirmButton, "RIGHT", 10, 0)
  profileNameInput:Hide()
  profileNameInput:SetScript(
    "OnTextChanged",
    function(self, isUserInput)
      if isUserInput then
        local text = self:GetText()
        if text and string.len(text) >= 2 then
          confirmButton:Enable()
        else
          confirmButton:Disable()
        end
      end
    end
  )
  profileNameInput:HookScript(
    "OnEnterPressed",
    function(self)
      if confirmButton:IsEnabled() then
        confirmButton:Click()
      end
    end
  )
  importFrame.profileNameInput = profileNameInput

  local profileNameLabel = DF:CreateLabel(importFrame, "Profile Name:", DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
  profileNameLabel:SetPoint("bottomleft", profileNameInput, "topleft", 0, 2)
  profileNameLabel:Hide()
  importFrame.profileNameLabel = profileNameLabel

  local pasteBuffer, pasteCharCount, isPasting = {}, 0, false

  local function clearBuffer(self)
    self:SetScript("OnUpdate", nil)
    editbox:SetMaxBytes(IMPORT_EXPORT_EDIT_MAX_BYTES)
    isPasting = false
    importFrame.icon:Hide()
    importFrame.confirmButton:Hide()
    importFrame.profileKeyLabel:Hide()
    importFrame.profileNameInput:Hide()
    importFrame.profileNameLabel:Hide()
    if pasteCharCount > 10 then
      local profileString = strtrim(table.concat(pasteBuffer))
      addon:Async(
        function()
          editbox:Disable()
          editbox:ClearFocus()
          instructionLabel:Hide()
          feedbackString = ""
          editbox:SetText(string.sub(profileString, 1, 2000))
          local moduleName, module, profileKey = testImport(profileString)
          if moduleName and module and profileKey then
            --TODO: No idea why profileKey would not match the type here
            ---@diagnostic disable-next-line: param-type-mismatch
            onSuccessfulTest(moduleName, module, profileKey, profileString)
          else
            feedbackString = "\n|cFFFF0000Profile string is invalid|r"
            editbox:SetText(feedbackString)
            editbox:SetFocus()
          end
          editbox:Enable()
        end,
        "importBoxOnTextChanged"
      )
    end
  end

  editbox:SetScript(
    "OnChar",
    function(self, c)
      if not isPasting then
        if editbox:GetMaxBytes() ~= 1 then -- ensure this for performance!
          editbox:SetMaxBytes(1)
        end
        pasteBuffer, pasteCharCount, isPasting = {}, 0, true
        self:SetScript("OnUpdate", clearBuffer) -- clearBuffer on next frame
      end
      pasteCharCount = pasteCharCount + 1
      pasteBuffer[pasteCharCount] = c
    end
  )

  editbox:SetScript(
    "OnKeyUp",
    function(_, key)
      if key == "ESCAPE" then
        importFrame:Hide()
      end
    end
  )
  addon.importFrame = importFrame
end

function addon:StartProfileImport()
  if not importFrame then
    createImportFrame()
  end
  if addon.exportFrame then
    addon.exportFrame.Close:Click()
  end
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
