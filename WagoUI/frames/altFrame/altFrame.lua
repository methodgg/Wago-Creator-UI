---@type string
local addonName = ...
---@class WagoUI
local addon = select(2, ...)
local DF = _G["DetailsFramework"];
local L = addon.L
local LAP = LibStub:GetLibrary("LibAddonProfiles")

local function setAllProfilesAsync()
  for moduleName, data in pairs(addon.db.importedProfiles) do
    ---@type LibAddonProfilesModule
    local lap = LAP:GetModule(moduleName)
    if data.profileKey and lap.isLoaded() then
      if lap.needsInitialization() then
        lap.openConfig()
        C_Timer.After(0, function()
          lap.closeConfig()
        end)
      end
      local profileKeys = lap.getProfileKeys()
      if profileKeys[data.profileKey] then
        lap.setProfile(data.profileKey)
      end
    end
    coroutine.yield()
  end
end

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
  addon.frames.altFrame.header = header

  local cancelButton = addon.DF:CreateButton(altFrame, 220, 50, L["Cancel"], 22)
  cancelButton:SetPoint("CENTER", altFrame, "CENTER", 160, -180)
  cancelButton:SetClickFunction(function()
    addon.frames.altFrame:Hide()
    addon.frames.expertFrame:Show()
  end);

  local introButton = addon.DF:CreateButton(altFrame, 220, 50, L["Set all Profiles"], 22)
  introButton:SetPoint("CENTER", altFrame, "CENTER", -160, -180)
  introButton:SetClickFunction(function()
    addon:Async(function()
      setAllProfilesAsync()
      header:SetText(L["altFrameHeader2"])
      introButton:SetText(L["Reload UI"])
      introButton:SetClickFunction(function()
        ReloadUI()
      end);
    end);
  end);
end

function addon:SetAltFrameHeaderText(text)
  addon.frames.altFrame.header:SetText(text)
end

function addon:ShowAltFrame()
  addon.frames.altFrame:Show()
end
