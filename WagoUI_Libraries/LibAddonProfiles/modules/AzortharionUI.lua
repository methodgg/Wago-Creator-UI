local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

local optionsFrame

---@type LibAddonProfilesModule
local m = {
  moduleName = "AzortharionUI",
  wagoId = "QNlzqDKe",
  oldestSupported = "2.5",
  addonNames = { "AzortharionUI" },
  conflictingAddons = {},
  icon = C_AddOns.GetAddOnMetadata("AzortharionUI", "IconTexture"),
  slash = "/aui",
  needReloadOnImport = true,
  needProfileKey = false,
  preventRename = true,
  willOverrideProfile = true,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("AzortharionUI")
    return loaded
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    if not SlashCmdList["AUI"] then return end
    SlashCmdList["AUI"]()
  end,
  closeConfig = function(self)
    if not SlashCmdList["AUI"] then return end
    SlashCmdList["AUI"]()
  end,
  getProfileKeys = function(self)
    return AzortharionUI_DB.profiles
  end,
  getCurrentProfileKey = function(self)
    local characterName = UnitName("player").." - "..GetRealmName()
    return AzortharionUI_DB.profileKeys and AzortharionUI_DB.profileKeys[characterName]
  end,
  isDuplicate = function(self, profileKey)
    if not profileKey then return false end
    return self:getProfileKeys()[profileKey] ~= nil
  end,
  setProfile = function(self, profileKey)
    local characterName = UnitName("player").." - "..GetRealmName()
    AzortharionUI_DB.profileKeys[characterName] = profileKey
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    if profileData and profileData.secondaryPower and profileData.secondaryPower.posY then
      return profileKey
    end
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    xpcall(function()
      AUIG:Import(profileString, profileKey)
    end, geterrorhandler())
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local export
    xpcall(function()
      export = AUIG:Export(profileKey)
    end, geterrorhandler())
    return export
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    --profilestrings have "AUI2=" prefix
    local _, _, profileDataA = private:GenericDecode(profileStringA:sub(6), true)
    local _, _, profileDataB = private:GenericDecode(profileStringB:sub(6), true)

    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end
}
private.modules[m.moduleName] = m
