local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

local optionsFrame

---@type LibAddonProfilesModule
local m = {
  moduleName = "BetterBlizzPlates",
  wagoId = "b6mb47KP",
  oldestSupported = "1.9.2",
  addonNames = { "BetterBlizzPlates" },
  conflictingAddons = {},
  icon = 135724,
  slash = "/bbp",
  needReloadOnImport = true,
  needProfileKey = false,
  preventRename = true,
  willOverrideProfile = true,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("BetterBlizzPlates")
    return loaded
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    BBP.LoadGUI()
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
      -- TODO: doesnt import, need a different function from author
      BBP.ImportProfile(profileString, "fullProfile")
    end, geterrorhandler())
  end,
  exportProfile = function(self, profileKey)
    local export
    xpcall(function()
      export = BBP.ExportProfile(BetterBlizzPlatesDB, "fullProfile")
    end, geterrorhandler())
    return export
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    -- return "!BBP" .. encoded .. "!BBP"
    local _, _, profileDataA = private:GenericDecode(profileStringA:sub(5, profileStringA:len() - 4), true, true)
    local _, _, profileDataB = private:GenericDecode(profileStringB:sub(5, profileStringB:len() - 4), true, true)
    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end
}
private.modules[m.moduleName] = m
