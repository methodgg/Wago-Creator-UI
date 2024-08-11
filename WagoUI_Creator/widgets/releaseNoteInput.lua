---@class WagoUICreator
local addon = select(2, ...)
local L = addon.L
local DF = _G["DetailsFramework"]
local LWF = LibStub("LibWagoFramework")

local releaseNotesFrame

function addon:CreateReleaseNoteInput()
  releaseNotesFrame = addon:CreateGenericTextFrame(600, 350, "Release Notes")
  releaseNotesFrame:SetFrameLevel(105)
  releaseNotesFrame.Close:SetScript("OnClick", function()
    releaseNotesFrame:Hide()
  end)
  local editbox = releaseNotesFrame.editbox
  editbox:SetAutoFocus(false)
  editbox:SetScript('OnKeyUp', function(_, key)
    if key == "ESCAPE" then
      releaseNotesFrame:Hide()
    end
  end)
  addon.exportFrame = releaseNotesFrame
  editbox:SetFontObject(GameFontNormalLarge)
  releaseNotesFrame.scrollframe:SetPoint("BOTTOMRIGHT", releaseNotesFrame, "BOTTOMRIGHT", -23, 125)

  local explainerLabel = DF:CreateLabel(releaseNotesFrame, L["autoReleaseNotesExplanation"], 12, "#d0d2d6")
  explainerLabel:SetPoint("TOPLEFT", releaseNotesFrame.scrollframe, "BOTTOMLEFT", 4, -10)

  local reloadButton = LWF:CreateButton(releaseNotesFrame, 200, 40, L["Save and Reload"], 16)
  reloadButton:SetClickFunction(function()
    local input = editbox:GetText()
    addon:SaveReleaseNotes(input)
    ReloadUI()
  end)
  reloadButton:SetBackdropColor(0, 0.8, 0, 1)
  reloadButton:SetScript("OnEnter", function(self)
    reloadButton.button:SetBackdropBorderColor(1, 1, 1, 1)
  end)
  reloadButton:SetScript("OnLeave", function(self)
    reloadButton.button:SetBackdropBorderColor(1, 1, 1, 0)
  end)
  reloadButton:SetPoint("BOTTOM", releaseNotesFrame, "BOTTOM", 0, 40)

  local nextStepLabel = DF:CreateLabel(
    releaseNotesFrame, L["Continue the upload through the Wago App after the reload!"], 14, "white")
  nextStepLabel:SetPoint("BOTTOM", releaseNotesFrame, "BOTTOM", 0, 15)
  local warningIconLeft = LWF:CreateIconButton(releaseNotesFrame, 30, "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
  local warningIconRight = LWF:CreateIconButton(releaseNotesFrame, 30, "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
  warningIconLeft:SetPoint("RIGHT", nextStepLabel, "LEFT", -5, 0)
  warningIconRight:SetPoint("LEFT", nextStepLabel, "RIGHT", 5, 0)

  releaseNotesFrame:HookScript("OnHide", function()
    addon.SetLockoutFrameShowState(false)
  end)
end

function addon:AddProfileRemoval(packName, resolution, moduleName)
  local data = {
    packName = packName,
    resolution = resolution,
    moduleName = moduleName
  }
  tinsert(addon.db.profileRemovals, data)
end

local function getAndClearCurrentProfileRemovals()
  local removeString
  for i = #addon.db.profileRemovals, 1, -1 do
    local data = addon.db.profileRemovals[i]
    if data.packName == addon.db.chosenPack then
      removeString = removeString or ""
      removeString = removeString.."- "..data.moduleName.." ("..data.resolution..")\n"
      table.remove(addon.db.profileRemovals, i)
    end
  end
  return removeString
end

function addon:CountRemovedProfiles(packName)
  local count = 0
  for i = #addon.db.profileRemovals, 1, -1 do
    if addon.db.profileRemovals[i].packName == packName then
      count = count + 1
    end
  end
  return count
end

function addon:OpenReleaseNoteInput(timestamp, updates, removals)
  if not releaseNotesFrame then addon:CreateReleaseNoteInput() end
  releaseNotesFrame.timestamp = timestamp
  addon.copyHelper:Hide()
  --updates/additions
  local str
  for key, entry in pairs(updates) do
    if type(entry) == "boolean" then
      str = str or ""
      str = str.."- "..key.."\n"
    elseif type(entry) == "table" then
      for k in pairs(entry) do
        str = str or ""
        str = str.."- "..key..": "..k.."\n"
      end
    end
  end
  str = str and "## "..L["Updated / Added"]..":\n"..str or ""
  --removals
  local removeString
  for module, v in pairs(removals) do
    for entry in pairs(v) do
      removeString = removeString or ""
      removeString = removeString.."- "..module..": "..entry.."\n"
    end
  end
  -- profiles removed
  local removedProfiles = getAndClearCurrentProfileRemovals()
  if removedProfiles then
    removeString = removeString or ""
    removeString = removeString..removedProfiles
  end
  if removeString then
    str = str.."## "..L["Removed"]..":\n"..removeString
  end
  local dateString = "# "..date("%y/%m/%d", timestamp).."\n"
  str = dateString..str
  if addon.importFrame then addon.importFrame.Close:Click() end
  releaseNotesFrame:SetPoint("CENTER", addon.frames.mainFrame, "CENTER")
  releaseNotesFrame:Show()
  releaseNotesFrame.editbox:SetText(str)
  addon:SaveReleaseNotes(str)
end

function addon:SaveReleaseNotes(input)
  addon:GetCurrentPack().releaseNotes[releaseNotesFrame.timestamp] = input
end
