local addonName, addon = ...;
local DF = _G["DetailsFramework"];
local L = addon.L

function addon:CreateAltFrame(f)
  local altFrame = CreateFrame("Frame", addonName.."AltFrame", f)
  altFrame:SetAllPoints(f)
  altFrame:Hide()
  addon.frames.altFrame = altFrame

  local logo = DF:CreateImage(altFrame, [[Interface\AddOns\]]..addonName..[[\media\wagoLogo512]], 256, 256)
  logo:SetPoint("TOP", altFrame, "TOP", 0, -60)

  local text = L["altFrameHeader"]
  local header = DF:CreateLabel(altFrame, text, 22, "white");
  header:SetWidth(altFrame:GetWidth() - 10)
  header:SetJustifyH("CENTER")
  header:SetPoint("LEFT", altFrame, "LEFT", 0, -80);

  local introButton = addon.DF:CreateButton(altFrame, 220, 50, L["Set all Profiles"], 22)
  introButton:SetPoint("CENTER", altFrame, "CENTER", -160, -180)
  introButton:SetClickFunction(function()
    print("Set all Profiles")
  end);

  local cancelButton = addon.DF:CreateButton(altFrame, 220, 50, L["Cancel"], 22)
  cancelButton:SetPoint("CENTER", altFrame, "CENTER", 160, -180)
  cancelButton:SetClickFunction(function()
    addon.frames.altFrame:Hide()
    addon.frames.expertFrame:Show()
  end);
end

function addon:ShowAltFrame()
  addon.frames.altFrame:Show()
end
