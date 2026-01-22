local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Prat-3.0",
  wagoId = "RNL9ae6o",
  oldestSupported = "3.9.82",
  addonNames = { "Prat-3.0" },
  conflictingAddons = { "Chattynator" },
  icon = C_AddOns.GetAddOnMetadata("Prat-3.0", "IconTexture"),
  slash = "/prat",
  needReloadOnImport = true,
  needProfileKey = true,
  preventRename = false,
  willOverrideProfile = true,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("Prat-3.0")
    return loaded
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    LibStub("AceConfigDialog-3.0"):Open("Prat")
  end,
  closeConfig = function(self)
    LibStub("AceConfigDialog-3.0"):Close("Prat")
  end,
  getProfileKeys = function(self)
    return Prat.db.sv.profiles
  end,
  getCurrentProfileKey = function(self)
    local characterName = UnitName("player").." - "..GetRealmName()
    return Prat.db.sv.profileKeys and Prat.db.sv.profileKeys[characterName]
  end,
  isDuplicate = function(self, profileKey)
    if not profileKey then return false end
    return self:getProfileKeys()[profileKey] ~= nil
  end,
  setProfile = function(self, profileKey)
    local characterName = UnitName("player").." - "..GetRealmName()
    Prat.db.sv.profileKeys[characterName] = profileKey
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)

  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    xpcall(function()
      Prat:ImportProfile(profileString, profileKey)
    end, geterrorhandler())
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local export
    xpcall(function()
      export = Prat:ExportProfile(profileKey)
    end, geterrorhandler())
    return export
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    -- when swapping to another profile prat doesnt fully put all the data into the proper places when it should
    -- after a reload it does so there can be false positives but if the creator just keeps exporting it will sort itself out
    local profileDataA = private:BlizzardDecodeB64CBOR(profileStringA)
    local profileDataB = private:BlizzardDecodeB64CBOR(profileStringB)
    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end
}
private.modules[m.moduleName] = m
