local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Advanced Focus Cast Bar",
  wagoId = "96d2DPGO",
  oldestSupported = "1.0.0",
  addonNames = { "AdvancedFocusCastBar" },
  conflictingAddons = {},
  icon = C_AddOns.GetAddOnMetadata("AdvancedFocusCastBar", "IconTexture"),
  slash = "?",
  needReloadOnImport = false,
  needProfileKey = false,
  preventRename = true,
  willOverrideProfile = true,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("AdvancedFocusCastBar")
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
    return {
      ["Global"] = true
    }
  end,
  getCurrentProfileKey = function(self)
    if AdvancedFocusCastBarAPI and AdvancedFocusCastBarAPI.GetCurrentProfileKey then
      return AdvancedFocusCastBarAPI.GetCurrentProfileKey()
    end
    return "Global"
  end,
  isDuplicate = function(self, profileKey)
    return true
  end,
  setProfile = function(self, profileKey)
    if AdvancedFocusCastBarAPI and AdvancedFocusCastBarAPI.SetProfile then
      AdvancedFocusCastBarAPI.SetProfile(profileKey)
    end
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)

  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    xpcall(function()
      if AdvancedFocusCastBarAPI and AdvancedFocusCastBarAPI.ImportProfile then
        AdvancedFocusCastBarAPI.ImportProfile(profileString)
      end
    end, geterrorhandler())
  end,
  exportProfile = function(self, profileKey)
    local export
    xpcall(function()
      if AdvancedFocusCastBarAPI and AdvancedFocusCastBarAPI.ExportProfile then
        export = AdvancedFocusCastBarAPI.ExportProfile()
      end
    end, geterrorhandler())
    return export
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    local profileDataA = AdvancedFocusCastBarAPI.DecodeProfileString(profileStringA)
    local profileDataB = AdvancedFocusCastBarAPI.DecodeProfileString(profileStringB)
    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end
}
private.modules[m.moduleName] = m
