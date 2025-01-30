local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end
local EXPORT_PREFIX = "!E1!"

---@type LibAddonProfilesModule
local m = {
  moduleName = "ElvUI",
  wagoId = "tukui--2",
  oldestSupported = "v13.76",
  addonNames = { "ElvUI", "ElvUI_Libraries", "ElvUI_Options" },
  conflictingAddons = { "Bartender4", "ShadowedUnitFrames", "ShadowedUF_Options", "PitBull4" },
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
    if not currentVersionString then return false end
    if strfind(currentVersionString, "project%-version") then return true end
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
    local E = ElvUI[1]
    E.Config_CloseWindow()
  end,
  getProfileKeys = function(self)
    return ElvDB.profiles
  end,
  getCurrentProfileKey = function(self)
    local E = ElvUI[1]
    return ElvDB.profileKeys and ElvDB.profileKeys[E.mynameRealm]
  end,
  getProfileAssignments = function(self)
    return ElvDB.profileKeys
  end,
  isDuplicate = function(self, profileKey)
    if not profileKey then return false end
    return self:getProfileKeys()[profileKey] ~= nil
  end,
  setProfile = function(self, profileKey)
    if not profileKey then return end
    if not self:getProfileKeys()[profileKey] then return end
    local E = ElvUI[1]
    E.data:SetProfile(profileKey)
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    if not profileString then return end
    local prefix = strsub(profileString, 1, 4)
    if prefix ~= EXPORT_PREFIX then return nil end
    local distributor = ElvUI[1]:GetModule("Distributor")
    local profileType, key, data = distributor:Decode(profileString)
    if key and data and profileType == "profile" then
      return key
    end
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    local E = ElvUI[1]
    local D = E:GetModule("Distributor")
    local decodedType, decodedKey, decodedData = D:Decode(profileString)
    -- important to use the supplied profileKey, as the decodedKey might be different
    local force = true
    D:SetImportedProfile(decodedType, profileKey, decodedData, force)
    if fromIntro then
      E.global.general.UIScale = E:PixelBestSize()
      E:PixelScaleChanged()
    end
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    --Core\General\Distributor.lua
    local E = ElvUI[1]
    local D = E:GetModule("Distributor")
    local _, profileExport = D:GetProfileExport("profile", profileKey, "text")
    return profileExport
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then return false end
    local E = ElvUI[1]
    local D = E:GetModule("Distributor")
    local _, _, profileDataA = D:Decode(profileStringA)
    local _, _, profileDataB = D:Decode(profileStringB)
    if not profileDataA or not profileDataB then return false end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end,
  refreshHookList = {
    {
      tableFunc = function()
        return ElvUI[1].Options.args.profiles.args.profile.handler.db
      end,
      functionNames = { "SetProfile", "CopyProfile", "DeleteProfile" }
    }
  }
}

private.modules[m.moduleName] = m
