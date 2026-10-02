---@diagnostic disable: undefined-field, inject-field
---@type string
local addonName = ...
---@class WagoUI
local addon = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")
local L = addon.L

-- handle most errors internally and provide an easy way for users to report these errors

local caughtErrors = {}

local function getActivePackDiagnostics()
  local packId = addon.dbC and addon.dbC.selection and addon.dbC.selection.packID
  if not packId then
    return "None", nil, nil
  end

  local pack = addon:GetPack(packId)
  local packName = type(pack) == "table" and pack.name or nil
  return packId, packName, addon.dbC.selection.variationID
end

local function getDiagnostics()
  local addonVersion = C_AddOns.GetAddOnMetadata(addonName, "Version")
  local locale = GetLocale()
  local dateString = date("%d/%m/%y %H:%M:%S")
  local gameVersion = select(4, GetBuildInfo())
  local name, realm = UnitFullName("player")
  local regionId = GetCurrentRegion()
  local regions = {
    [1] = "US",
    [2] = "Korea",
    [3] = "Europe",
    [4] = "Taiwan",
    [5] = "China",
    [72] = "PTR"
  }
  local region = regions[regionId]
  local combatState = InCombatLockdown() and "In combat" or "Out of combat"
  local mapID = C_Map.GetBestMapForUnit("player")
  local mapInfo = mapID and C_Map.GetMapInfo(mapID)
  local zoneInfo = format("Zone: %s (%d)", mapInfo and mapInfo.name or "Unknown", mapID or 0)
  local activePackId, activePackName, activePackResolution = getActivePackDiagnostics()
  return {
    addonVersion = addonVersion,
    locale = locale,
    dateString = dateString,
    gameVersion = gameVersion,
    name = name,
    realm = realm,
    region = region,
    combatState = combatState,
    zoneInfo = zoneInfo,
    activePackId = activePackId,
    activePackName = activePackName,
    activePackResolution = activePackResolution
  }
end

local hasShown = false

function addon:DisplayErrors(force)
  if not force and hasShown then
    return
  end
  hasShown = true
  if #caughtErrors == 0 then
    return
  end

  local function startCopyAction(editBox, copyButton, text)
    editBox:HighlightText(0, string.len(text))
    editBox:SetFocus()
    copyButton:SetDisabled(true)
    ---@diagnostic disable-next-line: invisible
    addon.copyHelper:SmartShow(addon.errorFrame.frame, 0, 0)
  end

  local function stopCopyAction(copyButton)
    copyButton:SetDisabled(false)
    addon.copyHelper:SmartHide()
  end

  local errorBoxText = ""

  if not addon.errorFrame then
    addon.errorFrame = AceGUI:Create("Frame")
    local errorFrameName = addonName .. "ErrorFrame"
    ---@diagnostic disable-next-line: invisible
    _G[errorFrameName] = addon.errorFrame.frame
    table.insert(UISpecialFrames, errorFrameName)
    local errorFrame = addon.errorFrame
    errorFrame:EnableResize(false)
    errorFrame:SetWidth(800)
    errorFrame:SetHeight(600)
    errorFrame:EnableResize(false)
    errorFrame:SetLayout("Flow")
    errorFrame:SetCallback(
      "OnClose",
      function(widget)
      end
    )
    errorFrame:SetTitle(L["Addon Error"])
    errorFrame.label = AceGUI:Create("Label")
    errorFrame.label:SetWidth(800)
    errorFrame.label:SetFontObject("GameFontNormalLarge")
    errorFrame.label.label:SetTextColor(1, 0, 0)
    errorFrame.label:SetText(L["Error Label 1"] .. "\n" .. L["Error Label 2"] .. "\n" .. L["Error Label 3"])
    errorFrame:AddChild(errorFrame.label)

    for _, dest in ipairs(addon.externalLinks) do
      errorFrame[dest.name .. "EditBox"] = AceGUI:Create("EditBox")
      local editBox = errorFrame[dest.name .. "EditBox"]
      addon:StyleEditBox(editBox.editbox)
      local copyButton
      editBox:SetLabel(dest.name .. ":")
      editBox:DisableButton(true)
      editBox:SetText(dest.url)
      editBox:SetCallback(
        "OnTextChanged",
        function()
          editBox:SetText(dest.url)
        end
      )

      editBox:SetWidth(400)
      editBox.editbox:HookScript(
        "OnEditFocusLost",
        function()
          stopCopyAction(copyButton)
        end
      )
      editBox.editbox:SetScript(
        "OnKeyUp",
        function(_, key)
          if (addon.copyHelper:WasControlKeyDown() and key == "C") then
            addon.copyHelper:SmartFadeOut()
            editBox:ClearFocus()
          else
            addon.copyHelper:SmartHide()
          end
        end
      )
      errorFrame[dest.name .. "CopyButton"] = AceGUI:Create("Button")
      copyButton = errorFrame[dest.name .. "CopyButton"]
      copyButton:SetText(L["Copy"])
      copyButton:SetWidth(100)
      copyButton:SetCallback(
        "OnClick",
        function(widget, callbackName, value)
          startCopyAction(editBox, copyButton, dest.url)
        end
      )
      errorFrame:AddChild(editBox)
      errorFrame:AddChild(copyButton)
    end

    local errorBox, errorBoxCopyButton
    errorFrame.errorBox = AceGUI:Create("MultiLineEditBox")
    errorBox = errorFrame.errorBox
    addon:StyleEditBox(errorBox.editBox, errorBox.scrollBG)
    errorBox:SetWidth(800)
    errorBox:SetLabel(L["Error Message"] .. ":")
    errorBox:DisableButton(true)
    errorBox:SetNumLines(20)
    errorBox:SetCallback(
      "OnTextChanged",
      function()
        errorBox:SetText(errorBoxText)
      end
    )
    errorBox.editBox:HookScript(
      "OnEditFocusLost",
      function()
        stopCopyAction(errorBoxCopyButton)
      end
    )
    errorBox.editBox:SetScript(
      "OnKeyUp",
      function(_, key)
        if (addon.copyHelper:WasControlKeyDown() and key == "C") then
          addon.copyHelper:SmartFadeOut()
          errorBox:ClearFocus()
        else
          addon.copyHelper:SmartHide()
        end
      end
    )

    errorFrame.errorBoxCopyButton = AceGUI:Create("Button")
    errorBoxCopyButton = errorFrame.errorBoxCopyButton
    errorBoxCopyButton:SetText(L["Copy error"])
    errorBoxCopyButton:SetHeight(40)
    errorBoxCopyButton:SetCallback(
      "OnClick",
      function(widget, callbackName, value)
        startCopyAction(errorFrame.errorBox, errorBoxCopyButton, errorBoxText)
      end
    )

    errorFrame:AddChild(errorFrame.errorBox)
    errorFrame:AddChild(errorFrame.errorBoxCopyButton)
    addon:ApplyFont(errorFrame.frame)
  end

  for _, error in ipairs(caughtErrors) do
    errorBoxText = errorBoxText .. error.count .. "x: " .. error.message .. "\n"
  end
  --add diagnostics
  local diagnostics = getDiagnostics()
  errorBoxText =
    errorBoxText ..
    "\n" ..
      diagnostics.dateString ..
        "\naddon: " ..
          diagnostics.addonVersion ..
            "\nClient: " ..
              diagnostics.gameVersion ..
                " " ..
                  diagnostics.locale ..
                    "\nCharacter: " .. diagnostics.name .. "-" .. diagnostics.realm .. " (" .. diagnostics.region .. ")"
  errorBoxText = errorBoxText .. "\nUI Pack: " .. diagnostics.activePackId
  if diagnostics.activePackName and diagnostics.activePackName ~= diagnostics.activePackId then
    errorBoxText = errorBoxText .. " [" .. diagnostics.activePackName .. "]"
  end
  if diagnostics.activePackResolution then
    errorBoxText = errorBoxText .. " / " .. diagnostics.activePackResolution
  end
  errorBoxText = errorBoxText .. "\n" .. diagnostics.combatState .. "\n" .. diagnostics.zoneInfo .. "\n"
  errorBoxText = errorBoxText .. "\nStacktraces\n\n"
  for _, error in ipairs(caughtErrors) do
    errorBoxText = errorBoxText .. error.stackTrace .. "\n"
  end

  addon.errorFrame.errorBox:SetText(errorBoxText)
  addon.errorFrame:Show()
end

local numError = 0
local currentFunc = ""
local addTrace = false
local function onError(msg, stackTrace, name)
  numError = numError + 1
  local funcName = name or currentFunc
  local e = funcName .. ": " .. msg
  -- return early on duplicate errors
  for _, error in pairs(caughtErrors) do
    if error.message == e then
      error.count = error.count + 1
      addTrace = false
      return false
    end
  end
  local stackTraceValue = stackTrace and name .. ":\n" .. stackTrace
  table.insert(caughtErrors, {message = e, stackTrace = stackTraceValue, count = 1})
  addTrace = true
  local diagnostics = getDiagnostics()
  local diagnosticString =
    diagnostics.dateString ..
    "\naddon: " ..
      diagnostics.addonVersion ..
        "\nClient: " .. diagnostics.gameVersion .. " " .. diagnostics.locale .. "\n" .. diagnostics.region
  diagnosticString = diagnosticString .. "\nUI Pack: " .. diagnostics.activePackId
  if diagnostics.activePackName and diagnostics.activePackName ~= diagnostics.activePackId then
    diagnosticString = diagnosticString .. " [" .. diagnostics.activePackName .. "]"
  end
  if diagnostics.activePackResolution then
    diagnosticString = diagnosticString .. " / " .. diagnostics.activePackResolution
  end
  -- addon.WagoAnalytics:Error(e..diagnosticString)
  if addon.errorTimer then
    addon.errorTimer:Cancel()
  end
  addon.errorTimer =
    C_Timer.NewTimer(
    0.5,
    function()
      addon:DisplayErrors(true)
    end
  )
  --if spam erroring then show errors early otherwise risk error display never showing
  if numError > 100 then
    addon:DisplayErrors(true)
  end
  return false
end

--accessible function for errors in coroutines
function addon:OnError(msg, stackTrace, name)
  onError(msg, stackTrace, name)
end

function addon:GetErrors()
  return caughtErrors
end

function addon:TestErrorHandling()
  addon:Async(
    function()
      addon:NonExistingFunctionFromAsync()
    end,
    "asyncErrorTest"
  )
  addon:NonExistingFunction()
end
