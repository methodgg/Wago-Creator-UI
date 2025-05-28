local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "WeakAurasExternal",
  wagoId = nil,
  icon = [[Interface\AddOns\WagoUI_Creator\media\wagoLogo512]],
  slash = "",
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
    local LAP = LibStub:GetLibrary("LibAddonProfiles")
    local waModule = LAP:GetModule("WeakAuras")
    return private:GenericVersionCheck(waModule)
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
