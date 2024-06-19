local addonName, addon = ...;
local DF = _G["DetailsFramework"];
local odt = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE");
local db
local L = addon.L

-- Helpers for creating common widgets in the DetailsFramework
-- We want to simplyfy the creation of widgets in our style and make it easier to maintain

addon.DF = {}

function addon.DF:CreateButton(parent, width, height, text, fontSize)
  local button = DF:CreateButton(parent, nil, width, height, text, nil, nil, nil, nil, nil, nil, odt);
  button:SetScript("OnEnter", function(self)
    button.button:SetBackdropBorderColor(1, 1, 1, 1)
  end)
  button:SetScript("OnLeave", function(self)
    button.button:SetBackdropBorderColor(0, 0, 0, 1)
  end)
  button.text_overlay:SetFont(button.text_overlay:GetFont(), fontSize);
  return button
end

function addon.DF:CreateDropdown(parent, width, height, fontSize, frameScale, dropdownFunc)
  local dropdown = DF:CreateDropDown(parent, dropdownFunc, nil, width, height, nil, nil, odt)
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
  button:SetScript("OnEnter", function(self)
    button.button:SetBackdropBorderColor(1, 1, 1, 1)
  end)
  button:SetScript("OnLeave", function(self)
    button.button:SetBackdropBorderColor(1, 1, 1, 0)
  end)
  button.text_overlay:SetFont(button.text_overlay:GetFont(), 28);
  return button
end

function addon.DF:ShowPrompt(promptText, successCallback, errorCallback, okayText, cancelText)
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
    local label = DF:CreateLabel(addon.promptFrame, promptText, 22, "white");
    label:SetWidth(addon.promptFrame:GetWidth() - 10)
    label:SetJustifyH("CENTER")
    label:SetPoint("TOP", addon.promptFrame, "TOP", 0, -120);
    local okayButton = addon.DF:CreateButton(addon.promptFrame, 180, 40, okayText, 18)
    okayButton:SetPoint("BOTTOMRIGHT", addon.promptFrame, "BOTTOM", -60, 60)
    okayButton:SetClickFunction(function()
      addon.promptFrame:Hide()
      if successCallback then
        successCallback()
      end
    end)
    local cancelButton = addon.DF:CreateButton(addon.promptFrame, 180, 40, cancelText, 18)
    cancelButton:SetPoint("BOTTOMLEFT", addon.promptFrame, "BOTTOM", 60, 60)
    cancelButton:SetClickFunction(function()
      addon.promptFrame:Hide()
      if errorCallback then
        errorCallback()
      end
    end)
  end
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
  return textEntry
end
