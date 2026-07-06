local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "BliZzi Party Tools",
  wagoId = "BKpgeB6E",
  oldestSupported = "4.1.4",
  addonNames = { "BliZzi_Interrupts" },
  conflictingAddons = {},
  icon = C_AddOns.GetAddOnMetadata("BliZzi_Interrupts", "IconTexture"),
  slash = "/blizzi",
  needReloadOnImport = false,
  needProfileKey = false,
  preventRename = true,
  willOverrideProfile = true,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("BliZzi_Interrupts")
    return loaded
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    xpcall(function()
      BIT.SettingsUI:Toggle()
    end, geterrorhandler())
  end,
  closeConfig = function(self)
    xpcall(function()
      BIT.SettingsUI:Toggle()
    end, geterrorhandler())
  end,
  getProfileKeys = function(self)
    local profileKeys = {
      ["Global"] = true,
    }
    return profileKeys
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
      BIT.ImportProfile(profileString)
    end, geterrorhandler())
  end,
  exportProfile = function(self, profileKey)
    if profileKey and type(profileKey) ~= "string" then return end
    if profileKey and not self:getProfileKeys()[profileKey] then return end
    local export
    xpcall(function()
      export = BIT.ExportProfile(nil, true)
    end, geterrorhandler())
    return export
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    if profileStringA == profileStringB then
      return true
    end
    local profileDataA, profileDataB
    xpcall(function()
      -- TODO: Missing in installed addon source: BIT.DecodeProfileString(profileString)
      -- implement when fixed in addon source
    end, geterrorhandler())
    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB, {
      addonVersion = true,
      formatVersion = true,
    })
  end
}

private.modules[m.moduleName] = m
