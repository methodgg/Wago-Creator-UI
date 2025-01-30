local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "BugSack",
  wagoId = "rkGrrgGy",
  oldestSupported = "v11.0.0",
  addonNames = { "BugSack", "BugGrabber" },
  icon = C_AddOns.GetAddOnMetadata("BugSack", "IconTexture"),
  slash = "/bugsack",
  needReloadOnImport = true,
  needProfileKey = false,
  preventRename = true,
  nonNativeProfileString = true,
  willOverrideProfile = true,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("BugSack")
    return loaded
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    if not SlashCmdList["BugSack"] then
      return
    end
    SlashCmdList["BugSack"]("")
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
  setProfile = function(self, profileKey)
  end,
  isDuplicate = function(self, profileKey)
    return true
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    if not profileString then return end
    if profileData and profileData.BugSack then
      return profileKey
    end
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    local _, decodedData = private:GenericDecode(profileString)
    if not decodedData then return end
    if not decodedData.BugSack or not decodedData.BugSackLDBIconDB then
      return
    end
    BugSackDB = decodedData.BugSack
    BugSackLDBIconDB = decodedData.BugSackLDBIconDB
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local data = {
      BugSack = BugSackDB,
      BugSackLDBIconDB = BugSackLDBIconDB
    }
    return private:GenericEncode(profileKey, data, self.moduleName)
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB)
    if not profileStringA or not profileStringB then
      return false
    end
    local _, profileDataA = private:GenericDecode(profileStringA)
    local _, profileDataB = private:GenericDecode(profileStringB)
    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end
}
private.modules[m.moduleName] = m
