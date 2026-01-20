local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Enhance QoL",
  wagoId = "aN0Ykv6j",
  oldestSupported = "7.2.0",
  addonNames = { "EnhanceQoL" },
  conflictingAddons = {},
  icon = C_AddOns.GetAddOnMetadata("EnhanceQoL", "IconTexture"),
  slash = "/eqol",
  needReloadOnImport = true,
  needProfileKey = true,
  preventRename = false,
  willOverrideProfile = false,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("EnhanceQoL")
    return loaded
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    if not SlashCmdList["ENHANCEQOL"] then return end
    SlashCmdList["ENHANCEQOL"]("")
  end,
  closeConfig = function(self)
    SettingsPanel:Hide()
  end,
  getProfileKeys = function(self)
    return EnhanceQoLDB.profiles
  end,
  getCurrentProfileKey = function(self)
    local characterName = UnitGUID("player")
    return EnhanceQoLDB.profileKeys and EnhanceQoLDB.profileKeys[characterName]
  end,
  isDuplicate = function(self, profileKey)
    if not profileKey then return false end
    return self:getProfileKeys()[profileKey] ~= nil
  end,
  setProfile = function(self, profileKey)
    local characterName = UnitGUID("player")
    EnhanceQoLDB.profileKeys[characterName] = profileKey
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)

  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    xpcall(function()
      EnhanceQoL.importProfile(profileString)
    end, geterrorhandler())
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local export
    xpcall(function()
      export = EnhanceQoL.exportProfile(profileKey)
    end, geterrorhandler())
    return export
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    local _, _, profileDataA = private:GenericDecode(profileStringA, false)
    local _, _, profileDataB = private:GenericDecode(profileStringB, false)
    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end
}
private.modules[m.moduleName] = m
