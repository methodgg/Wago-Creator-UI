local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Grid2",
  wagoId = "vEGPyeN1",
  oldestSupported = "3.3.12",
  addonNames = { "Grid2", "Grid2Options", "Grid2LDB", "Grid2RaidDebuffs", "Grid2RaidDebuffsOptions" },
  conflictingAddons = { "VuhDo", "VuhDoOptions", "Cell" },
  icon = C_AddOns.GetAddOnMetadata("Grid2", "IconTexture"),
  slash = "/grid2",
  needReloadOnImport = true,
  needProfileKey = true,
  preventRename = false,
  willOverrideProfile = true,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("Grid2")
        and Grid2ProfileAPI ~= nil
        and Grid2 ~= nil
        and Grid2.ExportProfileByKey ~= nil
        and Grid2.ImportProfileIntoKey ~= nil
        and Grid2.UnserializeProfile ~= nil
    return loaded
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return C_AddOns.IsAddOnLoaded("Grid2") and not self:isLoaded()
  end,
  openConfig = function(self)
    vdt("open")
    xpcall(function()
      Grid2ProfileAPI:OpenConfig()
    end, geterrorhandler())
  end,
  closeConfig = function(self)
    vdt("close")
    xpcall(function()
      Grid2ProfileAPI:CloseConfig()
    end, geterrorhandler())
  end,
  getProfileKeys = function(self)
    local profileKeys = {}
    xpcall(function()
      profileKeys = Grid2ProfileAPI:GetProfileKeys()
    end, geterrorhandler())
    return profileKeys
  end,
  getCurrentProfileKey = function(self)
    local profileKey
    xpcall(function()
      profileKey = Grid2ProfileAPI:GetCurrentProfileKey()
    end, geterrorhandler())
    return profileKey
  end,
  getProfileAssignments = function(self)
    local profileAssignments
    xpcall(function()
      profileAssignments = Grid2ProfileAPI:GetProfileAssignments()
    end, geterrorhandler())
    return profileAssignments
  end,
  isDuplicate = function(self, profileKey)
    if not profileKey then return false end
    return self:getProfileKeys()[profileKey] ~= nil
  end,
  setProfile = function(self, profileKey)
    if not profileKey then return end
    if not self:getProfileKeys()[profileKey] then return end
    xpcall(function()
      Grid2ProfileAPI:SetProfile(profileKey)
    end, geterrorhandler())
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)

  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    if type(profileKey) ~= "string" then return end
    xpcall(function()
      Grid2ProfileAPI:ImportProfile(profileString, profileKey)
    end, geterrorhandler())
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local export
    xpcall(function()
      export = Grid2ProfileAPI:ExportProfile(profileKey)
    end, geterrorhandler())
    return export
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    local profileDataA, profileDataB
    xpcall(function()
      profileDataA = Grid2ProfileAPI:DecodeProfileString(profileStringA)
      profileDataB = Grid2ProfileAPI:DecodeProfileString(profileStringB)
    end, geterrorhandler())
    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end,
  refreshHookList = {
    {
      tableFunc = function()
        return Grid2.db
      end,
      functionNames = { "SetProfile", "CopyProfile", "DeleteProfile" }
    }
  }
}

private.modules[m.moduleName] = m
