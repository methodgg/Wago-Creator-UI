local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@param profileString string
---@return table | nil
---@return string | nil
local decodeProfileString = function(profileString)
  local decodedName, decodedProfileString
  local firstBracket = strfind(profileString, "{")
  if firstBracket and firstBracket > 1 then
    decodedName = strsub(profileString, 1, firstBracket - 1)
    decodedProfileString = strsub(profileString, firstBracket)
  else
    decodedName = "import"
  end
  local kui = LibStub("Kui-1.0")
  ---@diagnostic disable-next-line: undefined-field
  local table, tlen = kui.string_to_table(decodedProfileString)
  if not table or tlen == 0 then
    return
  end
  return table, decodedName
end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Kui Nameplates",
  wagoId = "kNMd8qGz",
  oldestSupported = "2.29.18",
  addonNames = { "Kui_Nameplates", "Kui_Nameplates_Core", "Kui_Nameplates_Core_Config" },
  conflictingAddons = { "Plater" },
  icon = C_AddOns.GetAddOnMetadata("Kui_Nameplates", "IconTexture"),
  slash = "/knp",
  needReloadOnImport = true,
  needProfileKey = false,
  preventRename = false,
  willOverrideProfile = false,
  nonNativeProfileString = false,
  needSpecialInterface = false,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("Kui_Nameplates")
    return loaded
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    local core = SlashCmdList["KUINAMEPLATESCORE"]
    local lod = SlashCmdList["KUINAMEPLATES_LOD"]
    if core then
      core("")
    elseif lod then
      lod("")
    end
  end,
  closeConfig = function(self)
    SettingsPanel:Hide()
  end,
  getProfileKeys = function(self)
    return KuiNameplatesCoreSaved.profiles
  end,
  getCurrentProfileKey = function(self)
    return KuiNameplatesCoreCharacterSaved.profile
  end,
  getProfileAssignments = function(self)
    --stored character specific
    return nil
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
    local config = KuiNameplatesCore.config
    config:SetProfile(profileKey)
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    if not profileString then
      return
    end
    local table, decodedKey = decodeProfileString(profileString)
    --very weird export format
    --need to check in the future if this test causes issues if another addon has a format like this
    if table and decodedKey then
      return decodedKey
    end
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
    local table = decodeProfileString(profileString)
    local config = KuiNameplatesCore.config
    config.csv.profile = profileKey
    config:PostProfile(profileKey, table)
  end,
  exportProfile = function(self, profileKey)
    if not profileKey then return end
    if type(profileKey) ~= "string" then return end
    if not self:getProfileKeys()[profileKey] then return end
    local kui = LibStub("Kui-1.0")
    ---@diagnostic disable-next-line: undefined-field
    local tableToString = kui.table_to_string
    local config = KuiNameplatesCore.config
    -- dont use GetProfile, it has unwanted side effects
    local profile = config.gsv.profiles[profileKey]
    local encoded = tableToString(profile)
    local export = profileKey..encoded
    return export
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then
      return false
    end
    local decodedTableA = decodeProfileString(profileStringA)
    local decodedTableB = decodeProfileString(profileStringB)
    if not decodedTableA or not decodedTableB then
      return false
    end
    return private:DeepCompareAsync(decodedTableA, decodedTableB)
  end,
  refreshHookList = {
    {
      tableFunc = function()
        return KuiNameplatesCore
      end,
      functionNames = { "ConfigChanged" }
    },
    {
      tableFunc = function()
        return KuiNameplatesCore.config
      end,
      functionNames = { "PostProfile" }
    }
  }
}

private.modules[m.moduleName] = m
