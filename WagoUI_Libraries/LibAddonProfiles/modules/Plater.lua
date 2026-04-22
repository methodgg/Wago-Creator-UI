local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Plater",
  wagoId = "kRNLep6o",
  oldestSupported = "Plater-v643-Retail",
  addonNames = { "Plater" },
  conflictingAddons = { "Kui_Nameplates", "Kui_Nameplates_Core", "Kui_Nameplates_Core_Config" },
  icon = C_AddOns.GetAddOnMetadata("Plater", "IconTexture"),
  slash = "/plater",
  needReloadOnImport = true,
  needProfileKey = true,
  preventRename = false,
  willOverrideProfile = true,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("Plater")
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
      PlaterAPI:OpenConfig()
    end, geterrorhandler())
  end,
  closeConfig = function(self)
    xpcall(function()
      PlaterAPI:CloseConfig()
    end, geterrorhandler())
  end,
  getProfileKeys = function(self)
    local profileKeys = {}
    xpcall(function()
      local apiProfileKeys = PlaterAPI:GetProfileKeys() or {}
      -- PlaterAPI returns AceDB's array of names, but WagoUI expects [profileKey] = true.
      for key, value in pairs(apiProfileKeys) do
        if type(key) == "string" then
          profileKeys[key] = value
        elseif type(value) == "string" then
          profileKeys[value] = true
        end
      end
    end, geterrorhandler())
    return profileKeys
  end,
  getProfileAssignments = function(self)
    -- Missing in installed addon source: PlaterAPI:GetProfileAssignments()
    return nil
  end,
  getCurrentProfileKey = function(self)
    local profileKey
    xpcall(function()
      profileKey = PlaterAPI:GetCurrentProfileKey()
    end, geterrorhandler())
    return profileKey
  end,
  isDuplicate = function(self, profileKey)
    if not profileKey then return false end
    return self:getProfileKeys()[profileKey] ~= nil
  end,
  setProfile = function(self, profileKey)
    if not profileKey then return end
    if not self:getProfileKeys()[profileKey] then return end
    xpcall(function()
      PlaterAPI:SetProfile(profileKey)
    end, geterrorhandler())
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)

  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    xpcall(function()
      PlaterAPI:ImportProfile(profileString, profileKey)
    end, geterrorhandler())
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local export
    xpcall(function()
      export = PlaterAPI:ExportProfile(profileKey)
    end, geterrorhandler())
    return export
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    local profileDataA, profileDataB
    xpcall(function()
      profileDataA = PlaterAPI:DecodeProfileString(profileStringA)
      profileDataB = PlaterAPI:DecodeProfileString(profileStringB)
    end, geterrorhandler())
    if not profileDataA or not profileDataB then
      return false
    end
    return private:DeepCompareAsync(profileDataA, profileDataB, {
      captured_casts = true,
      captured_spells = true,
      expansion_triggerwipe = true,
      hook_data_trash = true,
      last_news_time = true,
      login_counter = true,
      npc_cache = true,
      number_region_first_run = true,
      patch_version = true,
      patch_version_profile = true,
      plugins_data = true,
      profile_name = true,
      reopoen_options_panel_on_tab = true,
      saved_cvars_last_change = true,
      script_data_trash = true,
      tocversion = true,
      use_ui_parent_just_enabled = true,
    })
  end
}

private.modules[m.moduleName] = m
