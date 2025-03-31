local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@param profileString string
---@return table | nil
local function decodeProfileString(profileString)
  local LibDeflate = LibStub:GetLibrary("LibDeflateAsync")
  local version, dataString = string.match(profileString, "^!CELL:(%d+):ALL!(.+)$")
  version = tonumber(version)
  if version < Cell.MIN_VERSION or version > Cell.versionNum then
    return
  end
  local decoded = LibDeflate:DecodeForPrint(dataString)
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
  moduleName = "Cell",
  wagoId = "qv63LLKb",
  oldestSupported = "r244-release",
  addonNames = { "Cell" },
  conflictingAddons = { "VuhDo", "VuhDoOptions", "Grid2" },
  icon = C_AddOns.GetAddOnMetadata("Cell", "IconTexture"),
  slash = "/cell opt",
  needReloadOnImport = true,
  needProfileKey = false,
  preventRename = true,
  willOverrideProfile = true,
  nonNativeProfileString = true,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("Cell")
    return loaded
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    if not Cell then return end
    Cell.funcs:ShowOptionsFrame()
  end,
  closeConfig = function(self)
    -- it's a toggle
    Cell.funcs:ShowOptionsFrame()
  end,
  getProfileKeys = function(self)
    return {
      ["Global"] = true
    }
  end,
  getCurrentProfileKey = function(self)
    return "Global"
  end,
  isDuplicate = function(self, profileKey)
    return true
  end,
  setProfile = function(self, profileKey)
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    if not profileString then return end
    local decodedProfileData = decodeProfileString(profileString)
    if not decodedProfileData then return end
    return "global"
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    xpcall(function()
      ---profileString string, profileName string?, ignoredIndicesExternal table<string, boolean>?
      Cell.ImportProfile(profileString, profileKey, { ["nicknames"] = true, ["clickCastings"] = true })
    end, geterrorhandler())
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    -- Cell\Modules\About_ImportExport.lua
    local LibDeflate = LibStub:GetLibrary("LibDeflateAsync")
    local prefix = "!CELL:"..Cell.versionNum..":ALL!"
    local db = private:DeepCopyAsync(CellDB)
    db["nicknames"] = nil
    -- possible on Classic only, ignore for now
    -- if includeCharacter then
    --     db["characterDB"] = F:Copy(CellCharacterDB)
    -- end
    local serialized = private:LibSerializeSerializeAsyncEx(nil, db)
    coroutine.yield()
    local compressed = LibDeflate:CompressDeflate(serialized, { level = 5 })
    coroutine.yield()
    local encoded = LibDeflate:EncodeForPrint(compressed)
    coroutine.yield()
    return prefix..encoded
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
  end
}
private.modules[m.moduleName] = m
