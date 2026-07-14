local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

local bigWigsModule = private.modules.BigWigs
if (not bigWigsModule) then return end

---@param profileString string
local function importBossOptionsAsync(profileString)
  -- Simulates the future BigWigs async boss-options import.
  C_Timer.After(1, function()
    print("done")
  end)
end

---@type LibAddonProfilesModule
local m = {
  moduleName = "BigWigs Boss Options",
  wagoId = bigWigsModule.wagoId,
  oldestSupported = bigWigsModule.oldestSupported,
  addonNames = bigWigsModule.addonNames,
  conflictingAddons = bigWigsModule.conflictingAddons,
  icon = bigWigsModule.icon,
  slash = bigWigsModule.slash,
  needReloadOnImport = bigWigsModule.needReloadOnImport,
  needProfileKey = bigWigsModule.needProfileKey,
  preventRename = bigWigsModule.preventRename,
  willOverrideProfile = bigWigsModule.willOverrideProfile,
  nonNativeProfileString = bigWigsModule.nonNativeProfileString,
  needSpecialInterface = bigWigsModule.needSpecialInterface,
  isLoaded = function(self)
    return bigWigsModule:isLoaded()
  end,
  isUpdated = function(self)
    return bigWigsModule:isUpdated()
  end,
  needsInitialization = function(self)
    return bigWigsModule:needsInitialization()
  end,
  openConfig = function(self)
    bigWigsModule:openConfig()
  end,
  closeConfig = function(self)
    bigWigsModule:closeConfig()
  end,
  getProfileKeys = function(self)
    return bigWigsModule:getProfileKeys()
  end,
  getCurrentProfileKey = function(self)
    return bigWigsModule:getCurrentProfileKey()
  end,
  getProfileAssignments = function(self)
    return bigWigsModule:getProfileAssignments()
  end,
  isDuplicate = function(self, profileKey)
    if not profileKey then return false end
    return self:getProfileKeys()[profileKey] ~= nil
  end,
  setProfile = function(self, profileKey)
    -- Missing in BigWigsAPI: SetProfile(profileKey); SwapProfile() opens a confirmation popup.
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)

  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    -- need to see if we need to pass a callback here or wait for it to finish before we can continue
    importBossOptionsAsync(profileString)
  end,
  exportProfile = function(self, profileKey)
    -- Missing in BigWigsAPI: RequestBossOptions(addonName, optionalCallbackFunction)
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    -- Missing in BigWigsAPI: DecodeBossOptionsString(profileString)
    return false
  end
}

private.modules[m.moduleName] = m
