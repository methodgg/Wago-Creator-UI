local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "ShadowedUnitFrames",
  wagoId = "none",
  oldestSupported = "v4.4.11",
  addonNames = { "ShadowedUnitFrames", "ShadowedUF_Options" },
  conflictingAddons = { "ElvUI", "ElvUI_Libraries", "ElvUI_Options", "PitBull4" },
  icon = C_AddOns.GetAddOnMetadata("ShadowedUnitFrames", "IconTexture"),
  slash = "/suf",
  needReloadOnImport = false,
  needProfileKey = false,
  preventRename = false,
  willOverrideProfile = false,
  nonNativeProfileString = true,
  needSpecialInterface = false,
  isLoaded = function(self)
    return ShadowUF and true or false
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    if not SlashCmdList["SHADOWEDUF"] then return end
    SlashCmdList["SHADOWEDUF"]("")
  end,
  closeConfig = function(self)
    LibStub("AceConfigDialog-3.0"):Close("ShadowedUF")
  end,
  getProfileKeys = function(self)
    return ShadowedUFDB.profiles
  end,
  getCurrentProfileKey = function(self)
    local characterName = UnitName("player").." - "..GetRealmName()
    return ShadowedUFDB.profileKeys and ShadowedUFDB.profileKeys[characterName]
  end,
  getProfileAssignments = function(self)
    return ShadowedUFDB.profileKeys
  end,
  isDuplicate = function(self, profileKey)
    if not profileKey then
      return false
    end
    return ShadowUF.db.profiles[profileKey]
  end,
  setProfile = function(self, profileKey)
    if not profileKey then return end
    if not self:getProfileKeys()[profileKey] then return end
    ShadowUF.db:SetProfile(profileKey)
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    if not profileString then return end
    -- dont accept normal SUF exports as they are insecure
    if profileData and profileData.auraColors and profileData.auraIndicators and profileData.visibility and profileData.wowBuild then
      return profileKey
    end
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    local _, pData = private:GenericDecode(profileString)
    if not pData then return end
    -- if this errors internally do not take the blame
    xpcall(function()
      ShadowUF.db:SetProfile(profileKey)
      ShadowUF:LoadDefaultLayout()
    end, geterrorhandler())
    for key, data in pairs(pData) do
      if (type(data) == "table") then
        ShadowUF.db.profile[key] = CopyTable(data)
      else
        ShadowUF.db.profile[key] = data
      end
    end
    xpcall(function()
      ShadowUF:ProfilesChanged()
    end, geterrorhandler())
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    return private:GenericEncode(profileKey, ShadowedUFDB.profiles[profileKey], self.moduleName)
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    local _, profileDataA = private:GenericDecode(profileStringA)
    local _, profileDataB = private:GenericDecode(profileStringB)
    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end,
  refreshHookList = {
    {
      tableFunc = function()
        return ShadowUF.db
      end,
      functionNames = { "SetProfile", "CopyProfile", "DeleteProfile" }
    }
  }
}

private.modules[m.moduleName] = m
