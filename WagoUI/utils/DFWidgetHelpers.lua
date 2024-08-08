---@class WagoUI
local addon = select(2, ...)
local DF = _G["DetailsFramework"];
local odt = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE");
local db
local L = addon.L

-- Helpers for creating common widgets in the DetailsFramework
-- We want to simplify the creation of widgets in our style and make it easier to maintain

addon.DF = {}

function addon.DF:CreateButton(parent, width, height, text, fontSize)
  local button = DF:CreateButton(parent, nil, width, height, text, nil, nil, nil, nil, nil, nil, odt);
  button:SetScript("OnEnter", function(self)
    button.button:SetBackdropBorderColor(1, 1, 1, 1)
  end)
  button:SetScript("OnLeave", function(self)
    button.button:SetBackdropBorderColor(0, 0, 0, 1)
  end)
  button.button:SetBackdropBorderColor(0, 0, 0, 1)
  button:SetBackdropColor(1, 1, 1, 0.7)
  button.text_overlay:SetFont(button.text_overlay:GetFont(), fontSize);
  return button
end

function addon.DF:CreateDropdown(parent, width, height, fontSize, frameScale, dropdownFunc)
  local dropdown = DF:CreateDropDown(parent, dropdownFunc, nil, width, height, nil, nil, odt)
  dropdown:SetBackdropColor(1, 1, 1, 0.7)
  dropdown:SetScript("OnEnter", function(self)
    dropdown:SetBackdropColor(1, 1, 1, 0.7)
    dropdown:SetBackdropBorderColor(1, 1, 1, 1)
  end)
  dropdown:SetScript("OnLeave", function(self)
    dropdown:SetBackdropColor(1, 1, 1, 0.7)
    dropdown:SetBackdropBorderColor(0, 0, 0, 1)
  end)
  if fontSize then
    dropdown.dropdown.text:SetFont(dropdown.dropdown.text:GetFont(), fontSize)
  end
  dropdown.dropdown.dropdownframe:SetScale(frameScale)
  return dropdown
end

function addon.DF:CreateTabButton(parent, width, height, text, fontSize)
  local button = addon.DF:CreateButton(parent, width, height, text, fontSize)
  button.disabled_overlay:SetDrawLayer("BORDER")
  button:SetScript("OnEnter", function(self)
    button.button:SetBackdropBorderColor(1, 1, 1, 1)
    button.disabled_overlay:Hide()
  end)
  button:SetScript("OnLeave", function(self)
    button.button:SetBackdropBorderColor(0, 0, 0, 1)
    if button:IsEnabled() then
      button.disabled_overlay:Show()
    end
  end)
  return button
end

function addon.DF:CreateTabStructure(buttons, tabFunction, defaultTab)
  for i, button in ipairs(buttons) do
    button:SetClickFunction(function()
      for j, b in ipairs(buttons) do
        if i == j then
          b:Disable()
          b.disabled_overlay:Hide()
        else
          b:Enable()
          b.disabled_overlay:Show()
        end
      end
      tabFunction(i)
    end)
    if i == defaultTab then
      button:Disable()
      button.disabled_overlay:Hide()
    else
      button:Disable()
      button:Enable()
      button.disabled_overlay:Show()
    end
  end
  tabFunction(defaultTab)
end

function addon.DF:CreateResolutionButton(parent, text)
  local button = DF:CreateButton(parent, nil, 250, 80, text, nil, nil, nil, nil, nil, nil,
    odt);
  button:SetBackdropColor(1, 1, 1, 0.7)
  button:SetScript("OnEnter", function(self)
    button.button:SetBackdropBorderColor(1, 1, 1, 1)
  end)
  button:SetScript("OnLeave", function(self)
    button.button:SetBackdropBorderColor(1, 1, 1, 0)
  end)
  button.text_overlay:SetFont(button.text_overlay:GetFont(), 28);
  return button
end

function addon.DF:ShowPrompt(promptText, successCallback, cancelCallback, okayText, cancelText)
  okayText = okayText or L["Okay"]
  cancelText = cancelText or L["Cancel"]
  if not addon.promptFrame then
    addon.promptFrame = CreateFrame("Frame", "WagoUIPromptFrame", addon.frames.mainFrame)
    addon.promptFrame:SetPoint("BOTTOMRIGHT", addon.frames.mainFrame, "BOTTOMRIGHT")
    addon.promptFrame:SetPoint("TOPLEFT", addon.frames.mainFrame, "TOPLEFT", 0, -20)
    addon.promptFrame:SetFrameStrata("DIALOG")
    addon.promptFrame:EnableMouse(true)
    local tex = addon.promptFrame:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints(addon.promptFrame)
    tex:SetColorTexture(0, 0, 0, 0.9)
    ---@diagnostic disable-next-line: inject-field
    addon.promptFrame.label = DF:CreateLabel(addon.promptFrame, "", 22, "white");
    addon.promptFrame.label:SetWidth(addon.promptFrame:GetWidth() - 10)
    addon.promptFrame.label:SetJustifyH("CENTER")
    addon.promptFrame.label:SetPoint("TOP", addon.promptFrame, "TOP", 0, -120);
    ---@diagnostic disable-next-line: inject-field
    addon.promptFrame.okayButton = addon.DF:CreateButton(addon.promptFrame, 180, 40, "", 18)
    addon.promptFrame.okayButton:SetPoint("BOTTOMRIGHT", addon.promptFrame, "BOTTOM", -60, 60)
    ---@diagnostic disable-next-line: inject-field
    addon.promptFrame.cancelButton = addon.DF:CreateButton(addon.promptFrame, 180, 40, "", 18)
    addon.promptFrame.cancelButton:SetPoint("BOTTOMLEFT", addon.promptFrame, "BOTTOM", 60, 60)
  end
  addon.promptFrame.label:SetText(promptText)
  addon.promptFrame.okayButton:SetText(okayText)
  addon.promptFrame.okayButton:SetClickFunction(function()
    addon.promptFrame:Hide()
    if successCallback then successCallback() end
  end)
  addon.promptFrame.cancelButton:SetText(cancelText)
  addon.promptFrame.cancelButton:SetClickFunction(function()
    addon.promptFrame:Hide()
    if cancelCallback then cancelCallback() end
  end)
  addon.promptFrame:Show()
end

function addon.DF:CreateCheckbox(parent, size, switchFunc, defaultValue)
  local checkBox = DF:CreateSwitch(parent,
    function(_, _, value)
      if switchFunc then switchFunc(value) end
    end,
    false, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, DF:GetTemplate("switch", "OPTIONS_CHECKBOX_BRIGHT_TEMPLATE"))
  checkBox:SetValue(defaultValue)
  checkBox:SetSize(size, size)
  checkBox:SetAsCheckBox()
  return checkBox
end

function addon.DF:CreateTextEntry(parent, width, height, textChangedCallback)
  local textEntry = DF:CreateTextEntry(parent, textChangedCallback, width, height, nil, nil, nil, odt)
  textEntry:SetBackdropColor(1, 1, 1, 0.7)
  textEntry:SetBackdropBorderColor(0, 0, 0, 1)
  textEntry:SetScript("OnEnter", function(self)
    if textEntry.editbox:IsEnabled() then
      textEntry:SetBackdropBorderColor(1, 1, 1, 1)
    end
  end)
  textEntry:SetScript("OnLeave", function(self)
    textEntry:SetBackdropBorderColor(0, 0, 0, 1)
  end)
  return textEntry
end
