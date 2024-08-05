local _, loadingAddonNamespace = ...;
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal();
if (not private) then return; end

---@return boolean
local isLoaded = function()
  local loaded = C_AddOns.IsAddOnLoaded("WarpDeplete")
  return loaded
end

---@return boolean
local needsInitialization = function()
  return false
end

---@return nil
local openConfig = function()
  SlashCmdList["ACECONSOLE_WARPDEPLETE"]("")
end

---@return nil
local closeConfig = function()
  SettingsPanel:Hide()
end

---@return table<string, any>
local getProfileKeys = function()
  return WarpDeplete.db.profiles
end

---@return string
local getCurrentProfileKey = function()
  return WarpDeplete.db:GetCurrentProfile()
end

---@param profileKey string
local setProfile = function(profileKey)
  if not profileKey then return end
  if not getProfileKeys()[profileKey] then return end
  WarpDeplete.db:SetProfile(profileKey)
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
local testImport = function(profileString, profileKey, profileData, rawData, moduleName)
  if not profileString then return end
  if not profileData then
    profileKey, profileData, rawData, moduleName = private:GenericDecode(profileString)
  end
  if not profileData then return end
  if not moduleName or moduleName ~= "WarpDeplete" then return end
  return profileKey
end

---@param profileString string
---@param profileKey string
local importProfile = function(profileString, profileKey, fromIntro)
  if not profileString then return end
  local decodedKey, profileData, rawData, moduleName = private:GenericDecode(profileString)
  if not profileData then return end
  if not moduleName or moduleName ~= "WarpDeplete" then return end
  profileKey = profileKey or decodedKey
  if not profileKey then return end
  WarpDeplete.db.profiles[profileKey] = profileData
  setProfile(profileKey)
end

---@param profileKey string | nil
---@return string | nil
local exportProfile = function(profileKey)
  if not profileKey then return end
  if not getProfileKeys()[profileKey] then return end
  local profileData = WarpDeplete.db.profiles[profileKey]
  if not profileData then return end
  local encoded = private:GenericEncode(profileKey, profileData, "WarpDeplete")
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
  moduleName = "WarpDeplete",
  icon = [[Interface\AddOns\WarpDeplete\logo]], --can also be icon = 134337,
  slash = "/exampleslash",
  needReloadOnImport = false,                   --self explanatory
  needProfileKey = true,                        --was used by the import anything function, might need again
  preventRename = false,                        --for AddOns that usually only have a global profile, used in the intro wizard
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
      tablePath = { "WarpDeplete", "db" },
      functionName = "SetProfile",
    },
    {
      tablePath = { "WarpDeplete", "db" },
      functionName = "DeleteProfile",
    },
  }
}
private.modules[m.moduleName] = m
