local _, loadingAddonNamespace = ...;
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal();
if (not private) then return; end

---@return boolean
local isLoaded = function()
  local loaded = C_AddOns.IsAddOnLoaded("BugSack")
  return loaded
end

---@return boolean
local needsInitialization = function()
  return false
end

---@return nil
local openConfig = function()
  SlashCmdList["BugSack"]("")
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
  return true
end

---@param profileString string
---@param profileKey string | nil
---@param profileData table | nil
---@param rawData table | nil
---@return string | nil
local testImport = function(profileString, profileKey, profileData, rawData)
  if profileData and profileData.BugSack then
    return profileKey
  end
end

---@param profileString string
---@param profileKey string
local importProfile = function(profileString, profileKey, fromIntro)
  local _, decodedData = private:GenericDecode(profileString)
  if not decodedData then return end
  if not decodedData.BugSack or not decodedData.BugSackLDBIconDB then return end
  BugSackDB = decodedData.BugSack
  BugSackLDBIconDB = decodedData.BugSackLDBIconDB
end

---@param profileKey string | nil
---@return string | nil
local exportProfile = function(profileKey)
  if not profileKey then return nil end
  local data = {
    BugSack = BugSackDB,
    BugSackLDBIconDB = BugSackLDBIconDB
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
  moduleName = "BugSack",
  icon = [[Interface\AddOns\BugSack\Media\icon]],
  slash = "/bugsack",
  needReloadOnImport = true, --optional
  needProfileKey = false,    --optional
  preventRename = true,      --optional
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
}
private.modules[m.moduleName] = m
