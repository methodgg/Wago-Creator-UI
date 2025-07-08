local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "HidingBar",
  wagoId = "LvNAJE6o",
  oldestSupported = "v11.0.12",
  addonNames = { "HidingBar", "HidingBar_Options" },
  icon = C_AddOns.GetAddOnMetadata("HidingBar", "IconTexture"),
  slash = "/hidingbar",
  needReloadOnImport = false,
  needProfileKey = true,
  preventRename = false,
  willOverrideProfile = false,
  nonNativeProfileString = true,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("HidingBar") and HidingBarConfigAddon -- config addon is lod
    return loaded and true or false
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return HidingBarConfigAddon and not HidingBarConfigAddon.setProfile
  end,
  openConfig = function(self)
    if not HidingBarConfigAddon.openConfig then
      return
    end
    HidingBarConfigAddon.openConfig()
  end,
  closeConfig = function(self)
    SettingsPanel:Hide()
  end,
  getProfileKeys = function(self)
    local keys = {}
    for _, profile in pairs(HidingBarDB.profiles) do
      keys[profile.name] = true
    end
    return keys
  end,
  getCurrentProfileKey = function(self)
    return HidingBarDBChar.currentProfileName
  end,
  getProfileAssignments = function(self)
    return nil
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
    xpcall(function()
      HidingBarAddon:setProfile(profileKey)
      HidingBarConfigAddon:hidingBarUpdate()
    end, geterrorhandler())
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    if not profileString then return end
    local _, pData = private:GenericDecode(profileString)
    if not pData then return end
    if not pData.bars or not pData.name or not pData.config then return end
    return profileKey
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    local _, pData = private:GenericDecode(profileString)
    if not pData then return end
    --need to inject new profileKey here due to the structure of the profiles
    pData.name = profileKey
    -- check if profile with same name exists and remove it
    for i, profile in pairs(HidingBarDB.profiles) do
      if profile.name == profileKey then
        table.remove(HidingBarDB.profiles, i)
        break
      end
    end
    -- add new profile
    table.insert(HidingBarDB.profiles, pData)
    HidingBarDBChar.currentProfileName = profileKey
    self:setProfile(profileKey)
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    for _, currentProfile in pairs(HidingBarDB.profiles) do
      if currentProfile.name == profileKey then
        return private:GenericEncode(profileKey, currentProfile, self.moduleName)
      end
    end
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
    -- there are some timestamps stored in the profile for some reason, ignore them
    return private:DeepCompareAsync(profileDataA, profileDataB, { ["tstmp"] = true })
  end,
  refreshHookList = {
    {
      tableFunc = function()
        return HidingBarAddon
      end,
      functionNames = { "setProfile" }
    },
    {
      tableFunc = function()
        return HidingBarConfigAddon
      end,
      functionNames = { "setProfile", "removeProfile" }
    },
  }
}

private.modules[m.moduleName] = m
