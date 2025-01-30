local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "WarpDeplete",
  wagoId = "5bGoOqG0",
  oldestSupported = "3.0.6",
  addonNames = { "WarpDeplete" },
  icon = C_AddOns.GetAddOnMetadata("WarpDeplete", "IconTexture"),
  slash = "/exampleslash",
  needReloadOnImport = false,
  needProfileKey = true,
  preventRename = false,
  willOverrideProfile = false,
  nonNativeProfileString = true,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("WarpDeplete")
    return loaded
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    if not SlashCmdList["ACECONSOLE_WARPDEPLETE"] then return end
    SlashCmdList["ACECONSOLE_WARPDEPLETE"]("")
  end,
  closeConfig = function(self)
    SettingsPanel:Hide()
  end,
  getProfileKeys = function(self)
    return WarpDeplete.db.profiles
  end,
  getCurrentProfileKey = function(self)
    return WarpDeplete.db:GetCurrentProfile()
  end,
  getProfileAssignments = function(self)
    return WarpDeplete.db.sv.profileKeys
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
    WarpDeplete.db:SetProfile(profileKey)
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    if not profileString then return end
    if not profileData then
      profileKey, profileData, rawData, moduleName = private:GenericDecode(profileString)
    end
    if not profileData then return end
    if not moduleName or moduleName ~= self.moduleName then return end
    return profileKey
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    local decodedKey, profileData, rawData, moduleName = private:GenericDecode(profileString)
    if not profileData then return end
    if not moduleName or moduleName ~= self.moduleName then return end
    profileKey = profileKey or decodedKey
    if not profileKey then return end
    WarpDeplete.db.profiles[profileKey] = profileData
    self:setProfile(profileKey)
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local profileData = WarpDeplete.db.profiles[profileKey]
    if not profileData then return end
    local encoded = private:GenericEncode(profileKey, profileData, self.moduleName)
    return encoded
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
        return WarpDeplete.db
      end,
      functionNames = { "SetProfile", "DeleteProfile" }
    }
  }
}

private.modules[m.moduleName] = m
