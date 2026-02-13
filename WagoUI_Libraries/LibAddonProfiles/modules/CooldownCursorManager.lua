local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Cooldown Cursor Manager",
  wagoId = "96d2elGO",
  oldestSupported = "6.1.0",
  addonNames = { "CooldownCursorManager" },
  conflictingAddons = {},
  icon = C_AddOns.GetAddOnMetadata("CooldownCursorManager", "IconTexture"),
  slash = "/ccm",
  needReloadOnImport = true,
  needProfileKey = true,
  preventRename = false,
  willOverrideProfile = true,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("CooldownCursorManager")
    return loaded
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    CooldownCursorManagerAPI:OpenConfig()
  end,
  closeConfig = function(self)
    CooldownCursorManagerAPI:CloseConfig()
  end,
  getProfileKeys = function(self)
    return CooldownCursorManagerAPI:GetProfileKeys()
  end,
  getCurrentProfileKey = function(self)
    return CooldownCursorManagerAPI:GetCurrentProfileKey()
  end,
  isDuplicate = function(self, profileKey)
    if not profileKey then return false end
    return self:getProfileKeys()[profileKey] ~= nil
  end,
  setProfile = function(self, profileKey)
    if not profileKey then return end
    if not self:getProfileKeys()[profileKey] then return end
    CooldownCursorManagerAPI:SetProfile(profileKey)
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)

  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    xpcall(function()
      CooldownCursorManagerAPI:ImportProfile(profileString, profileKey)
    end, geterrorhandler())
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local export
    xpcall(function()
      export = CooldownCursorManagerAPI:ExportProfile(profileKey)
    end, geterrorhandler())
    return export
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    local profileDataA, profileDataB
    xpcall(function()
      profileDataA = CooldownCursorManagerAPI:DecodeProfileString(profileStringA)
    end, geterrorhandler())
    xpcall(function()
      profileDataB = CooldownCursorManagerAPI:DecodeProfileString(profileStringB)
    end, geterrorhandler())

    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end
}
private.modules[m.moduleName] = m
