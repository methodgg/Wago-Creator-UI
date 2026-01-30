local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

local GLOBAL_SETTINGS_NAME = "FalconGlobalSettings"

---@type LibAddonProfilesModule
local m = {
  moduleName = "Skyriding Falcon",
  wagoId = "v63oJB6b",
  oldestSupported = "0.8.4",
  addonNames = { "Falcon" },
  conflictingAddons = {},
  icon = C_AddOns.GetAddOnMetadata("Falcon", "IconTexture"),
  slash = "?", -- no slash, it's editmode integrated
  needReloadOnImport = true,
  needProfileKey = false,
  preventRename = true,
  willOverrideProfile = true,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("Falcon")
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
    return FalconAddOnDB.Settings
  end,
  getCurrentProfileKey = function(self)
    if FalconAddOnDB.FalconGlobalSettingsEnabled then
      return GLOBAL_SETTINGS_NAME
    end
    return EditModeManagerFrame:GetActiveLayoutInfo().layoutName
  end,
  isDuplicate = function(self, profileKey)
    return true
  end,
  setProfile = function(self, profileKey)
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)

  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    xpcall(function()
      FalconPublicAPI:Import(profileString, profileKey)
    end, geterrorhandler())
  end,
  exportProfile = function(self, profileKey)
    local export
    xpcall(function()
      export = FalconPublicAPI:Export(profileKey)
    end, geterrorhandler())
    return export
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end

    local profileDataA = private:BlizzardDecodeB64CBOR(profileStringA)
    local profileDataB = private:BlizzardDecodeB64CBOR(profileStringB)

    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end
}
private.modules[m.moduleName] = m
