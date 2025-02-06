local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "OmniBar",
  wagoId = "BO678XK3",
  oldestSupported = "v27",
  addonNames = { "OmniBar" },
  icon = C_AddOns.GetAddOnMetadata("OmniBar", "IconTexture"),
  slash = "/omnibar",
  needReloadOnImport = false,
  needProfileKey = true,
  preventRename = false,
  willOverrideProfile = false,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("OmniBar")
    return (loaded and OmniBarDB) and true or false
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    if not SlashCmdList["OmniBar"] then
      return
    end
    SlashCmdList["OmniBar"]()
  end,
  closeConfig = function(self)
    SettingsPanel:Hide()
  end,
  getProfileKeys = function(self)
    return OmniBarDB.profiles
  end,
  getCurrentProfileKey = function(self)
    local characterName = UnitName("player").." - "..GetRealmName()
    return OmniBarDB.profileKeys and OmniBarDB.profileKeys[characterName]
  end,
  getProfileAssignments = function(self)
    return OmniBarDB.profileKeys
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
    ---@diagnostic disable-next-line: undefined-field
    LibStub("AceAddon-3.0"):GetAddon("OmniBar").db:SetProfile(profileKey)
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    if not profileString then return end
    local data = OmniBar:Decode(profileString)
    if data.profile and data.version and data.version == 1 and data.customSpells then
      return profileKey
    end
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    local data = OmniBar:Decode(profileString)
    if not (data.profile and data.version and data.version == 1 and data.customSpells) then
      return
    end
    -- OmniBar:ImportProfile
    OmniBar.db.profiles[profileKey] = data.profile
    OmniBar.db:SetProfile(profileKey)
    for k, v in pairs(data.customSpells) do
      OmniBar.db.global.cooldowns[k] = nil
      OmniBar.options.args.customSpells.args.spellId.set(nil, k, v)
    end
    OmniBar:OnEnable()
    LibStub("AceConfigRegistry-3.0"):NotifyChange("OmniBar")
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local LibDeflate = LibStub:GetLibrary("LibDeflateAsync")
    local data = {
      profile = OmniBarDB.profiles[profileKey],
      customSpells = OmniBarDB.global.cooldowns,
      version = 1
    }
    local serialized = OmniBar:Serialize(data)
    if (not serialized) then return end
    local compressed = LibDeflate:CompressZlib(serialized)
    if (not compressed) then return end
    return LibDeflate:EncodeForPrint(compressed)
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    local profileDataA = OmniBar:Decode(profileStringA)
    local profileDataB = OmniBar:Decode(profileStringB)
    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end,
  refreshHookList = {
    {
      tableFunc = function()
        ---@diagnostic disable-next-line: undefined-field
        return LibStub("AceAddon-3.0"):GetAddon("OmniBar").db
      end,
      functionNames = { "SetProfile", "DeleteProfile" }
    }
  }
}

private.modules[m.moduleName] = m
