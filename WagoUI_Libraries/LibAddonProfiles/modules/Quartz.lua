local _, loadingAddonNamespace = ...;
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal();
if (not private) then return; end

---@return boolean
local isLoaded = function()
  local loaded = C_AddOns.IsAddOnLoaded("Quartz")
  return loaded
end

---@return boolean
local needsInitialization = function()
  return false
end

---@return nil
local openConfig = function()
  SlashCmdList["ACECONSOLE_QUARTZ"]()
end

---@return nil
local closeConfig = function()
  SettingsPanel:Hide()
end

---@return table<string, any>
local getProfileKeys = function()
  return Quartz3DB.profiles
end

---@return string
local getCurrentProfileKey = function()
  local characterName = UnitName("player").." - "..GetRealmName()
  return Quartz3DB.profileKeys and Quartz3DB.profileKeys[characterName]
end

---@param profileKey string
local setProfile = function(profileKey)
  if not profileKey then return end
  if not getProfileKeys()[profileKey] then return end
  local Quartz = LibStub("AceAddon-3.0"):GetAddon("Quartz3")
  ---@diagnostic disable-next-line: undefined-field
  Quartz.db:SetProfile(profileKey)
end

---@param profileKey string
---@return boolean
local isDuplicate = function(profileKey)
  if not profileKey then return false end
  return getProfileKeys()[profileKey] ~= nil
end

---@param profileString string
---@param profileKey string | nil
---@param profileData table | nil
---@param rawData table | nil
---@return string | nil
local testImport = function(profileString, profileKey, profileData, rawData)
  if not profileString then return end
  if not profileData then
    profileKey, profileData, rawData, moduleName = private:GenericDecode(profileString)
  end
  if not profileData then return end
  if not moduleName or moduleName ~= "Quartz" then return end
  return profileKey
end

---@param profileString string
---@param profileKey string
local importProfile = function(profileString, profileKey, fromIntro)
  if not profileString then return end
  local decodedKey, profileData, rawData, moduleName = private:GenericDecode(profileString)
  if not profileData then return end
  if not moduleName or moduleName ~= "Quartz" then return end
  profileKey = profileKey or decodedKey
  if not profileKey then return end
  local Quartz = LibStub("AceAddon-3.0"):GetAddon("Quartz3")
  ---@diagnostic disable-next-line: undefined-field
  Quartz.db.profiles[profileKey] = profileData
  setProfile(profileKey)
end

---@param profileKey string | nil
---@return string | nil
local exportProfile = function(profileKey)
  if not profileKey then return end
  if not getProfileKeys()[profileKey] then return end
  local Quartz = LibStub("AceAddon-3.0"):GetAddon("Quartz3")
  ---@diagnostic disable-next-line: undefined-field
  local profileData = Quartz.db.profiles[profileKey]
  if not profileData then return end
  local encoded = private:GenericEncode(profileKey, profileData, "Quartz")
  return encoded
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
  moduleName = "Quartz",
  icon = 136235,
  slash = "/quartz",
  needReloadOnImport = false,
  needProfileKey = true,
  preventRename = false,
  isLoaded = isLoaded,
  needsInitialization = needsInitialization,
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
  nonNativeProfileString = true,
  refreshHookList = {
    {
      tableFunc = function()
        local Quartz = LibStub("AceAddon-3.0"):GetAddon("Quartz3")
        ---@diagnostic disable-next-line: undefined-field
        return Quartz.db
      end,
      functionNames = { "SetProfile", "DeleteProfile" },
    },
  },
}
private.modules[m.moduleName] = m
