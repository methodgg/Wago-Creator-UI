local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end
local EXPORT_PREFIX = "!E2!"

---@type LibAddonProfilesModule
local m = {
  moduleName = "ElvUI Aura Filters",
  oldestSupported = "v15.19",
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
    xpcall(function()
      SlashCmdList["ACECONSOLE_ELVUI"]()
    end, geterrorhandler())
  end,
  closeConfig = function(self)
    xpcall(function()
      local E = unpack(ElvUI)
      E.Config_CloseWindow()
    end, geterrorhandler())
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
    local profileType, data
    local success = xpcall(function()
      local distributor = ElvUI[1]:GetModule("Distributor")
      profileType, _, data = distributor:Decode(profileString)
    end, geterrorhandler())
    if not success then return end
    if profileType == "filters" and data then
      return ""
    end
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    xpcall(function()
      local E = ElvUI[1]
      local D = E:GetModule("Distributor")
      local decodedType, _, decodedData = D:Decode(profileString)
      if not decodedType or not decodedData then return end
      -- important to use the supplied profileKey, as the decoded key might be different
      local force = true
      D:SetImportedProfile(decodedType, profileKey, decodedData, force)
    end, geterrorhandler())
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    --Core\General\Distributor.lua
    local profileExport
    local success = xpcall(function()
      local E = ElvUI[1]
      local D = E:GetModule("Distributor")
      _, profileExport = D:GetProfileExport("filters", profileKey, "text")
    end, geterrorhandler())
    if not success or not profileExport then return nil, false end
    return profileExport, true
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    local profileDataA, profileDataB
    local success = xpcall(function()
      local E = ElvUI[1]
      local D = E:GetModule("Distributor")
      _, _, profileDataA = D:Decode(profileStringA)
      _, _, profileDataB = D:Decode(profileStringB)
    end, geterrorhandler())
    if not success or not profileDataA or not profileDataB then
      return nil, nil, nil, false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end
}

private.modules[m.moduleName] = m
