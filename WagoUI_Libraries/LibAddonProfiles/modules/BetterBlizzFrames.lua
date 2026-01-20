local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

local optionsFrame

---@type LibAddonProfilesModule
local m = {
  moduleName = "BetterBlizzFrames",
  wagoId = "qGZR02Gd",
  oldestSupported = "1.8.7",
  addonNames = { "BetterBlizzFrames" },
  conflictingAddons = { "UnhaltedUF", "MidnightSimpleUnitFrames", "ShadowedUnitFrames", "ShadowedUF_Options", "PitBull4" },
  icon = 135724,
  slash = "/bbf",
  needReloadOnImport = true,
  needProfileKey = false,
  preventRename = true,
  willOverrideProfile = true,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("BetterBlizzFrames")
    return loaded
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    BBF.LoadGUI()
  end,
  closeConfig = function(self)
    SettingsPanel:Hide()
  end,
  getProfileKeys = function(self)
    return {
      ["Global"] = true
    }
  end,
  getCurrentProfileKey = function(self)
    return "Global"
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
      BBF.ImportProfile(profileString)
    end, geterrorhandler())
  end,
  exportProfile = function(self, profileKey)
    local export
    xpcall(function()
      export = BBF.ExportProfile(BetterBlizzFramesDB, "fullProfile")
    end, geterrorhandler())
    return export
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    -- return "!BBF" .. encoded .. "!BBF"
    local _, _, profileDataA = private:GenericDecode(profileStringA:sub(5, profileStringA:len() - 4), true)
    local _, _, profileDataB = private:GenericDecode(profileStringB:sub(5, profileStringB:len() - 4), true)
    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end
}
private.modules[m.moduleName] = m
