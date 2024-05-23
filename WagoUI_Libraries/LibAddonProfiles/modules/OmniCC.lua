local _, loadingAddonNamespace = ...;
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal();
if (not private) then return; end

---@return boolean
local isLoaded = function()
  return OmniCC and true or false
end

---@return boolean
local needsInitialization = function()
  return false
end

---@return nil
local openConfig = function()
  SlashCmdList["OmniCC"]()
end

---@return nil
local closeConfig = function()
  LibStub("AceConfigDialog-3.0"):Close("OmniCC")
end

---@return table<string, any>
local getProfileKeys = function()
  return OmniCCDB.profiles
end

---@return string
local getCurrentProfileKey = function()
  local characterName = UnitName("player").." - "..GetRealmName()
  return OmniCCDB.profileKeys[characterName]
end

---@param profileKey string
local setProfile = function(profileKey)
  OmniCC.db:SetProfile(profileKey)
end

---@param profileKey string
---@return boolean
local isDuplicate = function(profileKey)
  return getProfileKeys()[profileKey]
end

---@param profileString string
---@param profileKey string | nil
---@param profileData table | nil
---@param rawData table | nil
---@return string | nil
local testImport = function(profileString, profileKey, profileData, rawData)
  if profileData and profileData.OmniCC4Config then
    return profileKey
  end
end

---@param profileString string
---@param profileKey string
---@param isDuplicateProfile boolean
local importProfile = function(profileString, profileKey, isDuplicateProfile)
  local _, pData = private:GenericDecode(profileString)
  if not pData then return end
  OmniCCDB.profileKeys = OmniCCDB.profileKeys or {}
  OmniCCDB.profileKeys[UnitName("player").." - "..GetRealmName()] = profileKey
  OmniCCDB.profiles = OmniCCDB.profiles or {}
  OmniCCDB.profiles[profileKey] = pData.profiles[profileKey]
  OmniCC4Config = pData.OmniCC4Config
end

---@param profileKey string | nil
---@return string | nil
local exportProfile = function(profileKey)
  if not profileKey then return nil end
  local data = {
    global = OmniCCDB.global,
    profileKeys = {
      [""] = profileKey
    },
    profiles = {
      [profileKey] = OmniCCDB.profiles[profileKey]
    },
    OmniCC4Config = OmniCC4Config,
  }
  return private:GenericEncode(profileKey, data)
end

---@param profileStringA string
---@param profileStringB string
---@return boolean
local areProfileStringsEqual = function(profileStringA, profileStringB)
  if not profileStringA or not profileStringB then return false end
  local _, profileDataA = private:GenericDecode(profileStringA)
  local _, profileDataB = private:GenericDecode(profileStringB)
  if not profileDataA or not profileDataB then return false end
  return private:DeepCompareAsync(profileDataA, profileDataB)
end

---@type LibAddonProfilesModule
local m = {
  moduleName = "OmniCC",
  icon = 136106,
  slash = "/omnicc",
  needReloadOnImport = true,
  needsInitialization = needsInitialization,
  needProfileKey = false,
  isLoaded = isLoaded,
  openConfig = openConfig,
  closeConfig = closeConfig,
  isDuplicate = isDuplicate,
  testImport = testImport,
  importProfile = importProfile,
  exportProfile = exportProfile,
  getProfileKeys = getProfileKeys,
  getCurrentProfileKey = getCurrentProfileKey,
  setProfile = setProfile,
  areProfileStringsEqual = areProfileStringsEqual,
}
private.modules[m.moduleName] = m
