local _, loadingAddonNamespace = ...;
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal();
if (not private) then return; end

---@return boolean
local isLoaded = function()
  local loaded = C_AddOns.IsAddOnLoaded("AddonName")
  return loaded
end

---@return boolean
local needsInitialization = function()
  return false
end

---@return nil
local openConfig = function()

end

---@return nil
local closeConfig = function()

end

---@return table<string, any>
local getProfileKeys = function()
  return {}
end

---@return string
local getCurrentProfileKey = function()
  return ""
end

---@param profileKey string
local setProfile = function(profileKey)
  if not profileKey then return end
  if not getProfileKeys()[profileKey] then return end
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
end

---@param profileString string
---@param profileKey string
local importProfile = function(profileString, profileKey, fromIntro)
  if not profileString then return end
end

local exportOptions = {
  example = false
}
local setExportOptions = function(options)
  for k, v in pairs(options) do
    exportOptions[k] = v
  end
end

---@param profileKey string | nil
---@return string | nil
local exportProfile = function(profileKey)
  if not profileKey then return end
  if not getProfileKeys()[profileKey] then return end
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
  moduleName = "ExampleModule",
  icon = [[Interface\AddOns\Plater\images\cast_bar]], --can also be icon = 134337,
  slash = "/exampleslash",
  needReloadOnImport = true,                          --optional
  needProfileKey = true,                              --optional
  preventRename = true,                               --optional
  isLoaded = isLoaded,
  needsInitialization = needsInitialization,
  openConfig = openConfig,
  closeConfig = closeConfig,
  isDuplicate = isDuplicate,
  testImport = testImport,
  importProfile = importProfile,
  exportProfile = exportProfile,
  setExportOptions = setExportOptions, --optional
  exportGroup = nil,                   --optional
  getProfileKeys = getProfileKeys,
  getCurrentProfileKey = getCurrentProfileKey,
  setProfile = setProfile,
  areProfileStringsEqual = areProfileStringsEqual,
}
private.modules[m.moduleName] = m
