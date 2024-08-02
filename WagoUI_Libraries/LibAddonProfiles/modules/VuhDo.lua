local _, loadingAddonNamespace = ...;
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal();
if (not private) then return; end

---@return boolean
local isLoaded = function()
  local loaded = C_AddOns.IsAddOnLoaded("VuhDo")
  return loaded
end

---@return boolean
local needsInitialization = function()
  return false
end

---@return nil
local openConfig = function()
  SlashCmdList["VUHDO"]("opt")
end

---@return nil
local closeConfig = function()
  VuhDoNewOptionsTabbedFrame:Hide()
end

---@return table<string, any>
local getProfileKeys = function()
  local profileKeys = {}
  for _, profile in ipairs(VUHDO_PROFILES) do
    tinsert(profileKeys, profile.NAME)
  end
  return profileKeys
end

---@return string
local getCurrentProfileKey = function()
  return ""
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

end

---@param profileString string
---@param profileKey string
local importProfile = function(profileString, profileKey, fromIntro)

end


---@param profileKey string | nil
---@return string | nil
local exportProfile = function(profileKey)

end

---@param profileStringA string
---@param profileStringB string
---@return boolean
local areProfileStringsEqual = function(profileStringA, profileStringB)
  return false
end

---@type LibAddonProfilesModule
local m = {
  moduleName = "VuhDo",
  icon = [[Interface\AddOns\VuhDo\Images\TemporaryPortrait-Female-BloodElf-VuhDo]],
  slash = "/vuhdo",

  needReloadOnImport = true, --optional
  needProfileKey = true,     --optional
  preventRename = true,      --optional
  isLoaded = isLoaded,
  needsInitialization = needsInitialization,
  openConfig = openConfig,
  closeConfig = closeConfig,
  isDuplicate = isDuplicate,
  testImport = testImport,
  importProfile = importProfile,
  exportProfile = exportProfile,
  exportGroup = nil, --optional
  getProfileKeys = getProfileKeys,
  getCurrentProfileKey = getCurrentProfileKey,
  setProfile = setProfile,
  areProfileStringsEqual = areProfileStringsEqual,
}
private.modules[m.moduleName] = m
