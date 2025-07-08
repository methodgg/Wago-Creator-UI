local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

local optionsFrame

---@type LibAddonProfilesModule
local m = {
  moduleName = "BigWigs",
  wagoId = "5NRegwG3",
  oldestSupported = "v355.3",
  addonNames = { "BigWigs", "BigWigs_Core", "BigWigs_Plugins", "BigWigs_Options" },
  conflictingAddons = { "DBM-Core" },
  icon = C_AddOns.GetAddOnMetadata("BigWigs", "IconTexture"),
  slash = "/bigwigs",
  needReloadOnImport = true,
  needProfileKey = false,
  preventRename = false,
  willOverrideProfile = false,
  nonNativeProfileString = true,
  needSpecialInterface = false,
  isLoaded = function(self)
    return BigWigs and true or false
  end,
  isUpdated = function(self)
    if BigWigsAPI and BigWigsAPI.GetVersion then
      local _, guildVersion = BigWigsAPI:GetVersion()
      if guildVersion and guildVersion ~= 0 then return true end
    end
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return C_AddOns.IsAddOnLoaded("BigWigs") and not self:isLoaded()
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
    local characterName = UnitName("player").." - "..GetRealmName()
    return BigWigs3DB.profileKeys and BigWigs3DB.profileKeys[characterName]
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
    BigWigsLoader.db:SetProfile(profileKey)
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    if not profileString then return end
    if profileKey and profileData and profileData.BigWigs3DB then
      return profileKey
    end
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    local _, pData = private:GenericDecode(profileString)
    if not pData then
      return
    end
    local bw3db = pData.BigWigs3DB
    local bw3Idb = pData.BigWigsIconDB
    --namespaces
    for namespaceKey, namespace in pairs(bw3db.namespaces) do
      if namespace.profiles then
        for _, profile in pairs(namespace.profiles) do
          BigWigs3DB.namespaces = BigWigs3DB.namespaces or {}
          BigWigs3DB.namespaces[namespaceKey] = BigWigs3DB.namespaces[namespaceKey] or {}
          BigWigs3DB.namespaces[namespaceKey].profiles = BigWigs3DB.namespaces[namespaceKey].profiles or {}
          BigWigs3DB.namespaces[namespaceKey].profiles[profileKey] = profile
        end
      end
    end
    --profileKey
    BigWigs3DB.profileKeys = BigWigs3DB.profileKeys or {}
    BigWigs3DB.profileKeys[UnitName("player").." - "..GetRealmName()] = profileKey
    --profiles
    for _, profile in pairs(bw3db.profiles) do
      BigWigs3DB.profiles = BigWigs3DB.profiles or {}
      BigWigs3DB.profiles[profileKey] = profile
    end
    --icon position
    BigWigsIconDB = bw3Idb
  end,
  exportOptions = {
    example = false
  },
  setExportOptions = function(self, options)
    for k, v in pairs(options) do
      self.exportOptions[k] = v
    end
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local data = {
      BigWigs3DB = {
        profiles = {
          [profileKey] = BigWigs3DB.profiles[profileKey]
        },
        profileKeys = {
          [""] = profileKey
        },
        namespaces = {}
      },
      BigWigsIconDB = {
        hide = BigWigsIconDB.hide,
        minimapPos = BigWigsIconDB.minimapPos
      }
    }
    for namespaceKey, namespace in pairs(BigWigs3DB.namespaces) do
      if namespace.profiles then
        for pKey, p in pairs(namespace.profiles) do
          if pKey == profileKey then
            data.BigWigs3DB.namespaces[namespaceKey] = {
              profiles = {
                [profileKey] = p
              }
            }
          end
        end
      end
    end
    return private:GenericEncode(profileKey, data, self.moduleName)
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
        return BigWigsLoader.db
      end,
      functionNames = { "SetProfile", "DeleteProfile" }
    }
  }
}
private.modules[m.moduleName] = m
