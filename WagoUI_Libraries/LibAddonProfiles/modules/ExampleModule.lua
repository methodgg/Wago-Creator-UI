local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Example Module",
  wagoId = "XXXXXXX", -- Replace with your Wago.io ID, "none" for Addons not on wago, "baseline" for Blizzard Addons, nil for sub modules
  oldestSupported = "1.0.0",
  addonNames = { "ExampleModule", "ExampleModule_Options", "ExampleModule_Core" },
  icon = C_AddOns.GetAddOnMetadata("ExampleAddon", "IconTexture"),
  slash = "/exampleslash",
  needReloadOnImport = false,
  needProfileKey = false,
  preventRename = false,
  willOverrideProfile = false,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("AddonName")
    return loaded
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
  end,
  closeConfig = function(self)
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
    if not profileKey then
      return false
    end
    return self:getProfileKeys()[profileKey] ~= nil
  end,
  setProfile = function(self, profileKey)
    if not profileKey then return end
    if not self:getProfileKeys()[profileKey] then
      return
    end
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    if not profileString then return end
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
  end,
  exportOptions = {
    example = false
  },
  setExportOptions = function(self, options)
    for k, v in pairs(options) do
      self.exportOptions[k] = v
    end
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    local _, profileDataA = private:GenericDecode(profileStringA)
    local _, profileDataB = private:GenericDecode(profileStringB)
    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end,
  refreshHookList = {
    {
      tableFunc = function()
        return ExampleAddon.db
      end,
      functionNames = { "SetProfile", "DeleteProfile" }
    }
  }
}
