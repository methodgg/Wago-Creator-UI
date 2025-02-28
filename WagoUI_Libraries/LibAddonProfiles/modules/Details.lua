local loadingAddon, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

local function compressData(data)
  local LibDeflate = LibStub:GetLibrary("LibDeflateAsync")
  local LibAceSerializer = LibStub:GetLibrary("AceSerializer-3.0Async")
  --check if there isn't a function in the data to export
  local dataCopied = DetailsFramework.table.copytocompress({}, data)
  if (LibDeflate and LibAceSerializer) then
    local dataSerialized = LibAceSerializer:Serialize(dataCopied)
    coroutine.yield()
    if (dataSerialized) then
      local dataCompressed = LibDeflate:CompressDeflate(dataSerialized, { level = 5 })
      if (dataCompressed) then
        local dataEncoded = LibDeflate:EncodeForPrint(dataCompressed)
        coroutine.yield()
        return dataEncoded
      end
    end
  end
end

local exportProfileBlacklist = {
  custom = true,
  cached_specs = true,
  cached_talents = true,
  combat_id = true,
  combat_counter = true,
  mythic_dungeon_currentsaved = true,
  nick_tag_cache = true,
  plugin_database = true,
  character_data = true,
  active_profile = true,
  SoloTablesSaved = true,
  RaidTablesSaved = true,
  benchmark_db = true,
  rank_window = true,
  last_realversion = true,
  last_version = true,
  __profiles = true,
  latest_news_saw = true,
  always_use_profile = true,
  always_use_profile_name = true,
  always_use_profile_exception = true,
  savedStyles = true,
  savedTimeCaptures = true,
  lastUpdateWarning = true,
  spell_school_cache = true,
  global_plugin_database = true,
  details_auras = true,
  item_level_pool = true,
  latest_report_table = true,
  boss_mods_timers = true,
  spell_pool = true,
  encounter_spell_pool = true,
  npcid_pool = true,
  createauraframe = true,
  mythic_plus = true,
  plugin_window_pos = true,
  switchSaved = true,
  installed_skins_cache = true,
  trinket_data = true,
  keystone_cache = true,
  performance_profiles = true
}

---@type LibAddonProfilesModule
local m = {
  moduleName = "Details",
  wagoId = "qv63A7Gb",
  oldestSupported = "#Details.12879.159",
  addonNames = { "Details", "Details_Compare2", "Details_DataStorage" },
  icon = C_AddOns.GetAddOnMetadata("Details", "IconTexture"),
  slash = "/details config",
  needReloadOnImport = false,
  needProfileKey = true,
  preventRename = false,
  willOverrideProfile = false,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    return Details and true or false
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    if not SlashCmdList["DETAILS"] then return end
    SlashCmdList["DETAILS"]("options")
  end,
  closeConfig = function(self)
    DetailsOptionsWindow:Hide()
  end,
  getProfileKeys = function(self)
    return _detalhes_global.__profiles
  end,
  getCurrentProfileKey = function(self)
    return Details:GetCurrentProfileName()
  end,
  getProfileAssignments = function(self)
    --stored character specific
    return nil
  end,
  isDuplicate = function(self, profileKey)
    if not profileKey then
      return false
    end
    return self:getProfileKeys()[profileKey]
  end,
  setProfile = function(self, profileKey)
    if not profileKey then return end
    if not self:getProfileKeys()[profileKey] then return end
    Details:ApplyProfile(profileKey)
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    if not profileString then return end
    if rawData and rawData.profile and rawData.profile.all_in_one_windows and rawData.profile.class_specs_coords then
      return ""
    end
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    local bImportAutoRunCode, bIsFromImportPrompt, overwriteExisting = false, true, true
    xpcall(function()
      Details:ImportProfile(profileString, profileKey, bImportAutoRunCode, bIsFromImportPrompt, overwriteExisting)
    end, geterrorhandler())
    --import automation
    profileString = DetailsFramework:Trim(profileString)
    local profileData = Details:DecompressData(profileString, "print")
    if profileData then
      for i, v in Details:ListInstances() do
        DetailsFramework.table.copy(v.hide_on_context, profileData.profile.instances[i].hide_on_context)
      end
    end
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    --functions\profiles.lua
    --need to call this so changes to the current profile are committed to the Details SavedVariables
    --TODO: logout still applies some changes to the data, not sure what this is about
    --      the important profile data is saved here, just might trigger additional versions
    Details.SaveProfile(profileKey)
    local profileObject = Details:GetProfile(profileKey)
    coroutine.yield()
    --data saved individual for each character
    local defaultPlayerData = Details.default_player_data
    local playerData = {}
    --data saved for the account
    local defaultGlobalData = Details.default_global_data
    local globalData = {}
    --fill player and global data tables
    for key, _ in pairs(defaultPlayerData) do
      if (not exportProfileBlacklist[key]) then
        if (type(Details[key]) == "table") then
          playerData[key] = DetailsFramework.table.copy({}, Details[key])
        else
          playerData[key] = Details[key]
        end
      end
      coroutine.yield()
    end
    for key, _ in pairs(defaultGlobalData) do
      if (not exportProfileBlacklist[key]) then
        if (type(Details[key]) == "table") then
          globalData[key] = DetailsFramework.table.copy({}, Details[key])
        else
          globalData[key] = Details[key]
        end
      end
      coroutine.yield()
    end
    coroutine.yield()
    local exportedData = {
      profile = profileObject,
      playerData = playerData,
      globaData = globalData, --typo in Details
      version = 1
    }
    return compressData(exportedData)
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
    return private:DeepCompareAsync(profileDataA, profileDataB,
      {
        report_to_who = true,
        report_heal_links = true,
        report_lines = true,
        report_schema = true,
      }
    )
  end,
  refreshHookList = {
    {
      tableFunc = function()
        return Details
      end,
      functionNames = { "ApplyProfile", "EraseProfile" }
    }
  }
}
private.modules[m.moduleName] = m
