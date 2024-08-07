local _, loadingAddonNamespace = ...;
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal();
if (not private) then return; end

---@type LibAddonProfilesModule
local m = {
  moduleName = "OmniCD",
  icon = [[Interface\AddOns\OmniCD\Config\Libs\Media\omnicd-logo64-c]],
  slash = "/omnicd",
  needReloadOnImport = false,
  needProfileKey = true,
  preventRename = false,
  willOverrideProfile = false,
  nonNativeProfileString = false,

  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("OmniCD")
    return loaded
  end,

  needsInitialization = function(self)
    return false
  end,

  openConfig = function(self)
    OmniCD[1]:OpenOptionPanel()
  end,

  closeConfig = function(self)
    -- missing but not needed for this module for now
  end,

  getProfileKeys = function(self)
    return OmniCDDB.profiles
  end,

  getCurrentProfileKey = function(self)
    local characterName = UnitName("player").." - "..GetRealmName()
    return OmniCDDB.profileKeys and OmniCDDB.profileKeys[characterName]
  end,

  isDuplicate = function(self, profileKey)
    if not profileKey then return false end
    return self:getProfileKeys()[profileKey] ~= nil
  end,

  setProfile = function(self, profileKey)
    if not profileKey then return end
    if not self:getProfileKeys()[profileKey] then return end
    OmniCD[1].DB:SetProfile(profileKey)
  end,

  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    if not profileString then return end
    local E = OmniCD[1]
    local PS = E.ProfileSharing
    -- pretty basic test, this is what the addon does and seems quite insecure but oh well
    local profileType, decodedProfileKey, decoded = PS:Decode(profileString)
    if not profileType or profileType ~= "all" then return end
    if not decodedProfileKey or not decoded then return end
    return decodedProfileKey
  end,

  importProfile = function(self, profileString, profileKey, fromIntro)
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
  end,

  exportProfile = function(self, profileKey)
    if not profileKey then return nil end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
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
  end,

  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then return false end
    local E = OmniCD[1]
    local PS = E.ProfileSharing
    local profileTypeA, decodedProfileKeyA, profileDataA = PS:Decode(profileStringA)
    local profileTypeB, decodedProfileKeyB, profileDataB = PS:Decode(profileStringB)
    if not profileDataA or not profileDataB then return false end
    if not profileTypeA == profileTypeB then return false end
    if not decodedProfileKeyA == decodedProfileKeyB then return false end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end,

  refreshHookList = {
    {
      tableFunc = function()
        return OmniCD[1].DB
      end,
      functionNames = { "SetProfile", "DeleteProfile" }
    },
  }
}

private.modules[m.moduleName] = m
