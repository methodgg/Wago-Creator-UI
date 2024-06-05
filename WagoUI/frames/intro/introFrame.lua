local addonName, addon = ...;
local DF = _G["DetailsFramework"];
local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE");
local db
local L = addon.L

function addon:CreateIntroFrame(f)
  local introFrame = CreateFrame("Frame", addonName.."IntroFrame", f)
  introFrame:SetAllPoints(f)
  introFrame:Hide()
  addon.frames.introFrame = introFrame
  local frameWidth = introFrame:GetWidth() - 0
  local frameHeight = introFrame:GetHeight() - 40

  local button = DF:CreateButton(introFrame, nil, 100, 40, "Expert", nil, nil, nil, nil, nil, nil,
    options_dropdown_template);
  button.text_overlay:SetFont(button.text_overlay:GetFont(), 16);
  button:SetClickFunction(function()
    addon.frames.introFrame:Hide()
    addon.frames.profileFrame:Show()
  end);
  button:SetPoint("TOPRIGHT", introFrame, "TOPRIGHT", -4, -30)
end
