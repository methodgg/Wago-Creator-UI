local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "DandersFrames Click Castings",
  wagoId = "RNL9B46o",
  oldestSupported = "3.1.12",
  addonNames = { "DandersFrames" },
  conflictingAddons = {},
  icon = C_AddOns.GetAddOnMetadata("DandersFrames", "IconTexture"),
  slash = "/df",
  needReloadOnImport = true,
  needProfileKey = true,
  preventRename = false,
  willOverrideProfile = false,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("DandersFrames")
    return loaded
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    if not SlashCmdList["DANDERSFRAMES"] then return end
    SlashCmdList["DANDERSFRAMES"]("")
  end,
  closeConfig = function(self)
    DandersFramesGUI:Hide()
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
      DandersFrames_ClickCast_Import(profileString, true)
    end, geterrorhandler())
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    local export
    xpcall(function()
      export = DandersFrames_ClickCast_Export()
    end, geterrorhandler())
    return export
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    --TODO TEST THIS
    local _, _, profileDataA = private:GenericDecode(profileStringA, false, true)
    local _, _, profileDataB = private:GenericDecode(profileStringB, false, true)
    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end
}
private.modules[m.moduleName] = m
