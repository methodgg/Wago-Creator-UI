local _, loadingAddonNamespace = ...;
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal();
if (not private) then return; end
local EXPORT_PREFIX = '!E1!'

---@return boolean
local isLoaded = function()
  return ElvUI and ElvUI[1].Options.args.profiles and true or false
end

---@return boolean
local needsInitialization = function()
  return C_AddOns.IsAddOnLoaded("ElvUI") and not isLoaded()
end

---@return nil
local openConfig = function()
  SlashCmdList["ACECONSOLE_ELVUI"]()
end

---@return nil
local closeConfig = function()
  local E = unpack(ElvUI)
  E.Config_CloseWindow()
end

---@return table<string, any>
local getProfileKeys = function()
  return ElvPrivateDB.profiles
end

---@return string
local getCurrentProfileKey = function()
  local E = unpack(ElvUI)
  return ElvPrivateDB.profileKeys and ElvPrivateDB.profileKeys[E.mynameRealm]
end

---@param profileKey string
local setProfile = function(profileKey)
  if not profileKey then return end
  if not getProfileKeys()[profileKey] then return end
  local E = unpack(ElvUI)
  ElvPrivateDB.profileKeys[E.mynameRealm] = profileKey
end

---@param profileKey string
---@return boolean
local isDuplicate = function(profileKey)
  if not profileKey then return false end
  return ElvPrivateDB.profiles[profileKey] and true or false
end

---@param profileString string
---@param profileKey string | nil
---@param profileData table | nil
---@param rawData table | nil
---@return string | nil
local testImport = function(profileString, profileKey, profileData, rawData)
  if not profileString then return end
  local prefix = strsub(profileString, 1, 4)
  if prefix ~= EXPORT_PREFIX then return nil end
  local distributor = ElvUI[1]:GetModule("Distributor");
  local profileType, _, data = distributor:Decode(profileString)
  if profileType == "private" and data then
    return ""
  end
end

---@param profileString string
---@param profileKey string
local importProfile = function(profileString, profileKey, fromIntro)
  if not profileString then return end
  -- TODO: do we even want to change this to use D:ImportProfile?
  -- seems simple enough as it is and sets the profile key (maybe this is not wanted?)
  local E = ElvUI[1]
  local D = E:GetModule('Distributor')
  local _, _, data = D:Decode(profileString)
  if not data then return end
  ElvPrivateDB.profileKeys[E.mynameRealm] = profileKey
  data = E:FilterTableFromBlacklist(data, D.blacklistedKeys.private) --Remove unwanted options from import
  ElvPrivateDB.profiles[profileKey] = data
end

---@param profileKey string | nil
---@return string | nil
local exportProfile = function(profileKey)
  if not profileKey then return end
  if not getProfileKeys()[profileKey] then return end
  --Core\General\Distributor.lua
  local E = ElvUI[1]
  local D = E:GetModule('Distributor')
  local _, profileExport = D:GetProfileExport("private", profileKey, "text")
  return profileExport
end

---@param profileStringA string
---@param profileStringB string
---@return boolean
local areProfileStringsEqual = function(profileStringA, profileStringB)
  if not profileStringA or not profileStringB then return false end
  local E = ElvUI[1]
  local D = E:GetModule('Distributor')
  local _, _, profileDataA = D:Decode(profileStringA)
  local _, _, profileDataB = D:Decode(profileStringB)
  if not profileDataA or not profileDataB then return false end
  return private:DeepCompareAsync(profileDataA, profileDataB)
end

---@type LibAddonProfilesModule
local m = {
  moduleName = "ElvUI Private Profile",
  icon = [[Interface\AddOns\ElvUI\Core\Media\Textures\LogoAddon]],
  slash = "/ec",
  needReloadOnImport = true,
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
  refreshHookList = {
    {
      tablePath = { "ElvUI", 1, "Options", "args", "profiles", "args", "private", "handler", "db" },
      functionName = "SetProfile",
    },
    {
      tablePath = { "ElvUI", 1, "Options", "args", "profiles", "args", "private", "handler", "db" },
      functionName = "CopyProfile",
    },
    {
      tablePath = { "ElvUI", 1, "Options", "args", "profiles", "args", "private", "handler", "db" },
      functionName = "DeleteProfile",
    },
  }
}
private.modules[m.moduleName] = m
