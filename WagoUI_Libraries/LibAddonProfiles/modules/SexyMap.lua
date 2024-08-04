local loadingAddonName, loadingAddonNamespace = ...;
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal();
if (not private) then return; end

---@return boolean
local isLoaded = function()
  return SexyMap and true or false
end

---@return boolean
local needsInitialization = function()
  return false
end

---@return nil
local openConfig = function()
  SlashCmdList["SexyMap"]("")
end

---@return nil
local closeConfig = function()
  SettingsPanel:Hide()
end

---@return table<string, any>
local getProfileKeys = function()
  -- we cannot hook refresh because the addon is not using AceDB
  -- this way we only show the key of the current character, other profiles are not shown
  local characterName = UnitName("player").."-"..GetRealmName()
  local profileKeys = {
    [characterName] = true
  }
  return profileKeys
end

---@return string
local getCurrentProfileKey = function()
  return UnitName("player").."-"..GetRealmName()
end

---@param profileKey string
local setProfile = function(profileKey)

end

---@param profileKey string
---@return boolean
local isDuplicate = function(profileKey)
  if not profileKey then return false end
  return SexyMap2DB[profileKey]
end

---@param profileString string
---@param profileKey string | nil
---@param profileData table | nil
---@param rawData table | nil
---@return string | nil
local testImport = function(profileString, profileKey, profileData, rawData)
  if not profileString then return end
  if profileData and profileData.SexyMapData then
    return profileKey
  end
end

---@param profileString string
---@param profileKey string
local importProfile = function(profileString, profileKey, fromIntro)
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
end

---@param profileKey string | nil
---@return string | nil
local exportProfile = function(profileKey)
  if not profileKey then return end
  if not getProfileKeys()[profileKey] then return end
  if not profileKey then return nil end
  local profile = SexyMap2DB[profileKey]
  if profile == "global" then
    profile = SexyMap2DB.global
    profileKey = "global"
  end
  local data = {
    SexyMapData = profile,
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
  moduleName = "SexyMap",
  icon = 237382,
  slash = "/sexymap",
  needReloadOnImport = true,
  needsInitialization = needsInitialization,
  needProfileKey = false,
  isLoaded = isLoaded,
  willOverrideProfile = true,
  openConfig = openConfig,
  closeConfig = closeConfig,
  isDuplicate = isDuplicate,
  preventRename = true,
  testImport = testImport,
  importProfile = importProfile,
  exportProfile = exportProfile,
  getProfileKeys = getProfileKeys,
  getCurrentProfileKey = getCurrentProfileKey,
  setProfile = setProfile,
  areProfileStringsEqual = areProfileStringsEqual,
}
private.modules[m.moduleName] = m
