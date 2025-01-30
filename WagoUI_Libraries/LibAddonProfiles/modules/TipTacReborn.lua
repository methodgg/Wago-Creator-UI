local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "TipTac Reborn",
  wagoId = "none",
  oldestSupported = "24.08.26",
  addonNames = { "TipTac", "TipTacItemRef", "TipTacOptions", "TipTacTalents" },
  icon = C_AddOns.GetAddOnMetadata("TipTac", "IconTexture"),
  slash = "/tiptac",
  needReloadOnImport = true,
  needProfileKey = false,
  preventRename = true,
  willOverrideProfile = true,
  nonNativeProfileString = true,
  needSpecialInterface = false,
  isLoaded = function(self)
    return TipTac and true or false
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    if not SlashCmdList["TIPTAC"] then return end
    SlashCmdList["TIPTAC"]("")
  end,
  closeConfig = function(self)
    TipTacOptions:Hide()
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
    if not profileString then return end
    if profileData and profileData.TipTacGlobal then
      return profileKey
    end
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    local _, pData = private:GenericDecode(profileString)
    if not pData then return end
    TipTac_Config = pData.TipTacGlobal
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    local data = {
      TipTacGlobal = TipTac_Config
    }
    return private:GenericEncode(profileKey, data, self.moduleName)
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
  end
}

private.modules[m.moduleName] = m
