---@class WagoUICreator
local addon = select(2, ...)
local L = addon.L
local DF = _G["DetailsFramework"]
local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")

local releaseNotesFrame

function addon:CreateReleaseNoteInput()
  releaseNotesFrame = addon:CreateGenericTextFrame(600, 300, "Release Notes")
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
  releaseNotesFrame.scrollframe:SetPoint("BOTTOMRIGHT", releaseNotesFrame, "BOTTOMRIGHT", -23, 80)
  local reloadButton = DF:CreateButton(releaseNotesFrame, nil, 200, 40, L["Save and Reload"], nil, nil, nil, nil, nil,
    nil,
    options_dropdown_template)
  reloadButton.text_overlay:SetFont(reloadButton.text_overlay:GetFont(), 16)
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
  reloadButton:SetPoint("BOTTOM", releaseNotesFrame, "BOTTOM", 0, 20)
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
      str = str..key.."\n"
    elseif type(entry) == "table" then
      for k in pairs(entry) do
        str = str or ""
        str = str..key..": "..k.."\n"
      end
    end
  end
  str = str and L["Updated / Added"]..":\n"..str or ""
  --removals
  local removeString
  for module, v in pairs(removals) do
    for entry in pairs(v) do
      removeString = removeString or ""
      removeString = removeString..module..": "..entry.."\n"
    end
  end
  if removeString then
    str = str..L["Removed"]..":\n"..removeString
  end
  if addon.importFrame then addon.importFrame.Close:Click() end
  releaseNotesFrame:SetPoint("CENTER", addon.frames.mainFrame, "CENTER")
  releaseNotesFrame:Show()
  releaseNotesFrame.editbox:SetText(str)
  addon:SaveReleaseNotes(str)
end

function addon:SaveReleaseNotes(input)
  addon:GetCurrentPack().releaseNotes[releaseNotesFrame.timestamp] = input
end
