local loadingAddon, loadingAddonNamespace = ...;
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal();
if (not private) then return; end

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
  performance_profiles = true,
}

---@return boolean
local isLoaded = function()
  return Details and true or false
end

---@return boolean
local needsInitialization = function()
  return false
end

---@return nil
local openConfig = function()
  SlashCmdList["DETAILS"]("options")
end

---@return nil
local closeConfig = function()
  DetailsOptionsWindow:Hide()
end

---@return table<string, any>
local getProfileKeys = function()
  return _detalhes_global.__profiles
end

---@return string
local getCurrentProfileKey = function()
  return Details:GetCurrentProfileName()
end

---@param profileKey string
local setProfile = function(profileKey)
  if not profileKey then return end
  if not getProfileKeys()[profileKey] then return end
  Details:ApplyProfile(profileKey)
end

---@param profileKey string
---@return boolean
local isDuplicate = function(profileKey)
  if not profileKey then return false end
  return getProfileKeys()[profileKey]
end

---@param profileString string
---@param profileKey string | nil
---@param profileData table | nil
---@param rawData table | nil
---@return string | nil
local testImport = function(profileString, profileKey, profileData, rawData)
  if not profileString then return end
  if rawData and rawData.profile and rawData.profile.all_in_one_windows and rawData.profile.class_specs_coords then
    return ""
  end
end

---@param profileString string
---@param profileKey string
local importProfile = function(profileString, profileKey, fromIntro)
  if not profileString then return end
  Details:ImportProfile(profileString, profileKey, nil, true, true);
end

---@param profileKey string | nil
---@return string | nil
local exportProfile = function(profileKey)
  if not profileKey then return end
  if not getProfileKeys()[profileKey] then return end
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
    version = 1,
  }
  return compressData(exportedData)
end

---@param profileStringA string
---@param profileStringB string
---@return boolean
local areProfileStringsEqual = function(profileStringA, profileStringB)
  if not profileStringA or not profileStringB then return false end
  local _, profileDataA = private:GenericDecode(profileStringA)
  local _, profileDataB = private:GenericDecode(profileStringB)
  if not profileDataA or not profileDataB then return false end
  return private:DeepCompareAsync(profileDataA, profileDataB)
end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Details",
  slash = "/details config",
  icon = [[Interface\AddOns\Details\images\minimap]],
  needReloadOnImport = false,
  needsInitialization = needsInitialization,
  needProfileKey = true,
  isLoaded = isLoaded,
  openConfig = openConfig,
  closeConfig = closeConfig,
  isDuplicate = isDuplicate,
  testImport = testImport,
  importProfile = importProfile,
  exportProfile = exportProfile,
  getProfileKeys = getProfileKeys,
  getCurrentProfileKey = getCurrentProfileKey,
  setProfile = setProfile,
  areProfileStringsEqual = areProfileStringsEqual,
  refreshHookList = {
    {
      tablePath = { "Details" },
      functionName = "ApplyProfile",
    },
    {
      tablePath = { "Details" },
      functionName = "EraseProfile",
    },
  }
}
private.modules[m.moduleName] = m
