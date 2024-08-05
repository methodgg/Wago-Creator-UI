local _, loadingAddonNamespace = ...;
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal();
if (not private) then return; end

---@return boolean
local isLoaded = function()
  local loaded = C_AddOns.IsAddOnLoaded("Kui_Nameplates")
  return loaded
end

---@return boolean
local needsInitialization = function()
  return false
end

---@return nil
local openConfig = function()
  local core = SlashCmdList["KUINAMEPLATESCORE"]
  local lod = SlashCmdList["KUINAMEPLATES_LOD"]
  if core then core("") elseif lod then lod("") end
end

---@return nil
local closeConfig = function()
  SettingsPanel:Hide()
end

---@return table<string, any>
local getProfileKeys = function()
  return KuiNameplatesCoreSaved.profiles
end

---@return string
local getCurrentProfileKey = function()
  return KuiNameplatesCoreCharacterSaved.profile
end

---@param profileKey string
local setProfile = function(profileKey)
  if not profileKey then return end
  if not getProfileKeys()[profileKey] then return end
  local config = KuiNameplatesCore.config
  config:SetProfile(profileKey)
end

---@param profileKey string
---@return boolean
local isDuplicate = function(profileKey)
  if not profileKey then return false end
  return getProfileKeys()[profileKey]
end

---@param profileString string
---@return table | nil
local decodeProfileString = function(profileString)
  local decodedName, decodedProfileString
  local firstBracket = strfind(profileString, '{')
  if firstBracket and firstBracket > 1 then
    decodedName = strsub(profileString, 1, firstBracket - 1)
    decodedProfileString = strsub(profileString, firstBracket)
  else
    decodedName = 'import'
  end
  profileKey = profileKey or decodedName
  local kui = LibStub('Kui-1.0')
  ---@diagnostic disable-next-line: undefined-field
  local table, tlen = kui.string_to_table(decodedProfileString)
  if not table or tlen == 0 then return end
  return table
end

---@param profileString string
---@param profileKey string | nil
---@param profileData table | nil
---@param rawData table | nil
---@return string | nil
local testImport = function(profileString, profileKey, profileData, rawData)
  if not profileString then return end
  local table = decodeProfileString(profileString)
  --very weird export format
  --need to check in the future if this test causes issues if another addon has a format like this
  if table then return profileKey end
end

---@param profileString string
---@param profileKey string
local importProfile = function(profileString, profileKey, fromIntro)
  if not profileString then return end
  local table = decodeProfileString(profileString)
  local config = KuiNameplatesCore.config
  config.csv.profile = profileKey
  config:PostProfile(profileKey, table)
end

---@param profileKey string | nil
---@return string | nil
local exportProfile = function(profileKey)
  if not profileKey then return end
  if not getProfileKeys()[profileKey] then return end
  local kui = LibStub('Kui-1.0')
  ---@diagnostic disable-next-line: undefined-field
  local tableToString = kui.table_to_string
  local config = KuiNameplatesCore.config
  -- dont use GetProfile, it has unwanted side effects
  local profile = config.gsv.profiles[profileKey]
  local encoded = tableToString(profile)
  local export = profileKey..encoded
  return export
end

---@param profileStringA string
---@param profileStringB string
---@return boolean
local areProfileStringsEqual = function(profileStringA, profileStringB)
  if not profileStringA or not profileStringB then return false end
  local tableA = decodeProfileString(profileStringA)
  local tableB = decodeProfileString(profileStringB)
  if not tableA or not tableB then return false end
  return private:DeepCompareAsync(tableA, tableB)
end

--TODO
---@type LibAddonProfilesModule
local m = {
  moduleName = "Kui Nameplates",
  icon = 132177,
  slash = "/knp",
  needReloadOnImport = true,
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
  refreshHookList = {
    {
      tablePath = { "KuiNameplatesCore" },
      functionName = "ConfigChanged",
    },
    {
      tablePath = { "KuiNameplatesCore", "config" },
      functionName = "PostProfile",
    },
  },
}
private.modules[m.moduleName] = m
