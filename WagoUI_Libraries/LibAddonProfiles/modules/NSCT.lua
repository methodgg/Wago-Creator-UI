local _, loadingAddonNamespace = ...;
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal();
if (not private) then return; end

---@type LibAddonProfilesModule
local m = {
  moduleName = "NameplateSCT",
  icon = 4548873,
  slash = "/nsct",
  needReloadOnImport = true,
  needProfileKey = false,
  preventRename = true,
  willOverrideProfile = true,
  nonNativeProfileString = true,

  isLoaded = function(self)
    return NameplateSCTDB and true or false
  end,

  needsInitialization = function(self)
    return false
  end,

  openConfig = function(self)
    SlashCmdList["ACECONSOLE_NSCT"]()
  end,

  closeConfig = function(self)
    SettingsPanel:Hide()
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
    if not profileKey then return false end
    return true
  end,

  setProfile = function(self, profileKey)

  end,

  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    if not profileString then return end
    if profileData and profileData.NSCTGlobal then
      return profileKey
    end
  end,

  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    local _, pData = private:GenericDecode(profileString)
    if not pData then return end
    NameplateSCTDB.global = pData.NSCTGlobal
  end,

  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local data = {
      NSCTGlobal = NameplateSCTDB.global
    }
    return private:GenericEncode(profileKey, data, self.moduleName)
  end,

  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then return false end
    local _, profileDataA = private:GenericDecode(profileStringA)
    local _, profileDataB = private:GenericDecode(profileStringB)
    if not profileDataA or not profileDataB then return false end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end,

}

private.modules[m.moduleName] = m
