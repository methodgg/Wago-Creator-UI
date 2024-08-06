local _, loadingAddonNamespace = ...;
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal();
if (not private) then return; end

---@return boolean
local isLoaded = function()
  return ShadowUF and true or false
end

---@return boolean
local needsInitialization = function()
  return false
end

---@return nil
local openConfig = function()
  SlashCmdList["SHADOWEDUF"]("")
end

---@return nil
local closeConfig = function()
  LibStub("AceConfigDialog-3.0"):Close("ShadowedUF")
end

---@return table<string, any>
local getProfileKeys = function()
  return ShadowedUFDB.profiles
end

---@return string
local getCurrentProfileKey = function()
  local characterName = UnitName("player").." - "..GetRealmName()
  return ShadowedUFDB.profileKeys and ShadowedUFDB.profileKeys[characterName]
end

---@param profileKey string
local setProfile = function(profileKey)
  if not profileKey then return end
  if not getProfileKeys()[profileKey] then return end
  ShadowUF.db:SetProfile(profileKey)
end

---@param profileKey string
---@return boolean
local isDuplicate = function(profileKey)
  if not profileKey then return false end
  return ShadowUF.db.profiles[profileKey]
end

---@param profileString string
---@param profileKey string | nil
---@param profileData table | nil
---@param rawData table | nil
---@return string | nil
local testImport = function(profileString, profileKey, profileData, rawData)
  if not profileString then return end
  if profileData and profileData.auraColors and profileData.auraIndicators and profileData.visibility and profileData.wowBuild then
    return profileKey
  end
  -- dont accept normal SUF exports as they are insecure
end

---@param profileString string
---@param profileKey string
local importProfile = function(profileString, profileKey, fromIntro)
  if not profileString then return end
  local _, pData = private:GenericDecode(profileString)
  if not pData then return end
  ShadowUF.db:SetProfile(profileKey)
  ShadowUF:LoadDefaultLayout()
  for key, data in pairs(pData) do
    if (type(data) == "table") then
      ShadowUF.db.profile[key] = CopyTable(data)
    else
      ShadowUF.db.profile[key] = data
    end
  end
  ShadowUF:ProfilesChanged()
end

---@param profileKey string | nil
---@return string | nil
local exportProfile = function(profileKey)
  if not profileKey then return end
  if not getProfileKeys()[profileKey] then return end
  return private:GenericEncode(profileKey, ShadowedUFDB.profiles[profileKey])
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
  moduleName = "ShadowedUnitFrames",
  icon = 136200,
  slash = "/suf",
  needReloadOnImport = false,
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
  nonNativeProfileString = true,
  refreshHookList = {
    {
      tableFunc = function()
        return ShadowUF.db
      end,
      functionNames = { "SetProfile", "CopyProfile", "DeleteProfile" }
    },
  },
}
private.modules[m.moduleName] = m
