local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "BlizzHUDTweaks",
  wagoId = "rkGrWlNy",
  oldestSupported = "1.50.0",
  addonNames = { "BlizzHUDTweaks" },
  icon = C_AddOns.GetAddOnMetadata("BlizzHUDTweaks", "IconTexture"),
  slash = "/bht",
  needReloadOnImport = true,
  needProfileKey = true,
  preventRename = false,
  willOverrideProfile = false,
  nonNativeProfileString = true,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("BlizzHUDTweaks")
    return (loaded and BlizzHUDTweaksDB) and true or false
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    if not SlashCmdList["ACECONSOLE_BHT"] then
      return
    end
    SlashCmdList["ACECONSOLE_BHT"]()
  end,
  closeConfig = function(self)
    SettingsPanel:Hide()
  end,
  getProfileKeys = function(self)
    return BlizzHUDTweaksDB.profiles
  end,
  getCurrentProfileKey = function(self)
    local characterName = UnitName("player").." - "..GetRealmName()
    return BlizzHUDTweaksDB.profileKeys and BlizzHUDTweaksDB.profileKeys[characterName]
  end,
  getProfileAssignments = function(self)
    return BlizzHUDTweaksDB.profileKeys
  end,
  isDuplicate = function(self, profileKey)
    if not profileKey then
      return false
    end
    return self:getProfileKeys()[profileKey] ~= nil
  end,
  setProfile = function(self, profileKey)
    if not profileKey then return end
    if not self:getProfileKeys()[profileKey] then return end
    ---@diagnostic disable-next-line: undefined-field
    LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks").db:SetProfile(profileKey)
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    if not profileString then return end
    if profileKey and profileData and profileData.global then
      return profileKey
    end
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    local _, pData = private:GenericDecode(profileString)
    if not pData then
      return
    end
    BlizzHUDTweaksDB.global = pData.global
    BlizzHUDTweaksDB.profiles[profileKey] = pData.profile
    BlizzHUDTweaksDB.profileKeys[UnitName("player").." - "..GetRealmName()] = profileKey
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local data = {
      global = BlizzHUDTweaksDB.global,
      profile = BlizzHUDTweaksDB.profiles[profileKey],
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
  end,
  refreshHookList = {
    {
      tableFunc = function()
        ---@diagnostic disable-next-line: undefined-field
        return LibStub("AceAddon-3.0"):GetAddon("BlizzHUDTweaks").db
      end,
      functionNames = { "SetProfile", "DeleteProfile" }
    }
  }
}

private.modules[m.moduleName] = m
