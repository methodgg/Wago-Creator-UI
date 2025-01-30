local loadingAddonName, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "SexyMap",
  wagoId = "e56no0K9",
  oldestSupported = "v11.0.1",
  addonNames = { "SexyMap" },
  icon = C_AddOns.GetAddOnMetadata("SexyMap", "IconTexture"),
  slash = "/sexymap",
  needReloadOnImport = true,
  needProfileKey = false,
  preventRename = true,
  willOverrideProfile = true,
  nonNativeProfileString = true,
  needSpecialInterface = false,
  isLoaded = function(self)
    return SexyMap and true or false
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    if not SlashCmdList["SexyMap"] then return end
    SlashCmdList["SexyMap"]("")
  end,
  closeConfig = function(self)
    SettingsPanel:Hide()
  end,
  getProfileKeys = function(self)
    -- we cannot hook refresh because the addon is not using AceDB
    -- this way we only show the key of the current character, other profiles are not shown
    local characterName = UnitName("player").."-"..GetRealmName()
    local profileKeys = {
      [characterName] = true
    }
    return profileKeys
  end,
  getCurrentProfileKey = function(self)
    return UnitName("player").."-"..GetRealmName()
  end,
  isDuplicate = function(self, profileKey)
    if not profileKey then
      return false
    end
    return SexyMap2DB[profileKey]
  end,
  setProfile = function(self, profileKey)
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    if not profileString then return end
    if profileData and profileData.SexyMapData then
      return profileKey
    end
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    local _, pData = private:GenericDecode(profileString)
    if not pData then return end
    if profileKey == "global" then
      SexyMap2DB.global = pData.SexyMapData
      local characterName = UnitName("player").."-"..GetRealmName()
      SexyMap2DB[characterName] = "global"
    else
      SexyMap2DB[profileKey] = pData.SexyMapData
    end
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local profile = SexyMap2DB[profileKey]
    if profile == "global" then
      profile = SexyMap2DB.global
      profileKey = "global"
    end
    local data = {
      SexyMapData = profile
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
