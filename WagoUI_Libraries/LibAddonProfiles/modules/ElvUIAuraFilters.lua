local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end
local EXPORT_PREFIX = "!E1!"

---@type LibAddonProfilesModule
local m = {
  moduleName = "ElvUI Aura Filters",
  oldestSupported = "v13.76",
  addonNames = { "ElvUI", "ElvUI_Libraries", "ElvUI_Options" },
  icon = C_AddOns.GetAddOnMetadata("ElvUI", "IconTexture"),
  slash = "/ec",
  needReloadOnImport = true,
  needProfileKey = false,
  preventRename = false,
  willOverrideProfile = true,
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
    return {
      ["Global"] = true
    }
  end,
  getCurrentProfileKey = function(self)
    return "Global"
  end,
  isDuplicate = function(self, profileKey)
    return true
  end,
  setProfile = function(self, profileKey)
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    if not profileString then return end
    local prefix = strsub(profileString, 1, 4)
    if prefix ~= EXPORT_PREFIX then
      return nil
    end
    local distributor = ElvUI[1]:GetModule("Distributor")
    local profileType, _, data = distributor:Decode(profileString)
    if profileType == "filters" and data then
      return ""
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
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    --Core\General\Distributor.lua
    local E = ElvUI[1]
    local D = E:GetModule("Distributor")
    local _, profileExport = D:GetProfileExport("filters", profileKey, "text")
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
  end
}

private.modules[m.moduleName] = m
