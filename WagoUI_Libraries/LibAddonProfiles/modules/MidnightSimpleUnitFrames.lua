local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Midnight Simple Unit Frames",
  wagoId = "XKq9aoKy",
  oldestSupported = "1.67",
  addonNames = { "MidnightSimpleUnitFrames" },
  conflictingAddons = { "BetterBlizzFrames", "UnhaltedUF", "ShadowedUnitFrames", "ShadowedUF_Options", "PitBull4" },
  icon = C_AddOns.GetAddOnMetadata("MidnightSimpleUnitFrames", "IconTexture"),
  slash = "/msuf",
  needReloadOnImport = true,
  needProfileKey = true,
  preventRename = false,
  willOverrideProfile = true,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("MidnightSimpleUnitFrames")
    return loaded
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    if not SlashCmdList["MSUFOPTIONS"] then return end
    SlashCmdList["MSUFOPTIONS"]()
  end,
  closeConfig = function(self)
    MSUF_StandaloneOptionsWindow:Hide()
  end,
  getProfileKeys = function(self)
    return MSUF_GlobalDB.profiles
  end,
  getCurrentProfileKey = function(self)
    local characterName = UnitName("player").."-"..GetRealmName()
    return MSUF_GlobalDB.char and MSUF_GlobalDB.char[characterName].activeProfile
  end,
  isDuplicate = function(self, profileKey)
    if not profileKey then return false end
    return self:getProfileKeys()[profileKey] ~= nil
  end,
  setProfile = function(self, profileKey)
    local characterName = UnitName("player").."-"..GetRealmName()
    MSUF_GlobalDB.char[characterName].activeProfile = profileKey
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)

  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    local success
    xpcall(function()
      success = MSUF_ImportExternal(profileString, profileKey)
    end, geterrorhandler())
    if success then
      self:setProfile(profileKey)
    end
  end,
  exportProfile = function(self, profileKey)
    local export, _
    xpcall(function()
      _, export = MSUF_ExportExternal(profileKey)
    end, geterrorhandler())
    return export
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    local profileDataA = private:BlizzardDecodeB64CBOR(profileStringA:sub(7), true)
    local profileDataB = private:BlizzardDecodeB64CBOR(profileStringB:sub(7), true)
    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end
}
private.modules[m.moduleName] = m
