local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Unhalted Unit Frames",
  wagoId = "96do35NO",
  oldestSupported = "12.0.5",
  addonNames = { "UnhaltedUnitFrames" },
  conflictingAddons = { "BetterBlizzFrames", "MidnightSimpleUnitFrames", "ShadowedUnitFrames", "ShadowedUF_Options", "PitBull4" },
  icon = C_AddOns.GetAddOnMetadata("UnhaltedUnitFrames", "IconTexture"),
  slash = "/uuf",
  needReloadOnImport = true,
  needProfileKey = true,
  preventRename = false,
  willOverrideProfile = true,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("UnhaltedUnitFrames")
    return loaded
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    UUFG.OpenUUFGUI()
  end,
  closeConfig = function(self)
    UUFG.CloseUUFGUI()
  end,
  getProfileKeys = function(self)
    return UUFDB.profiles
  end,
  getCurrentProfileKey = function(self)
    local characterName = UnitName("player").." - "..GetRealmName()
    return UUFDB.profileKeys and UUFDB.profileKeys[characterName]
  end,
  isDuplicate = function(self, profileKey)
    if not profileKey then return false end
    return self:getProfileKeys()[profileKey] ~= nil
  end,
  setProfile = function(self, profileKey)
    local characterName = UnitName("player").." - "..GetRealmName()
    UUFDB.profileKeys[characterName] = profileKey
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)

  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    xpcall(function()
      UUFG:ImportUUF(profileString, profileKey)
    end, geterrorhandler())
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local export
    xpcall(function()
      export = UUFG:ExportUUF(profileKey)
    end, geterrorhandler())
    return export
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    local _, _, profileDataA = private:GenericDecode(profileStringA:sub(6), false)
    local _, _, profileDataB = private:GenericDecode(profileStringB:sub(6), false)
    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end
}
private.modules[m.moduleName] = m
