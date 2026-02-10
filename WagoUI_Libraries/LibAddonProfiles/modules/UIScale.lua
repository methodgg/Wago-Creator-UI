local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "UI Scale",
  wagoId = nil,
  icon = [[Interface\Icons\INV_Misc_Spyglass_03]],
  slash = "/wagoc",
  needReloadOnImport = false,
  needProfileKey = false,
  preventRename = false,
  willOverrideProfile = false,
  nonNativeProfileString = false,
  needSpecialInterface = true,
  isLoaded = function(self)
    return true
  end,
  isUpdated = function(self)
    return true
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
  end,
  closeConfig = function(self)
  end,
  isDuplicate = function(self, profileKey)
    return false
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
  end,
  exportProfile = function(self, profileKey)
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    return false
  end,
}

private.modules[m.moduleName] = m
