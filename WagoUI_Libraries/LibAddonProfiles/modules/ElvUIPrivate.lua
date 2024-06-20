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
  return ElvPrivateDB.profiles
end

---@return string
local getCurrentProfileKey = function()
  local E = unpack(ElvUI)
  return ElvPrivateDB.profileKeys and ElvPrivateDB.profileKeys[E.mynameRealm]
end

---@param profileKey string
local setProfile = function(profileKey)
  local E = unpack(ElvUI)
  ElvPrivateDB.profileKeys[E.mynameRealm] = profileKey
end

---@param profileKey string
---@return boolean
local isDuplicate = function(profileKey)
  return ElvPrivateDB.profiles[profileKey] and true or false
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
  local profileType, _, data = distributor:Decode(profileString)
  if profileType == "private" and data then
    return ""
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
  ElvPrivateDB.profileKeys[E.mynameRealm] = profileKey
  data = E:FilterTableFromBlacklist(data, D.blacklistedKeys.private) --Remove unwanted options from import
  ElvPrivateDB.profiles[profileKey] = data
end

---@param profileKey string | nil
---@return string | nil
local exportProfile = function(profileKey)
  local LibDeflate = LibStub:GetLibrary("LibDeflateAsync");
  --Core\General\Distributor.lua
  if not profileKey then return nil end
  local E, _, V = unpack(ElvUI)
  local D = E:GetModule('Distributor')
  local profileType = "private"
  local profileData = {}
  profileData = E:CopyTable(profileData, ElvPrivateDB.profiles[profileKey])
  coroutine.yield()
  profileData = E:RemoveTableDuplicates(profileData, V, D.GeneratedKeys.private)
  coroutine.yield()
  profileData = E:FilterTableFromBlacklist(profileData, D.blacklistedKeys.private)
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
}
private.modules[m.moduleName] = m
