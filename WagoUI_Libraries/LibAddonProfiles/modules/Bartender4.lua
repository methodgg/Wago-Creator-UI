local _, loadingAddonNamespace = ...;
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal();
if (not private) then return; end

---@return boolean
local isLoaded = function()
  return Bartender4 and true or false
end

---@return boolean
local needsInitialization = function()
  return false
end

---@return nil
local openConfig = function()
  SlashCmdList["ACECONSOLE_BARTENDER4"]()
end

---@return nil
local closeConfig = function()
  LibStub("AceConfigDialog-3.0"):Close("Bartender4")
end

---@return table<string, any>
local getProfileKeys = function()
  return Bartender4DB.profiles
end

---@return string
local getCurrentProfileKey = function()
  local characterName = UnitName("player").." - "..GetRealmName()
  return Bartender4DB.profileKeys and Bartender4DB.profileKeys[characterName]
end

---@param profileKey string
local setProfile = function(profileKey)
  Bartender4.db:SetProfile(profileKey)
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
  if profileKey and profileData and profileData.Bartender4DB then
    return profileKey
  end
end

---@param profileString string
---@param profileKey string
local importProfile = function(profileString, profileKey, fromIntro)
  local _, pData = private:GenericDecode(profileString)
  if not pData then return end
  local b4db = pData.Bartender4DB
  --namespaces
  for namespaceKey, namespace in pairs(b4db.namespaces) do
    if namespace.profiles then
      for _, profile in pairs(namespace.profiles) do
        Bartender4DB.namespaces = Bartender4DB.namespaces or {}
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
end

---@param profileKey string | nil
---@return string | nil
local exportProfile = function(profileKey)
  if not profileKey then return nil end
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
      namespaces = namespaces,
    },
    addonName = "Bartender4"
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
  moduleName = "Bartender4",
  slash = "/bartender",
  icon = 132792,
  needReloadOnImport = true, --optional
  needsInitialization = needsInitialization,
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
