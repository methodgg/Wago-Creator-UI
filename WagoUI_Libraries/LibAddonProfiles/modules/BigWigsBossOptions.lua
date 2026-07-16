local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

local bigWigsModule = private.modules.BigWigs
if (not bigWigsModule) then return end

local REQUESTER_NAME = "LibAddonProfiles"
local LibAsync = LibStub("LibAsync")

---@type LibAddonProfilesModule
local m = {
  moduleName = "BigWigs Boss Options",
  wagoId = bigWigsModule.wagoId,
  oldestSupported = bigWigsModule.oldestSupported,
  addonNames = bigWigsModule.addonNames,
  conflictingAddons = bigWigsModule.conflictingAddons,
  icon = bigWigsModule.icon,
  slash = bigWigsModule.slash,
  needReloadOnImport = bigWigsModule.needReloadOnImport,
  needProfileKey = bigWigsModule.needProfileKey,
  preventRename = bigWigsModule.preventRename,
  willOverrideProfile = bigWigsModule.willOverrideProfile,
  nonNativeProfileString = bigWigsModule.nonNativeProfileString,
  needSpecialInterface = bigWigsModule.needSpecialInterface,
  isProfileStringCompatible = function(self, profileString)
    return type(profileString) == "string" and profileString:sub(1, 5) == "BWB1:"
  end,
  isLoaded = function(self)
    return bigWigsModule:isLoaded()
  end,
  isUpdated = function(self)
    return bigWigsModule:isUpdated()
  end,
  needsInitialization = function(self)
    return bigWigsModule:needsInitialization()
  end,
  openConfig = function(self)
    bigWigsModule:openConfig()
  end,
  getProfileKeys = function(self)
    return bigWigsModule:getProfileKeys()
  end,
  getCurrentProfileKey = function(self)
    return bigWigsModule:getCurrentProfileKey()
  end,
  getProfileAssignments = function(self)
    return bigWigsModule:getProfileAssignments()
  end,
  isDuplicate = function(self, profileKey)
    return bigWigsModule:isDuplicate(profileKey)
  end,
  setProfile = function(self, profileKey)
    -- This is a no-op because BigWigs Boss Options does not have its own profiles. It uses the same profile as the main BigWigs module.
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)

  end,
  ---@async
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not self:isProfileStringCompatible(profileString) then return false end
    -- Boss options may be imported independently from the main BigWigs profile.
    -- They intentionally apply to the currently active profile, so profileKey is unused.
    return LibAsync:Await(function(done)
      local success = xpcall(function()
        BigWigsAPI.ImportBossOptions(REQUESTER_NAME, profileString, done)
      end, geterrorhandler())
      if not success then done(false) end
    end)
  end,
  ---@async
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    -- pass true for now, but we may want to make this configurable in the UI for the creator
    local includeRaids, includeSeasonalDungeons, includeExpansionDungeons = true, true, true
    local _, bossString = LibAsync:Await(function(done)
      local success = xpcall(function()
        BigWigsAPI.RequestProfile(
          REQUESTER_NAME,
          profileKey,
          done,
          includeRaids,
          includeSeasonalDungeons,
          includeExpansionDungeons
        )
      end, geterrorhandler())
      if not success then done() end
    end)
    return bossString
  end,
  ---@async
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    return bigWigsModule:areProfileStringsEqual(profileStringA, profileStringB, tableA, tableB)
  end
}

private.modules[m.moduleName] = m
