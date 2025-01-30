local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Bartender4",
  wagoId = "v63oVn6b",
  oldestSupported = "4.15.0",
  addonNames = { "Bartender4" },
  conflictingAddons = { "Dominos", "ElvUI", "ElvUI_Libraries", "ElvUI_Options" },
  icon = C_AddOns.GetAddOnMetadata("Bartender4", "IconTexture"),
  slash = "/bartender",
  needReloadOnImport = true,
  needProfileKey = false,
  preventRename = true,
  willOverrideProfile = true,
  nonNativeProfileString = true,
  needSpecialInterface = false,
  isLoaded = function(self)
    return Bartender4 and true or false
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    if not SlashCmdList["ACECONSOLE_BARTENDER4"] then
      return
    end
    SlashCmdList["ACECONSOLE_BARTENDER4"]()
  end,
  closeConfig = function(self)
    LibStub("AceConfigDialog-3.0"):Close("Bartender4")
  end,
  getProfileKeys = function(self)
    return Bartender4DB.profiles
  end,
  getCurrentProfileKey = function(self)
    local characterName = UnitName("player").." - "..GetRealmName()
    return Bartender4DB.profileKeys and Bartender4DB.profileKeys[characterName]
  end,
  getProfileAssignments = function(self)
    return Bartender4DB.profileKeys
  end,
  isDuplicate = function(self, profileKey)
    if not profileKey then return false end
    return self:getProfileKeys()[profileKey] ~= nil
  end,
  setProfile = function(self, profileKey)
    if not profileKey then return end
    if not self:getProfileKeys()[profileKey] then return end
    Bartender4.db:SetProfile(profileKey)
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    if not profileString then return end
    if profileKey and profileData and profileData.Bartender4DB then
      return profileKey
    end
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    local _, pData = private:GenericDecode(profileString)
    if not pData then return end
    local b4db = pData.Bartender4DB
    --namespaces
    for namespaceKey, namespace in pairs(b4db.namespaces) do
      if namespace.profiles then
        for _, profile in pairs(namespace.profiles) do
          Bartender4DB.namespaces = Bartender4DB.namespaces or {}
          Bartender4DB.namespaces[namespaceKey] = Bartender4DB.namespaces[namespaceKey] or {}
          Bartender4DB.namespaces[namespaceKey].profiles = Bartender4DB.namespaces[namespaceKey].profiles or {}
          Bartender4DB.namespaces[namespaceKey].profiles[profileKey] = profile
        end
      end
    end
    --profileKey
    Bartender4DB.profileKeys = Bartender4DB.profileKeys or {}
    Bartender4DB.profileKeys[UnitName("player").." - "..GetRealmName()] = profileKey
    --profiles
    for _, profile in pairs(b4db.profiles) do
      Bartender4DB.profiles = Bartender4DB.profiles or {}
      Bartender4DB.profiles[profileKey] = profile
    end
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local profiles = { [profileKey] = Bartender4DB.profiles[profileKey] }
    local profileKeys = { ["important"] = profileKey }
    local namespaces = {}
    for namespaceKey, namespace in pairs(Bartender4DB.namespaces) do
      if namespace.profiles then
        local namespaceData = namespace.profiles[profileKey]
        if namespaceData then
          namespaces[namespaceKey] = {
            profiles = {
              [profileKey] = namespaceData
            }
          }
        end
      end
    end
    local data = {
      Bartender4DB = {
        profiles = profiles,
        profileKeys = profileKeys,
        namespaces = namespaces
      }
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
        return Bartender4.db
      end,
      functionNames = { "SetProfile", "CopyProfile", "DeleteProfile" }
    }
  }
}
private.modules[m.moduleName] = m
