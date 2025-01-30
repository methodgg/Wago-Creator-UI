local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "OmniCC",
  wagoId = "baNDDpNo",
  oldestSupported = "11.0.1",
  addonNames = { "OmniCC", "OmniCC_Config" },
  icon = C_AddOns.GetAddOnMetadata("OmniCC", "IconTexture"),
  slash = "/omnicc",
  needReloadOnImport = true,
  needProfileKey = false,
  preventRename = false,
  willOverrideProfile = false,
  nonNativeProfileString = true,
  needSpecialInterface = false,
  isLoaded = function(self)
    return OmniCC and true or false
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    if not SlashCmdList["OmniCC"] then return end
    SlashCmdList["OmniCC"]()
  end,
  closeConfig = function(self)
    LibStub("AceConfigDialog-3.0"):Close("OmniCC")
  end,
  getProfileKeys = function(self)
    return OmniCCDB.profiles
  end,
  getCurrentProfileKey = function(self)
    local characterName = UnitName("player").." - "..GetRealmName()
    return OmniCCDB.profileKeys[characterName]
  end,
  getProfileAssignments = function(self)
    return OmniCCDB.profileKeys
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
    OmniCC.db:SetProfile(profileKey)
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    if not profileString then return end
    if profileData and profileData.OmniCC4Config then
      return profileKey
    end
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    local _, pData = private:GenericDecode(profileString)
    if not pData then return end
    OmniCCDB.profileKeys = OmniCCDB.profileKeys or {}
    OmniCCDB.profileKeys[UnitName("player").." - "..GetRealmName()] = profileKey
    OmniCCDB.profiles = OmniCCDB.profiles or {}
    OmniCCDB.profiles[profileKey] = pData.profiles[profileKey]
    OmniCC4Config = pData.OmniCC4Config
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local data = {
      global = OmniCCDB.global,
      profileKeys = {
        [""] = profileKey
      },
      profiles = {
        [profileKey] = OmniCCDB.profiles[profileKey]
      },
      OmniCC4Config = OmniCC4Config
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
        return OmniCC.db
      end,
      functionNames = { "SetProfile", "DeleteProfile" }
    }
  }
}

private.modules[m.moduleName] = m
