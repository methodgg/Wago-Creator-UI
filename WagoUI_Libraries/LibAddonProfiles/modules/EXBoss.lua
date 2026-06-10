local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "EXBoss",
  wagoId = "vNAgrRKo",
  oldestSupported = "v26.6.10.2213",
  addonNames = { "EXBoss", "ExwindCore", "EXBossData", "EXBOSS-Locale", "EXBOSS-LocaleBase", "EXBOSS-EXWIND", "EXBOSS-ENG" },
  conflictingAddons = {},
  icon = C_AddOns.GetAddOnMetadata("EXBoss", "IconTexture"),
  slash = "/exboss",
  needReloadOnImport = true,
  needProfileKey = false,
  preventRename = true,
  willOverrideProfile = true,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("EXBoss")
    return loaded
  end,
  isUpdated = function(self)
    local currentVersionString = ExBoss_MetaData and ExBoss_MetaData.version
    if not currentVersionString then return false end
    return private:IsSemverSameOrHigher(currentVersionString, self.oldestSupported)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    xpcall(function()
      EXBossWagoAPI:OpenConfig()
    end, geterrorhandler())
  end,
  closeConfig = function(self)
    xpcall(function()
      EXBossWagoAPI:CloseConfig()
    end, geterrorhandler())
  end,
  getProfileKeys = function(self)
    local profileKeys = {}
    xpcall(function()
      profileKeys = EXBossWagoAPI:GetProfileKeys()
    end, geterrorhandler())
    return profileKeys
  end,
  getCurrentProfileKey = function(self)
    local profileKey
    xpcall(function()
      profileKey = EXBossWagoAPI:GetCurrentProfileKey()
    end, geterrorhandler())
    return profileKey
  end,
  isDuplicate = function(self, profileKey)
    if not profileKey then return false end
    return self:getProfileKeys()[profileKey] ~= nil
  end,
  setProfile = function(self, profileKey)
    if not profileKey then return end
    if not self:getProfileKeys()[profileKey] then return end
    xpcall(function()
      EXBossWagoAPI:SetProfile(profileKey)
    end, geterrorhandler())
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)

  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    xpcall(function()
      EXBossWagoAPI:ImportProfile(profileString, "Global")
    end, geterrorhandler())
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local export
    xpcall(function()
      export = EXBossWagoAPI:ExportProfile(profileKey)
    end, geterrorhandler())
    return export
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    local profileDataA, profileDataB
    xpcall(function()
      profileDataA = EXBossWagoAPI:DecodeProfileString(profileStringA)
      profileDataB = EXBossWagoAPI:DecodeProfileString(profileStringB)
    end, geterrorhandler())
    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end
}

private.modules[m.moduleName] = m
