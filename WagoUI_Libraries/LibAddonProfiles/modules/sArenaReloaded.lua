local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "sArena Reloaded",
  wagoId = "5NRebvG3",
  oldestSupported = "2.3.3",
  addonNames = { "sArena_Reloaded" },
  conflictingAddons = {},
  icon = 135884,
  slash = "/sarena",
  needReloadOnImport = true,
  needProfileKey = true,
  preventRename = false,
  willOverrideProfile = false,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("sArena_Reloaded")
    return loaded
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    LibStub("AceConfigDialog-3.0"):Open("sArena")
  end,
  closeConfig = function(self)
    LibStub("AceConfigDialog-3.0"):Close("sArena")
  end,
  getProfileKeys = function(self)
    return sArena_ReloadedDB.profiles
  end,
  getCurrentProfileKey = function(self)
    local characterName = UnitName("player").." - "..GetRealmName()
    return sArena_ReloadedDB.profileKeys and sArena_ReloadedDB.profileKeys[characterName]
  end,
  isDuplicate = function(self, profileKey)
    if not profileKey then return false end
    return self:getProfileKeys()[profileKey] ~= nil
  end,
  setProfile = function(self, profileKey)
    local characterName = UnitName("player").." - "..GetRealmName()
    sArena_ReloadedDB.profileKeys[characterName] = profileKey
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)

  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    xpcall(function()
      sArena:ImportProfile(profileString, profileKey, true)
    end, geterrorhandler())
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local export
    xpcall(function()
      export = sArena:ExportProfile(profileKey)
    end, geterrorhandler())
    return export
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    local _, _, profileDataA = private:GenericDecode(profileStringA:sub(9, profileStringA:len() - 8), true)
    local _, _, profileDataB = private:GenericDecode(profileStringB:sub(9, profileStringB:len() - 8), true)
    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end
}
private.modules[m.moduleName] = m
