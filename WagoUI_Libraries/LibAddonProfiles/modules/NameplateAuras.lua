local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

local function findDBObject()
  local aceDB = LibStub("AceDB-3.0")
  for db in pairs(aceDB.db_registry) do
    if db.sv == NameplateAurasAceDB then
      return db
    end
  end
end

---@param profileString string
---@return table | nil
local function decodeProfileString(profileString)
  local LibDeflate = LibStub:GetLibrary("LibDeflateAsync")
  local decoded = LibDeflate:DecodeForPrint(profileString)
  if not decoded then return end
  coroutine.yield()
  local decompressed = LibDeflate:DecompressDeflate(decoded)
  if not decompressed then return end
  coroutine.yield()
  local deserialized = private:LibSerializeDeserializeAsync(decompressed)
  if not deserialized then return end
  coroutine.yield()
  return deserialized
end

---@type LibAddonProfilesModule
local m = {
  moduleName = "NameplateAuras",
  wagoId = "lQNl536e",
  oldestSupported = "110007.0-release",
  addonNames = { "NameplateAuras" },
  icon = C_AddOns.GetAddOnMetadata("NameplateAuras", "IconTexture"),
  slash = "/nauras",
  needReloadOnImport = true,
  needProfileKey = true,
  preventRename = false,
  willOverrideProfile = false,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("NameplateAuras")
    return loaded and true or false
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    if not SlashCmdList["NAMEPLATEAURAS"] then
      return
    end
    SlashCmdList["NAMEPLATEAURAS"]("")
  end,
  closeConfig = function(self)
    if not _G["NAuras.GUIFrame"] then return end
    _G["NAuras.GUIFrame"]:Hide()
  end,
  getProfileKeys = function(self)
    return NameplateAurasAceDB.profiles
  end,
  getCurrentProfileKey = function(self)
    local characterName = UnitName("player").." - "..GetRealmName()
    return NameplateAurasAceDB.profileKeys and NameplateAurasAceDB.profileKeys[characterName]
  end,
  getProfileAssignments = function(self)
    return NameplateAurasAceDB.profileKeys
  end,
  isDuplicate = function(self, profileKey)
    if not profileKey then
      return false
    end
    return self:getProfileKeys()[profileKey] ~= nil
  end,
  setProfile = function(self, profileKey)
    if not profileKey then return end
    if not self:getProfileKeys()[profileKey] then return end
    findDBObject():SetProfile(profileKey)
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    if not profileString then return end
    local pData = decodeProfileString(profileString)
    if not pData then return end
    if not pData.CustomSpells2 or not pData.DBVersion or not pData.IconGroups then return end
    return profileKey
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    local pData = decodeProfileString(profileString)
    if not pData then return end
    NameplateAurasAceDB.profiles[profileKey] = pData
    NameplateAurasAceDB.profileKeys[UnitName("player").." - "..GetRealmName()] = profileKey
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local data = NameplateAurasAceDB.profiles[profileKey]
    local LibDeflate = LibStub:GetLibrary("LibDeflateAsync")
    local serialized = private:LibSerializeSerializeAsyncEx(nil, data)
    local compressed = LibDeflate:CompressDeflate(serialized, { level = 5 })
    local encoded = LibDeflate:EncodeForPrint(compressed);
    return encoded
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    local profileDataA = decodeProfileString(profileStringA)
    local profileDataB = decodeProfileString(profileStringB)
    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end,
  refreshHookList = {
    {
      tableFunc = function()
        return findDBObject()
      end,
      functionNames = { "SetProfile", "DeleteProfile" }
    },
  }
}

private.modules[m.moduleName] = m
