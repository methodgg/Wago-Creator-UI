local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Midnight Simple Unit Frames",
  wagoId = "XKq9aoKy",
  oldestSupported = "1.62",
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
    local loaded = C_AddOns.IsAddOnLoaded("UnhaltedUF")
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

  end,
  getCurrentProfileKey = function(self)

  end,
  isDuplicate = function(self, profileKey)

  end,
  setProfile = function(self, profileKey)

  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)

  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    xpcall(function()

    end, geterrorhandler())
  end,
  exportProfile = function(self, profileKey)
    local export
    xpcall(function()

    end, geterrorhandler())
    return export
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    -- TODO TEST THIS
    local profileDataA = C_EncodingUtil.DeserializeCBOR(C_EncodingUtil.DecodeBase64(profileStringA))
    local profileDataB = C_EncodingUtil.DeserializeCBOR(C_EncodingUtil.DecodeBase64(profileStringB))
    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end
}
private.modules[m.moduleName] = m
