local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

local WAGOUI_ADDON_NAME = "WagoUI"
local optionsFrame

---@param profileString string
---@return table | nil
local function decodeBigWigsProfileString(profileString)
  if type(profileString) ~= "string" then return end
  local versionPlain, importData = profileString:match("^(%w+):(.+)$")
  if not versionPlain or not versionPlain:match("^BW") then return end
  local data = private:BlizzardDecodeB64CBOR(importData, true)
  if not data or data.version ~= versionPlain or data.bossExport then return end
  return data
end

---@type LibAddonProfilesModule
local m = {
  moduleName = "BigWigs",
  wagoId = "5NRegwG3",
  oldestSupported = "v418.1",
  addonNames = { "BigWigs", "BigWigs_Core", "BigWigs_Plugins", "BigWigs_Options" },
  conflictingAddons = { "DBM-Core" },
  icon = C_AddOns.GetAddOnMetadata("BigWigs", "IconTexture"),
  slash = "/bigwigs",
  needReloadOnImport = false,
  needProfileKey = false,
  preventRename = false,
  willOverrideProfile = true,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("BigWigs") and BigWigsAPI ~= nil
    return loaded
  end,
  isUpdated = function(self)
    if BigWigsAPI and BigWigsAPI.GetVersion then
      local _, guildVersion = BigWigsAPI:GetVersion()
      if guildVersion and guildVersion ~= 0 then return true end
    end
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    if not SlashCmdList["BigWigs"] then
      return
    end
    SlashCmdList["BigWigs"]()
  end,
  closeConfig = function(self)
    local function findBWFrame()
      for i = 1, select("#", UIParent:GetChildren()) do
        local childFrame = select(i, UIParent:GetChildren())
        if childFrame and childFrame.obj and childFrame.obj.titletext then
          if childFrame.obj.titletext:GetText() == "BigWigs" then
            return childFrame
          end
        end
      end
    end
    optionsFrame = optionsFrame or findBWFrame()
    if optionsFrame then
      optionsFrame:Hide()
    end
  end,
  getProfileKeys = function(self)
    return BigWigs3DB.profiles
  end,
  getCurrentProfileKey = function(self)
    local profileKey
    xpcall(function()
      profileKey = BigWigsAPI.GetProfileName()
    end, geterrorhandler())
    return profileKey
  end,
  getProfileAssignments = function(self)
    return BigWigs3DB.profileKeys
  end,
  isDuplicate = function(self, profileKey)
    if not profileKey then return false end
    return self:getProfileKeys()[profileKey] ~= nil
  end,
  setProfile = function(self, profileKey)
    if not profileKey then return end
    if not self:getProfileKeys()[profileKey] then return end
    if profileKey == self:getCurrentProfileKey() then return end
    xpcall(function()
      BigWigsAPI.SwapProfile(WAGOUI_ADDON_NAME, profileKey)
    end, geterrorhandler())
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)

  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    if profileKey == "" then profileKey = nil end
    xpcall(function()
      BigWigsAPI.RegisterProfile(WAGOUI_ADDON_NAME, profileString, profileKey)
    end, geterrorhandler())
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local export
    xpcall(function()
      -- expect bw to provide this argument for now
      export = BigWigsAPI.RequestProfile(WAGOUI_ADDON_NAME, profileKey)
    end, geterrorhandler())
    return export
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    local profileDataA = decodeBigWigsProfileString(profileStringA)
    local profileDataB = decodeBigWigsProfileString(profileStringB)
    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end
}
private.modules[m.moduleName] = m
