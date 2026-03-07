local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Ayije_CDM",
  wagoId = "aNebMd62",
  oldestSupported = "3.68",
  addonNames = { "Ayije_CDM" },
  conflictingAddons = {},
  icon = C_AddOns.GetAddOnMetadata("Ayije_CDM", "IconTexture"),
  slash = "/cdm",
  needReloadOnImport = false,
  needProfileKey = true,
  preventRename = false,
  willOverrideProfile = true,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    return C_AddOns.IsAddOnLoaded("Ayije_CDM") and Ayije_CDM_API ~= nil
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    xpcall(function()
      Ayije_CDM_API:OpenConfig()
    end, geterrorhandler())
  end,
  closeConfig = function(self)
    xpcall(function()
      Ayije_CDM_API:CloseConfig()
    end, geterrorhandler())
  end,
  getProfileKeys = function(self)
    local profileKeys = {}
    xpcall(function()
      profileKeys = Ayije_CDM_API:GetProfileKeys() or {}
    end, geterrorhandler())
    return profileKeys
  end,
  getCurrentProfileKey = function(self)
    local profileKey
    xpcall(function()
      profileKey = Ayije_CDM_API:GetCurrentProfileKey()
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
      Ayije_CDM_API:SetProfile(profileKey)
    end, geterrorhandler())
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)

  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    xpcall(function()
      Ayije_CDM_API:ImportProfile(profileString, profileKey)
    end, geterrorhandler())
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local export
    xpcall(function()
      export = Ayije_CDM_API:ExportProfile(profileKey)
    end, geterrorhandler())
    return export
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    local profileDataA, profileDataB
    xpcall(function()
      profileDataA = Ayije_CDM_API:DecodeProfileString(profileStringA)
      profileDataB = Ayije_CDM_API:DecodeProfileString(profileStringB)
    end, geterrorhandler())
    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end
}

private.modules[m.moduleName] = m
