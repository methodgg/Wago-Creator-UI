local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Details",
  wagoId = "qv63A7Gb",
  oldestSupported = "#Details.20260422.15002.171",
  addonNames = { "Details" },
  icon = C_AddOns.GetAddOnMetadata("Details", "IconTexture"),
  slash = "/details config",
  needReloadOnImport = false,
  needProfileKey = true,
  preventRename = false,
  willOverrideProfile = true,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("Details")
    return loaded
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    xpcall(function()
      DetailsAPI:OpenConfig()
    end, geterrorhandler())
  end,
  closeConfig = function(self)
    xpcall(function()
      DetailsAPI:CloseConfig()
    end, geterrorhandler())
  end,
  getProfileKeys = function(self)
    local profileKeys = {}
    xpcall(function()
      profileKeys = DetailsAPI:GetProfileKeys()
    end, geterrorhandler())
    return profileKeys
  end,
  getCurrentProfileKey = function(self)
    local profileKey
    xpcall(function()
      profileKey = DetailsAPI:GetCurrentProfileKey()
    end, geterrorhandler())
    return profileKey
  end,
  getProfileAssignments = function(self)
    local profileAssignments
    xpcall(function()
      profileAssignments = DetailsAPI:GetProfileAssignments()
    end, geterrorhandler())
    return profileAssignments
  end,
  isDuplicate = function(self, profileKey)
    if not profileKey then
      return false
    end
    return self:getProfileKeys()[profileKey] ~= nil
  end,
  setProfile = function(self, profileKey)
    if not profileKey then return end
    if not self:getProfileKeys()[profileKey] then return end
    xpcall(function()
      DetailsAPI:SetProfile(profileKey)
    end, geterrorhandler())
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)

  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    xpcall(function()
      DetailsAPI:ImportProfile(profileString, profileKey)
    end, geterrorhandler())
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local export
    xpcall(function()
      export = DetailsAPI:ExportProfile(profileKey)
    end, geterrorhandler())
    return export
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    local profileDataA, profileDataB
    xpcall(function()
      profileDataA = DetailsAPI:DecodeProfileString(profileStringA)
      profileDataB = DetailsAPI:DecodeProfileString(profileStringB)
    end, geterrorhandler())
    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB, {
      report_to_who = true,
      report_heal_links = true,
      report_lines = true,
      report_schema = true,
      class_time_played = true,
      logons = true,
      main_help_button = true,
      report_where = true,
      report_pos = true,
      unlock_button = true,
      version_announce = true,
      alert_frames = true,
      bookmark_tutorial = true,
      ctrl_click_close_tutorial = true,
      last_day = true,
      last_instance_id = true,
      last_instance_time = true,
      mythic_dungeon_id = true,
      combat_id_global = true,
      player_stats = true,
      data_harvested_for_charts = true,
      apocalypse_savedsegments = true,
      arena_data_headers = true,
      arena_data_compressed = true,
      arena_data_index_selected = true,
      current_exp_raid_encounters = true,
      encounter_journal_cache = true,
      recent_players = true,
      boss_wipe_counter = true,
      boss_icon_cache = true,
      shield_spellid_cache = true,
      latest_shield_spellid_cache_access = true,
      last_changelog_size = true,
      last_10days_cache_cleanup = true,
      latest_spell_pool_access = true,
      latest_npcid_pool_access = true,
      latest_encounter_spell_pool_access = true,
      spell_category_savedtable = true,
      spell_category_latest_query = true,
      spell_category_latest_save = true,
      spell_category_latest_sent = true,
      sessionId = true,
    })
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
