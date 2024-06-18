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

function addon.DF:CreateDropdown(parent, width, height, fontSize, dropdownFunc)
  local dropdown = DF:CreateDropDown(parent, dropdownFunc, nil, width, height, nil, nil, odt)
  if fontSize then
    dropdown.dropdown.text:SetFont(dropdown.dropdown.text:GetFont(), fontSize)
  end
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
