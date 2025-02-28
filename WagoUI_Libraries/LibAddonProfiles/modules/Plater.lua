local loadingAddon, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

local function deepCopyAsync(orig)
  local orig_type = type(orig)
  local copy
  coroutine.yield()
  if orig_type == "table" then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[deepCopyAsync(orig_key)] = deepCopyAsync(orig_value)
    end
    setmetatable(copy, deepCopyAsync(getmetatable(orig)))
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Plater",
  wagoId = "kRNLep6o",
  oldestSupported = "Plater-v585b-Retail",
  addonNames = { "Plater" },
  conflictingAddons = { "Kui_Nameplates", "Kui_Nameplates_Core", "Kui_Nameplates_Core_Config" },
  icon = C_AddOns.GetAddOnMetadata("Plater", "IconTexture"),
  slash = "/plater",
  needReloadOnImport = true,
  needProfileKey = true,
  preventRename = false,
  willOverrideProfile = false,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    return Plater and true or false
  end,
  isUpdated = function(self)
    local currentVersionString = private:GetAddonVersionCached(self.addonNames[1])
    if not currentVersionString then
      return false
    end
    -- we look at 585b vs 583a
    local cMajor, cMinor = string.match(currentVersionString, "(%d+)(%a*)")
    cMajor = cMajor and tonumber(cMajor) or 0
    local oMajor, oMinor = string.match(self.oldestSupported, "(%d+)(%a*)")
    oMajor = oMajor and tonumber(oMajor) or 0
    if cMajor > oMajor then
      return true
    end
    if cMajor < oMajor then
      return false
    end
    if cMinor > oMinor then
      return true
    end
    if cMinor < oMinor then
      return false
    end
    return true
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    if not SlashCmdList["PLATER"] then return end
    SlashCmdList["PLATER"]("")
  end,
  closeConfig = function(self)
    PlaterOptionsPanelFrame:Hide()
  end,
  getProfileKeys = function(self)
    return PlaterDB.profiles
  end,
  getCurrentProfileKey = function(self)
    return Plater.db:GetCurrentProfile()
  end,
  getProfileAssignments = function(self)
    return PlaterDB.profileKeys
  end,
  isDuplicate = function(self, profileKey)
    if not profileKey then
      return false
    end
    local profiles = Plater.db:GetProfiles()
    local profileExists = false
    for i, existingProfName in ipairs(profiles) do
      if existingProfName == profileKey then
        profileExists = true
        break
      end
    end
    return profileExists
  end,
  setProfile = function(self, profileKey)
    if not profileKey then return end
    if not self:getProfileKeys()[profileKey] then return end
    Plater.db:SetProfile(profileKey)
    if DetailsFrameworkPromptSimple then
      DetailsFrameworkPromptSimple.CloseButton:Click()
    end
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    if not profileString then return end
    if rawData and rawData.plate_config and rawData.profile_name then
      return rawData.profile_name
    end
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    local _, _, profile = private:GenericDecode(profileString)
    if not profile then return end

    local bIsUpdate = true             --if true, the profile is an update and the user settings for mods/scripts will be copied
    local bKeepModsNotInUpdate = false -- indicates if wago update from companion, we won't use it here
    local doNotReload = true
    local keepScaleTune = true         -- don't mess with ui scale
    xpcall(function()
      Plater.ImportAndSwitchProfile(profileKey, profile, bIsUpdate, bKeepModsNotInUpdate, doNotReload, keepScaleTune)
    end, geterrorhandler())

    coroutine.yield()
    if DetailsFrameworkPromptSimple then
      DetailsFrameworkPromptSimple:Hide()
    end
    C_Timer.After(.5,
      function()
        if DetailsFrameworkPromptSimple then
          DetailsFrameworkPromptSimple:Hide()
        end
      end
    )
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local LibAceSerializer = LibStub:GetLibrary("AceSerializer-3.0Async")
    local LibDeflate = LibStub:GetLibrary("LibDeflateAsync")
    --Plater_Comms.lua
    local profile = deepCopyAsync(Plater.db.profiles[profileKey])
    coroutine.yield()
    profile.profile_name = profileKey
    profile.spell_animation_list = nil
    profile.script_data_trash = {}
    profile.hook_data_trash = {}
    profile.plugins_data = {}
    --cleanup mods HooksTemp (for good)
    for i = #profile.hook_data, 1, -1 do
      local scriptObject = profile.hook_data[i]
      scriptObject.HooksTemp = {}
    end
    --convert the profile to string
    local dataSerialized = LibAceSerializer:Serialize(profile)
    coroutine.yield()
    local dataCompressed = LibDeflate:CompressDeflate(dataSerialized, { level = 5 })
    coroutine.yield()
    local dataEncoded = LibDeflate:EncodeForPrint(dataCompressed)
    coroutine.yield()
    return dataEncoded
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    local _, _, rawProfileDataA = private:GenericDecode(profileStringA)
    local _, _, rawProfileDataB = private:GenericDecode(profileStringB)
    if not rawProfileDataA or not rawProfileDataB then
      return false
    end
    return private:DeepCompareAsync(rawProfileDataA, rawProfileDataB,
      {
        login_counter = true,
        captured_casts = true,
        captured_spells = true,
        last_news_time = true,
        npc_cache = true
      }
    )
  end,
  refreshHookList = {
    {
      tableFunc = function()
        return Plater.db
      end,
      functionNames = { "SetProfile", "CopyProfile", "DeleteProfile" }
    }
  }
}

private.modules[m.moduleName] = m
