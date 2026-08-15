local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end
local EXPORT_PREFIX = "!E2!"

---@type LibAddonProfilesModule
local m = {
  moduleName = "ElvUI Private Profile",
  oldestSupported = "v15.19",
  addonNames = { "ElvUI", "ElvUI_Libraries", "ElvUI_Options" },
  icon = C_AddOns.GetAddOnMetadata("ElvUI", "IconTexture"),
  slash = "/ec",
  needReloadOnImport = true,
  needProfileKey = false,
  preventRename = false,
  willOverrideProfile = false,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    return ElvUI and ElvUI[1].Options.args.profiles and true or false
  end,
  isUpdated = function(self)
    local currentVersionString = private:GetAddonVersionCached(self.addonNames[1])
    if not currentVersionString then
      return false
    end
    if strfind(currentVersionString, "project%-version") then
      return true
    end
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return C_AddOns.IsAddOnLoaded("ElvUI") and not self:isLoaded()
  end,
  openConfig = function(self)
    if not SlashCmdList["ACECONSOLE_ELVUI"] then return end
    xpcall(function()
      SlashCmdList["ACECONSOLE_ELVUI"]()
    end, geterrorhandler())
  end,
  closeConfig = function(self)
    xpcall(function()
      local E = unpack(ElvUI)
      E.Config_CloseWindow()
    end, geterrorhandler())
  end,
  getProfileKeys = function(self)
    return ElvPrivateDB.profiles
  end,
  getCurrentProfileKey = function(self)
    local E = unpack(ElvUI)
    return ElvPrivateDB.profileKeys and ElvPrivateDB.profileKeys[E.mynameRealm]
  end,
  getProfileAssignments = function(self)
    return ElvPrivateDB.profileKeys
  end,
  isDuplicate = function(self, profileKey)
    if not profileKey then
      return false
    end
    return ElvPrivateDB.profiles[profileKey] and true or false
  end,
  setProfile = function(self, profileKey)
    if not profileKey then return end
    if not self:getProfileKeys()[profileKey] then return end
    local E = unpack(ElvUI)
    ElvPrivateDB.profileKeys[E.mynameRealm] = profileKey
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    if not profileString then return end
    local prefix = strsub(profileString, 1, 4)
    if prefix ~= EXPORT_PREFIX then
      return nil
    end
    local profileType, data
    local success = xpcall(function()
      local distributor = ElvUI[1]:GetModule("Distributor")
      profileType, _, data = distributor:Decode(profileString)
    end, geterrorhandler())
    if not success then return end
    if profileType == "private" and data then
      return ""
    end
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    -- TODO: do we even want to change this to use D:ImportProfile?
    -- seems simple enough as it is and sets the profile key (maybe this is not wanted?)
    local E, data
    local success = xpcall(function()
      E = ElvUI[1]
      local D = E:GetModule("Distributor")
      _, _, data = D:Decode(profileString)
      if not data then return end
      data = E:FilterTableFromBlacklist(data, D.blacklistedKeys.private) --Remove unwanted options from import
    end, geterrorhandler())
    if not success or not data then return end
    ElvPrivateDB.profileKeys[E.mynameRealm] = profileKey
    ElvPrivateDB.profiles[profileKey] = data
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local printableString
    local success = xpcall(function()
      --Core\General\Distributor.lua
      local E, _, V = unpack(ElvUI)
      local D = E:GetModule("Distributor")
      local profileData = E:CopyTable({}, ElvPrivateDB.profiles[profileKey])
      profileData = E:RemoveTableDuplicates(profileData, V, D.GeneratedKeys.private)
      profileData = E:FilterTableFromBlacklist(profileData, D.blacklistedKeys.private)
      if type(profileData) ~= "table" then return end

      local serialString = C_EncodingUtil.SerializeCBOR(profileData)
      local exportString = D:CreateProfileExport("private", profileKey, serialString)
      local compressedData = C_EncodingUtil.CompressString(exportString, Enum.CompressionMethod.Deflate or 0, Enum.CompressionLevel.Default or 0)
      printableString = C_EncodingUtil.EncodeBase64(compressedData)
    end, geterrorhandler())
    if not success or not printableString then return nil, false end
    return format("%s%s", EXPORT_PREFIX, printableString), true
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    local profileDataA, profileDataB
    local success = xpcall(function()
      local E = ElvUI[1]
      local D = E:GetModule("Distributor")
      _, _, profileDataA = D:Decode(profileStringA)
      _, _, profileDataB = D:Decode(profileStringB)
    end, geterrorhandler())
    if not success or not profileDataA or not profileDataB then
      return nil, nil, nil, false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end,
  refreshHookList = {
    {
      tableFunc = function()
        return ElvUI[1].Options.args.profiles.args.private.handler.db
      end,
      functionNames = { "SetProfile", "CopyProfile", "DeleteProfile" }
    }
  }
}

private.modules[m.moduleName] = m
