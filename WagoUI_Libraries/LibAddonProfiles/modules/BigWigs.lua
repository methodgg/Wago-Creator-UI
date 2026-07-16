local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

local REQUESTER_NAME = "LibAddonProfiles"
local LibAsync = LibStub("LibAsync")

---@async
---@param profileString string
---@return table | nil
local function decodeBigWigsProfileString(profileString)
  if type(profileString) ~= "string" then return end
  local versionPlain, importData = profileString:match("^(%w+):(.+)$")
  if not versionPlain or not versionPlain:match("^BW") then return end
  local data = private:BlizzardDecodeB64CBOR(importData, true)
  if not data or data.version ~= versionPlain then return end
  return data
end

---@type LibAddonProfilesModule
local m = {
  moduleName = "BigWigs",
  wagoId = "5NRegwG3",
  oldestSupported = "v419",
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
  isProfileStringCompatible = function(self, profileString)
    return type(profileString) == "string" and profileString:sub(1, 4) == "BW2:"
  end,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("BigWigs") and BigWigsAPI ~= nil
    return loaded
  end,
  isUpdated = function(self)
    if BigWigsAPI and BigWigsAPI.GetVersion then
      local _, guildVersion = BigWigsAPI.GetVersion()
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
  getProfileKeys = function(self)
    local profileKeys = {}
    xpcall(function()
      for _, profileKey in ipairs(BigWigsAPI.GetProfileList()) do
        profileKeys[profileKey] = true
      end
    end, geterrorhandler())
    return profileKeys
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
    local duplicate = false
    xpcall(function()
      duplicate = BigWigsAPI.IsValidProfile(profileKey)
    end, geterrorhandler())
    return duplicate
  end,
  ---@async
  setProfile = function(self, profileKey)
    if type(profileKey) ~= "string" then return end
    if not self:isDuplicate(profileKey) then return end
    if profileKey == self:getCurrentProfileKey() then return end
    LibAsync:Await(function(done)
      local success, swapStarted = xpcall(function()
        return BigWigsAPI.SwapProfile(REQUESTER_NAME, profileKey, done)
      end, geterrorhandler())
      if not success or not swapStarted then done() end
    end)
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)

  end,
  ---@async
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not self:isProfileStringCompatible(profileString) then return false end
    if profileKey == "" then profileKey = nil end
    return LibAsync:Await(function(done)
      local success = xpcall(function()
        BigWigsAPI.RegisterProfile(REQUESTER_NAME, profileString, profileKey, done)
      end, geterrorhandler())
      if not success then done(false) end
    end)
  end,
  ---@async
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local profileString = LibAsync:Await(function(done)
      local success = xpcall(function()
        BigWigsAPI.RequestProfile(
          REQUESTER_NAME,
          profileKey,
          done
        )
      end, geterrorhandler())
      if not success then done() end
    end)
    return profileString
  end,
  ---@async
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
