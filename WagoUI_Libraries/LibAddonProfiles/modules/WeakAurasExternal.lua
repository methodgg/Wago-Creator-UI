local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Wago WeakAuras",
  wagoId = "VBNBxKx5",
  oldestSupported = "5.17.0",
  addonNames = { "WeakAuras", "WeakAurasArchive", "WeakAurasModelPaths", "WeakAurasOptions", "WeakAurasTemplates" },
  icon = [[Interface\AddOns\WagoUI_Creator\media\wagoLogo512]],
  slash = "/wa",
  needReloadOnImport = false,
  needProfileKey = false,
  preventRename = false,
  willOverrideProfile = false,
  nonNativeProfileString = false,
  needSpecialInterface = true,
  isLoaded = function(self)
    return WeakAuras and true or false
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    if not SlashCmdList["WEAKAURAS"] then return end
    SlashCmdList["WEAKAURAS"]("")
  end,
  closeConfig = function(self)
    WeakAurasOptions:Hide()
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
  exportGroup = function(self, profileKey)
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    return false
  end,
}

private.modules[m.moduleName] = m
