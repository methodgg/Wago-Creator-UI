local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "MRT",
  wagoId = "5bGoJnK0",
  oldestSupported = "5300",
  addonNames = { "MRT" },
  conflictingAddons = {},
  icon = C_AddOns.GetAddOnMetadata("MRT", "IconTexture"),
  slash = "/mrt",
  needReloadOnImport = true,
  needProfileKey = true,
  preventRename = false,
  willOverrideProfile = true,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("MRT")
    return loaded
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    xpcall(function()
      MRT_API:OpenConfig()
    end, geterrorhandler())
  end,
  closeConfig = function(self)
    xpcall(function()
      MRT_API:CloseConfig()
    end, geterrorhandler())
  end,
  getProfileKeys = function(self)
    local profileKeys = {}
    xpcall(function()
      profileKeys = MRT_API:GetProfileKeys()
    end, geterrorhandler())
    return profileKeys
  end,
  getCurrentProfileKey = function(self)
    local profileKey
    xpcall(function()
      profileKey = MRT_API:GetCurrentProfileKey()
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
      MRT_API:SetProfile(profileKey)
    end, geterrorhandler())
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)

  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    xpcall(function()
      MRT_API:ImportProfile(profileString, profileKey)
    end, geterrorhandler())
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local export
    xpcall(function()
      export = MRT_API:ExportProfile(profileKey)
    end, geterrorhandler())
    return export
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    local profileDataA, profileDataB
    xpcall(function()
      profileDataA = MRT_API:DecodeProfileString(profileStringA)
      profileDataB = MRT_API:DecodeProfileString(profileStringB)
    end, geterrorhandler())
    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end
}

private.modules[m.moduleName] = m
