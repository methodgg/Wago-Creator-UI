local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end
local EXPORT_PREFIX = "!E1!"

---@type LibAddonProfilesModule
local m = {
  moduleName = "ElvUI Private Profile",
  oldestSupported = "v13.76",
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
    SlashCmdList["ACECONSOLE_ELVUI"]()
  end,
  closeConfig = function(self)
    local E = unpack(ElvUI)
    E.Config_CloseWindow()
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
    local distributor = ElvUI[1]:GetModule("Distributor")
    local profileType, _, data = distributor:Decode(profileString)
    if profileType == "private" and data then
      return ""
    end
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    -- TODO: do we even want to change this to use D:ImportProfile?
    -- seems simple enough as it is and sets the profile key (maybe this is not wanted?)
    local E = ElvUI[1]
    local D = E:GetModule("Distributor")
    local _, _, data = D:Decode(profileString)
    if not data then
      return
    end
    ElvPrivateDB.profileKeys[E.mynameRealm] = profileKey
    data = E:FilterTableFromBlacklist(data, D.blacklistedKeys.private) --Remove unwanted options from import
    ElvPrivateDB.profiles[profileKey] = data
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    --Core\General\Distributor.lua
    local E, L, V, P, G = unpack(ElvUI)
    local D = E:GetModule("Distributor")

    local profileData = {}
    profileData = E:CopyTable(profileData, ElvPrivateDB.profiles[profileKey])
    profileData = E:RemoveTableDuplicates(profileData, V, D.GeneratedKeys.private)
    profileData = E:FilterTableFromBlacklist(profileData, D.blacklistedKeys.private)
    if not profileData or (profileData and type(profileData) ~= 'table') then return end

    local profileExport
    local serialString = D:Serialize(profileData)
    local exportString = D:CreateProfileExport('private', profileKey, serialString)
    local LibDeflate = LibStub:GetLibrary("LibDeflateAsync")
    local compressedData = LibDeflate:CompressDeflate(exportString, { level = 5 })
    local printableString = LibDeflate:EncodeForPrint(compressedData)
    profileExport = printableString and format('%s%s', EXPORT_PREFIX, printableString) or nil

    return profileExport
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    local E = ElvUI[1]
    local D = E:GetModule("Distributor")
    local _, _, profileDataA = D:Decode(profileStringA)
    local _, _, profileDataB = D:Decode(profileStringB)
    if not profileDataA or not profileDataB then
      return false
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
