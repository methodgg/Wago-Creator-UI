---@type string
local addonName = ...
---@class WagoUI
local addon = select(2, ...)
local DF = _G["DetailsFramework"]
local LWF = LibStub("LibWagoFramework")
local L = addon.L
local LAP = LibStub:GetLibrary("LibAddonProfiles")

---@type string | nil
local currentSelectedCharacter = nil
local needLoad
local altFrame, header, dropdownData, uiPackDropdown, sourceLabel, cancelButton, setProfilesButton

--- Set all profiles for the current selected character.
--- This function will try to lookup matching profiles key in the addon's SV.
--- If it can't find it, it will look for the latest imported profile key for that character and module as stored in the WagoUI SV.
local function setAllProfilesAsync()
  if not currentSelectedCharacter then
    return
  end
  needLoad = {}
  -- call this so we get and initialized db entry for the current character
  -- Keys that need to be retrieved from WagoUI db need to also be stored in WagoUI db again
  -- This is needed when the user "chains" characters
  addon:GetImportedProfilesTarget()
  for _, lapModule in pairs(LAP:GetAllModules()) do
    if lapModule:isLoaded() and lapModule:isUpdated() then
      local profileAssignments = lapModule.getProfileAssignments and lapModule:getProfileAssignments()
      if profileAssignments then
        -- it should be a retrievable key, the addon stores it in accessible SV
        local profileKey = profileAssignments[currentSelectedCharacter]
        if profileKey then
          lapModule:setProfile(profileKey)
          addon:AddonPrint(string.format(L["Set Profile %s: %s"], profileKey, lapModule.moduleName))
        end
      else
        -- the place where the keys are stored is not accessible, see if we have imported via WagoUI on that character
        local profileKey, updatedAt = addon:GetLatestImportedProfile(currentSelectedCharacter, lapModule.moduleName)
        local profileKeys = lapModule.getProfileKeys and lapModule:getProfileKeys()
        if profileKey and updatedAt and profileKeys[profileKey] then
          lapModule:setProfile(profileKey)
          addon:AddonPrint(string.format(L["Set Profile %s: %s"], profileKey, lapModule.moduleName))
          addon:StoreImportedProfileData(updatedAt, lapModule.moduleName, profileKey)
        end
      end
    elseif LAP:CanEnableAnyAddOn(lapModule.addonNames) then
      -- check if we have imported via WagoUI on that character and the module is not loaded
      -- we need to load the addon, reload UI and continue setting the profile
      local profileKey, updatedAt = addon:GetLatestImportedProfile(currentSelectedCharacter, lapModule.moduleName)
      if profileKey then
        addon:AddonPrint(string.format("Module %s is not loaded, but imported profile found", lapModule.moduleName))
        tinsert(needLoad, {moduleName = lapModule.moduleName, profileKey = profileKey})
      end
    end
    coroutine.yield()
  end
end

function addon:ContinueSetAllProfiles()
  addon:SuppressAddOnSpam()
  header:Hide()
  setProfilesButton:SetText(L["Load remaining and Reload"])
  uiPackDropdown:Hide()
  sourceLabel:Hide()
  setProfilesButton:ClearAllPoints()
  setProfilesButton:SetPoint("CENTER", altFrame, "CENTER", 0, -100)
  setProfilesButton:SetClickFunction(
    function()
      for _, data in ipairs(addon.dbC.needLoad) do
        ---@type LibAddonProfilesModule
        local lap = LAP:GetModule(data.moduleName)
        local profileKeys = lap.getProfileKeys and lap:getProfileKeys()
        if profileKeys and data.profileKey and profileKeys[data.profileKey] then
          lap:setProfile(data.profileKey)
        end
      end
      addon.dbC.needLoad = nil
      ReloadUI()
    end
  )
end

local function getImportedProfilesDataForDropdown()
  local currentCharacter = UnitName("player") .. " - " .. GetRealmName()
  local res = {}
  for key, data in pairs(addon.db.importedProfiles) do
    if key ~= currentCharacter then
      local entry = {
        value = key,
        label = addon:GetClassColoredNameFromDB(key),
        onclick = function()
          currentSelectedCharacter = key
        end
      }
      tinsert(res, entry)
    end
  end
  return res
end

---Look at the importedProfiles data and return the most likely character.
---This is the character that has the most profiles imported to it.
---@return string | nil characterName
local function getMostLikelyProfileSource()
  local max = 0
  local maxcharacterName = nil
  for characterName, packs in pairs(addon.db.importedProfiles) do
    local count = 0
    for _, pack in pairs(packs) do
      for resolution, modules in pairs(pack) do
        count = count + 1
      end
    end
    if count > max then
      max = count
      maxcharacterName = characterName
    end
  end
  return maxcharacterName
end

function addon:CreateAltFrame(f)
  altFrame = CreateFrame("Frame", addonName .. "AltFrame", f)
  altFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -10)
  altFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
  altFrame:Hide()
  addon.frames.altFrame = altFrame

  local logo = DF:CreateImage(altFrame, [[Interface\AddOns\]] .. addonName .. [[\media\wagoLogo512]], 256, 256)
  logo:SetPoint("TOP", altFrame, "TOP", 0, -15)

  local text = L["altFrameHeader"]
  header = DF:CreateLabel(altFrame, text, 22, "white")
  header:SetWidth(altFrame:GetWidth() - 100)
  header:SetJustifyH("CENTER")
  header:SetPoint("TOP", logo, "BOTTOM", 0, 5)
  addon.frames.altFrame.header = header

  -- label or dropdown, depending on if single or multiple characters exist that we imported profiles to
  dropdownData = getImportedProfilesDataForDropdown()
  local dropdownFunc = function()
    return getImportedProfilesDataForDropdown()
  end
  uiPackDropdown = LWF:CreateDropdown(altFrame, 300, 50, 16, 1.5, dropdownFunc)
  local fontName, fontSize = uiPackDropdown.dropdown.text:GetFont()
  uiPackDropdown.dropdown.text:SetFont(fontName, fontSize, "THINOUTLINE")

  local value = getMostLikelyProfileSource()
  uiPackDropdown:Select(value)
  currentSelectedCharacter = value
  uiPackDropdown:SetPoint("RIGHT", altFrame, "CENTER", -10, -100)
  sourceLabel = DF:CreateLabel(altFrame, L["Source:"], 14)
  sourceLabel:SetPoint("BOTTOMLEFT", uiPackDropdown, "TOPLEFT", 0, 2)

  cancelButton = LWF:CreateButton(altFrame, 200, 40, L["Cancel"], 18)
  cancelButton:SetPoint("BOTTOM", altFrame, "BOTTOM", 0, 40)
  cancelButton:SetClickFunction(
    function()
      addon.frames.altFrame:Hide()
      addon.frames.expertFrame:Show()
    end
  )

  setProfilesButton = LWF:CreateButton(altFrame, 300, 50, L["Load Profiles"], 22)
  if not dropdownData[1] then
    setProfilesButton:Disable()
  end
  setProfilesButton:SetPoint("LEFT", uiPackDropdown, "RIGHT", 40, 0)
  setProfilesButton:SetClickFunction(
    function()
      addon:Async(
        function()
          uiPackDropdown:Disable()
          setProfilesButton:Disable()
          setProfilesButton:SetText(L["Please wait..."])
          cancelButton:Disable()
          setAllProfilesAsync()
          if #needLoad > 0 then
            addon.dbC.needLoad = needLoad
            for _, data in ipairs(needLoad) do
              local lap = LAP:GetModule(data.moduleName)
              LAP:EnableAddOns(lap.addonNames)
            end
            header:SetText(L["altFrameHeader4"])
          else
            header:SetText(L["altFrameHeader2"])
          end
          if uiPackDropdown then
            uiPackDropdown:Hide()
          end
          sourceLabel:Hide()
          cancelButton:Hide()
          setProfilesButton:Enable()
          setProfilesButton:ClearAllPoints()
          setProfilesButton:SetPoint("CENTER", altFrame, "CENTER", 0, -100)
          setProfilesButton:SetScale(1.2)
          setProfilesButton:SetText(L["Reload UI"])
          setProfilesButton:SetClickFunction(
            function()
              ReloadUI()
            end
          )
        end
      )
    end
  )
end

function addon:SetAltFrameHeaderText(text)
  addon.frames.altFrame.header:SetText(text)
end

function addon:ShowAltFrame()
  addon.frames.altFrame:Show()
end
