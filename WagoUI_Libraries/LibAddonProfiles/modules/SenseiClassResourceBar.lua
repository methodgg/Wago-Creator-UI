local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Sensei Class Resource Bar",
  wagoId = "ANzk0V64",
  oldestSupported = "1.4.7",
  addonNames = { "SenseiClassResourceBar" },
  conflictingAddons = {},
  icon = C_AddOns.GetAddOnMetadata("SenseiClassResourceBar", "IconTexture"),
  slash = "?", -- no slash, it's editmode integrated
  needReloadOnImport = true,
  needProfileKey = false,
  preventRename = true,
  willOverrideProfile = true,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("SenseiClassResourceBar")
    return loaded
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    if not SlashCmdList["EDITMODE"] then return end
    SlashCmdList["EDITMODE"]()
  end,
  closeConfig = function(self)
    EditModeManagerFrame.onCloseCallback()
  end,
  getProfileKeys = function(self)
    local profileKeys = {}
    for _, profileKey in pairs(SCRB.getAvailableProfiles()) do
      profileKeys[profileKey] = true
    end
    return profileKeys
  end,
  getCurrentProfileKey = function(self)
    return SCRB.getCurrentProfileName()
  end,
  isDuplicate = function(self, profileKey)
    return true
  end,
  setProfile = function(self, profileKey)
    --tied to editmode, we don't need to do anything here
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)

  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    xpcall(function()
      SCRB.importProfileFromString(profileString)
    end, geterrorhandler())
  end,
  exportProfile = function(self, profileKey)
    local export
    xpcall(function()
      export = SCRB.exportProfileAsString(true, true)
    end, geterrorhandler())
    return export
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    local prefixA, versionA, encodedA = profileStringA:match("^([^:]+):(%d+):(.+)$")
    local prefixB, versionB, encodedB = profileStringB:match("^([^:]+):(%d+):(.+)$")

    local _, _, profileDataA = private:GenericDecode(encodedA, true)
    local _, _, profileDataB = private:GenericDecode(encodedB, true)
    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end
}
private.modules[m.moduleName] = m
