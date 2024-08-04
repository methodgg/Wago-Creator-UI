local _, loadingAddonNamespace = ...;
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal();
if (not private) then return; end

---@return boolean
local isLoaded = function()
  return NameplateSCTDB and true or false
end

---@return boolean
local needsInitialization = function()
  return false
end

---@return nil
local openConfig = function()
  SlashCmdList["ACECONSOLE_NSCT"]()
end

---@return nil
local closeConfig = function()
  SettingsPanel:Hide()
end

---@return table<string, any>
local getProfileKeys = function()
  return {
    ["Global"] = true
  }
end

---@return string
local getCurrentProfileKey = function()
  return "Global"
end

---@param profileKey string
local setProfile = function(profileKey)

end

---@param profileKey string
---@return boolean
local isDuplicate = function(profileKey)
  if not profileKey then return false end
  return true
end

---@param profileString string
---@param profileKey string | nil
---@param profileData table | nil
---@param rawData table | nil
---@return string | nil
local testImport = function(profileString, profileKey, profileData, rawData)
  if not profileString then return end
  if profileData and profileData.NSCTGlobal then
    return profileKey
  end
end

---@param profileString string
---@param profileKey string
local importProfile = function(profileString, profileKey, fromIntro)
  if not profileString then return end
  local _, pData = private:GenericDecode(profileString)
  if not pData then return end
  NameplateSCTDB.global = pData.NSCTGlobal
end

---@param profileKey string | nil
---@return string | nil
local exportProfile = function(profileKey)
  if not profileKey then return end
  if not getProfileKeys()[profileKey] then return end
  local data = {
    NSCTGlobal = NameplateSCTDB.global
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
  moduleName = "NameplateSCT",
  icon = 4548873,
  slash = "/nsct",
  needReloadOnImport = true,
  needsInitialization = needsInitialization,
  needProfileKey = false,
  willOverrideProfile = true,
  isLoaded = isLoaded,
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
