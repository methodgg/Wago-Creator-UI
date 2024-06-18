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
    button.button:SetBackdropBorderColor(1, 1, 1, 0)
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
