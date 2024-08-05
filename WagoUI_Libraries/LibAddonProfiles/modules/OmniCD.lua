local _, loadingAddonNamespace = ...;
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal();
if (not private) then return; end

---@return boolean
local isLoaded = function()
  local loaded = C_AddOns.IsAddOnLoaded("OmniCD")
  return loaded
end

---@return boolean
local needsInitialization = function()
  return false
end

---@return nil
local openConfig = function()
  OmniCD[1]:OpenOptionPanel()
end

---@return nil
local closeConfig = function()
  -- missing but not needed for this module for now
end

---@return table<string, any>
local getProfileKeys = function()
  return OmniCDDB.profiles
end

---@return string
local getCurrentProfileKey = function()
  local characterName = UnitName("player").." - "..GetRealmName()
  return OmniCDDB.profileKeys and OmniCDDB.profileKeys[characterName]
end

---@param profileKey string
local setProfile = function(profileKey)
  if not profileKey then return end
  if not getProfileKeys()[profileKey] then return end
  OmniCD[1].DB:SetProfile(profileKey)
end

---@param profileKey string
---@return boolean
local isDuplicate = function(profileKey)
  if not profileKey then return false end
  return getProfileKeys()[profileKey]
end

---@param profileString string
---@param profileKey string | nil
---@param profileData table | nil
---@param rawData table | nil
---@return string | nil
local testImport = function(profileString, profileKey, profileData, rawData)
  if not profileString then return end
  local E = OmniCD[1]
  local PS = E.ProfileSharing
  -- pretty basic test, this is what the addon does and seems quite insecure but oh well
  local profileType, decodedProfileKey, decoded = PS:Decode(profileString)
  if not profileType or profileType ~= "all" then return end
  if not decodedProfileKey or not decoded then return end
  return decodedProfileKey
end

---@param profileString string
---@param profileKey string
local importProfile = function(profileString, profileKey, fromIntro)
  if not profileString then return end
  local E = OmniCD[1]
  local PS = E.ProfileSharing
  local profileType, decodedProfileKey, profileData = PS:Decode(profileString)
  if not profileData then return end
  local prefix = "[IMPORT-%s]%s"
  local n = 1
  local key
  while true do
    key = format(prefix, n, decodedProfileKey)
    if not OmniCDDB.profiles[key] then
      decodedProfileKey = key
      break
    end
    n = n + 1
  end
  E.ProfileSharing:CopyProfile(profileType, decodedProfileKey, profileData)
end

---@param profileKey string | nil
---@return string | nil
local exportProfile = function(profileKey)
  if not profileKey then return nil end
  if not getProfileKeys()[profileKey] then return end
  -- OmniCD\Core\ProfileSharing.lua
  local LibDeflate = LibStub:GetLibrary("LibDeflateAsync")
  local E = OmniCD[1]
  local C = OmniCD[3]
  local PS = E.ProfileSharing
  local PS_VERSION = "OmniCD2"
  local blackList = {
    modules = true,
  }
  local profileType = "all"
  local profileData
  profileData = E:DeepCopy(OmniCDDB.profiles[profileKey], blackList)
  profileData = E:RemoveEmptyDuplicateTables(profileData, C)
  if not profileData then return end
  if next(profileData) == nil then return end
  local serializedData = PS:Serialize(profileData)
  if type(serializedData) ~= "string" then return end
  local embeddedProfileKey = gsub(profileKey, "^%[IMPORT.-%]", "")
  serializedData = format("%s%s%s,%s", serializedData, PS_VERSION, profileType, embeddedProfileKey)
  local compressedData = LibDeflate:CompressDeflate(serializedData, { level = 5 })
  local encodedData = LibDeflate:EncodeForPrint(compressedData)
  return encodedData
end

---@param profileStringA string
---@param profileStringB string
---@return boolean
local areProfileStringsEqual = function(profileStringA, profileStringB)
  if not profileStringA or not profileStringB then return false end
  local E = OmniCD[1]
  local PS = E.ProfileSharing
  local profileTypeA, decodedProfileKeyA, profileDataA = PS:Decode(profileStringA)
  local profileTypeB, decodedProfileKeyB, profileDataB = PS:Decode(profileStringB)
  if not profileDataA or not profileDataB then return false end
  if not profileTypeA == profileTypeB then return false end
  if not decodedProfileKeyA == decodedProfileKeyB then return false end
  return private:DeepCompareAsync(profileDataA, profileDataB)
end

---@type LibAddonProfilesModule
local m = {
  moduleName = "OmniCD",
  icon = [[Interface\AddOns\OmniCD\Config\Libs\Media\omnicd-logo64-c]],
  slash = "/omnicd",
  needReloadOnImport = false, --optional
  needProfileKey = true,      --optional
  preventRename = false,      --optional
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
      tablePath = { "OmniCD", 1, "DB" },
      functionName = "SetProfile",
    },
    {
      tablePath = { "OmniCD", 1, "DB" },
      functionName = "DeleteProfile",
    },
  }
}
private.modules[m.moduleName] = m
