local _, loadingAddonNamespace = ...;
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal();
if (not private) then return; end
local EXPORT_PREFIX = '!E1!'

---@return boolean
local isLoaded = function()
  return ElvUI and true or false
end

---@return boolean
local needsInitialization = function()
  return false
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
  return ElvDB.profiles
end

---@return string
local getCurrentProfileKey = function()
  local E = unpack(ElvUI)
  return ElvDB.profileKeys and ElvDB.profileKeys[E.mynameRealm]
end

---@param profileKey string
local setProfile = function(profileKey)
  local E = unpack(ElvUI)
  E.data:SetProfile(profileKey)
end

---@param profileKey string
---@return boolean
local isDuplicate = function(profileKey)
  return getProfileKeys()[profileKey]
end

---@param profileString string
---@param profileKey string | nil
---@param profileData table | nil
---@param rawData table | nil
---@return string | nil
local testImport = function(profileString, profileKey, profileData, rawData)
  local prefix = strsub(profileString, 1, 4)
  if prefix ~= EXPORT_PREFIX then return nil end
  local distributor = ElvUI[1]:GetModule("Distributor");
  local profileType, key, data = distributor:Decode(profileString)
  if key and data and profileType == "profile" then
    return key
  end
end

---@param profileString string
---@param profileKey string
---@param isDuplicateProfile boolean
local importProfile = function(profileString, profileKey, isDuplicateProfile)
  local E = ElvUI[1]
  local D = E:GetModule('Distributor')
  local _, _, data = D:Decode(profileString)
  if not data then return end
  data = E:FilterTableFromBlacklist(data, D.blacklistedKeys.profile)
  if not ElvDB.profiles[profileKey] then
    if E.data.keys.profile == profileKey then
      E.data.keys.profile = profileKey..'_Temp'
    end
    ElvDB.profiles[profileKey] = data
    E.data:SetProfile(profileKey)
  end
end

---@param profileKey string | nil
---@return string | nil
local exportProfile = function(profileKey)
  local LibDeflate = LibStub:GetLibrary("LibDeflateAsync");
  --Core\General\Distributor.lua
  if not profileKey then return nil end
  local E, L, V, P, G = unpack(ElvUI)
  local D = E:GetModule('Distributor')
  local profileType = "profile"
  local profileData = {}
  profileData = E:CopyTable(profileData, ElvDB.profiles[profileKey])
  coroutine.yield()
  profileData = E:RemoveTableDuplicates(profileData, P, D.GeneratedKeys.profile)
  coroutine.yield()
  profileData = E:FilterTableFromBlacklist(profileData, D.blacklistedKeys.profile)
  coroutine.yield()
  local serialData = D:Serialize(profileData)
  coroutine.yield()
  local exportString = D:CreateProfileExport(serialData, profileType, profileKey)
  coroutine.yield()
  local compressedData = LibDeflate:CompressDeflate(exportString, { level = 5 })
  coroutine.yield()
  local printableString = LibDeflate:EncodeForPrint(compressedData)
  coroutine.yield()
  local profileExport = printableString and format('%s%s', EXPORT_PREFIX, printableString) or nil
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
  moduleName = "ElvUI",
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
}
private.modules[m.moduleName] = m
