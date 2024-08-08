---@type string
local addonName = ...
---@class WagoUI
local addon = select(2, ...)
local DF = _G["DetailsFramework"];
local LWF = LibStub("LibWagoFramework")
local L = addon.L
local LAP = LibStub:GetLibrary("LibAddonProfiles")

local currentSelectedCharacter = nil

local function setAllProfilesAsync()
  print(currentSelectedCharacter)
  -- local target = addon:GetImportedProfilesTarget()
  -- for moduleName, data in pairs(target) do
  --   ---@type LibAddonProfilesModule
  --   local lap = LAP:GetModule(moduleName)
  --   if data.profileKey and lap:isLoaded() then
  --     if lap:needsInitialization() then
  --       lap:openConfig()
  --       C_Timer.After(0, function()
  --         lap:closeConfig()
  --       end)
  --     end
  --     local profileKeys = lap:getProfileKeys()
  --     if profileKeys[data.profileKey] then
  --       lap:setProfile(data.profileKey)
  --     end
  --   end
  --   coroutine.yield()
  -- end
end

local function getImportedProfilesDataForDropdown()
  local res = {}
  for key, data in pairs(addon.db.importedProfiles) do
    local entry = {
      value = key,
      label = key,
      onclick = function()
        currentSelectedCharacter = key
      end
    }
    tinsert(res, entry)
  end
  return res
end

function addon:CreateAltFrame(f)
  local altFrame = CreateFrame("Frame", addonName.."AltFrame", f)
  altFrame:SetAllPoints(f)
  altFrame:Hide()
  addon.frames.altFrame = altFrame

  local logo = DF:CreateImage(altFrame, [[Interface\AddOns\]]..addonName..[[\media\wagoLogo512]], 256, 256)
  logo:SetPoint("TOP", altFrame, "TOP", 0, -15)

  local text = L["altFrameHeader"]
  local header = DF:CreateLabel(altFrame, text, 22, "white");
  header:SetWidth(altFrame:GetWidth() - 100)
  header:SetJustifyH("CENTER")
  header:SetPoint("TOP", logo, "BOTTOM", 0, 5);
  addon.frames.altFrame.header = header

  -- label or dropdown, depending on if single or multiple characters exist that we imported profiles to
  local dropdownData = getImportedProfilesDataForDropdown()
  local dropdownFunc = function() return getImportedProfilesDataForDropdown() end
  local uiPackDropdown = LWF:CreateDropdown(altFrame, 250, 50, 16, 1.5, dropdownFunc)
  local key = dropdownData[1] and dropdownData[1].key or nil
  uiPackDropdown:Select(key)
  currentSelectedCharacter = key
  uiPackDropdown:SetPoint("RIGHT", altFrame, "CENTER", -10, -100)
  local sourceLabel = DF:CreateLabel(altFrame, L["Source:"], 14)
  sourceLabel:SetPoint("BOTTOMLEFT", uiPackDropdown, "TOPLEFT", 0, 2)

  local cancelButton = LWF:CreateButton(altFrame, 200, 40, L["Cancel"], 18)
  cancelButton:SetPoint("BOTTOM", altFrame, "BOTTOM", 0, 40)
  cancelButton:SetClickFunction(function()
    addon.frames.altFrame:Hide()
    addon.frames.expertFrame:Show()
  end);

  local setProfilesButton = LWF:CreateButton(altFrame, 220, 50, L["Load Profiles"], 22)
  setProfilesButton:SetPoint("LEFT", uiPackDropdown, "RIGHT", 40, 0)
  setProfilesButton:SetClickFunction(function()
    addon:Async(function()
      setAllProfilesAsync()
      header:SetText(L["altFrameHeader2"])
      if uiPackDropdown then uiPackDropdown:Hide() end
      sourceLabel:Hide()
      cancelButton:Hide()
      setProfilesButton:ClearAllPoints()
      setProfilesButton:SetPoint("CENTER", altFrame, "CENTER", 0, -100)
      setProfilesButton:SetScale(1.2)
      setProfilesButton:SetText(L["Reload UI"])
      setProfilesButton:SetClickFunction(function()
        --TODO TEMPORARY REMOVE THIS ONLY FOR TEST PURPOSES
        --TODO TEMPORARY REMOVE THIS ONLY FOR TEST PURPOSES
        --TODO TEMPORARY REMOVE THIS ONLY FOR TEST PURPOSES
        WagoUI.dbC.hasLoggedIn = false
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
