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

---@param profileName string
---@param profile table
---@param bIsUpdate boolean if true, the profile is an update and the user settings for mods/scripts will be copied
---@param bKeepModsNotInUpdate boolean indicates if wago update from companion, we won't use it here
local function doProfileImport(profileName, profile, bIsUpdate, bKeepModsNotInUpdate)
  DF = _G["DetailsFramework"]
  local bWasUsingUIParent = Plater.db.profile.use_ui_parent
  local scriptDataBackup =
      (bIsUpdate or bKeepModsNotInUpdate) and DF.table.copy({}, Plater.db.profile.script_data) or {}
  local hookDataBackup = (bIsUpdate or bKeepModsNotInUpdate) and DF.table.copy({}, Plater.db.profile.hook_data) or {}

  --switch to profile
  Plater.db:SetProfile(profileName)
  --cleanup profile -> reset to defaults
  Plater.db:ResetProfile(false, true)
  --import new profile settings
  DF.table.copy(Plater.db.profile, profile)

  --check if parent to UIParent is enabled and calculate the new scale
  if (Plater.db.profile.use_ui_parent) then
    if (not bIsUpdate or not bWasUsingUIParent) then --only update if necessary
      Plater.db.profile.ui_parent_scale_tune = 1 / UIParent:GetEffectiveScale()
    end
  else
    Plater.db.profile.ui_parent_scale_tune = 0
  end

  if (bIsUpdate or bKeepModsNotInUpdate) then
    --copy user settings for mods/scripts and keep mods/scripts which are not part of the profile
    for index, oldScriptObject in ipairs(scriptDataBackup) do
      local scriptDB = Plater.db.profile.script_data or {}
      local bFound = false
      for i = 1, #scriptDB do
        local scriptObject = scriptDB[i]
        if (scriptObject.Name == oldScriptObject.Name) then
          if (bIsUpdate) then
            Plater.UpdateOptionsForModScriptImport(scriptObject, oldScriptObject)
          end
          bFound = true
          break
        end
      end

      if (not bFound and bKeepModsNotInUpdate) then
        table.insert(scriptDB, oldScriptObject)
      end
    end

    for index, oldScriptObject in ipairs(hookDataBackup) do
      local scriptDB = Plater.db.profile.hook_data or {}
      local bFound = false
      for i = 1, #scriptDB do
        local scriptObject = scriptDB[i]
        if (scriptObject.Name == oldScriptObject.Name) then
          if (bIsUpdate) then
            Plater.UpdateOptionsForModScriptImport(scriptObject, oldScriptObject)
          end

          bFound = true
          break
        end
      end

      if (not bFound and bKeepModsNotInUpdate) then
        table.insert(scriptDB, oldScriptObject)
      end
    end
  end

  --cleanup NPC cache/colors
  ---@type table<number, string[]> [1] npcname [2] zonename [3] language
  local cache = Plater.db.profile.npc_cache

  local cacheTemp = DF.table.copy({}, cache)
  for npcId, npcData in pairs(cacheTemp) do
    ---@cast npcData table{key1: string, key2: string, key3: string|nil}
    if (tonumber(npcId)) then
      cache[npcId] = nil
      cache[tonumber(npcId)] = npcData
    end
  end

  --cleanup npc colors
  local colors = Plater.db.profile.npc_colors
  local colorsTemp = DF.table.copy({}, colors)

  for npcId, npcColorTable in pairs(colorsTemp) do
    if tonumber(npcId) then
      colors[npcId] = nil
      colors[tonumber(npcId)] = npcColorTable
    end
  end

  --cleanup cast colors/sounds
  local castColors = Plater.db.profile.cast_colors
  local castColorsTemp = DF.table.copy({}, castColors)

  for spellId, castColorTable in pairs(castColorsTemp) do
    if tonumber(spellId) then
      castColors[spellId] = nil
      castColors[tonumber(spellId)] = castColorTable
    end
  end

  local audioCues = Plater.db.profile.cast_audiocues
  local audioCuesTemp = DF.table.copy({}, audioCues)

  for spellId, audioCuePath in pairs(audioCuesTemp) do
    if tonumber(spellId) then
      audioCues[spellId] = nil
      audioCues[tonumber(spellId)] = audioCuePath
    end
  end

  --restore CVars of the profile
  Plater.RestoreProfileCVars()

  --automatically reload the user UI
  -- ReloadUI()
end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Plater",
  wagoId = "kRNLep6o",
  oldestSupported = "Plater-v585b-Retail",
  addonNames = { "Plater" },
  conflictingAddons = { "Kui_Nameplates", "Kui_Nameplates_Core", "Kui_Nameplates_Core_Config" },
  icon = [[Interface\AddOns\Plater\images\cast_bar]],
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
    doProfileImport(profileKey, profile, true, false)
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
    return private:DeepCompareAsync(rawProfileDataA, rawProfileDataB, { login_counter = true })
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
