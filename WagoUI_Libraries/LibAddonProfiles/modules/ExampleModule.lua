local _, loadingAddonNamespace = ...;
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal();
if (not private) then return; end

---@class RefreshHook : table
---@field tableFunc fun() : table The target table that we want to hook functions on
---@field functionNames table<number, string> The names of the functions that we want to hook

---@class LibAddonProfilesModule : table
---@field moduleName string
---@field icon number | string
---@field slash string
---@field needReloadOnImport boolean
---@field needProfileKey boolean If importing a profilestring needs a profileKey that is not otherwise encoded in the profileString. Was used by the import anything function, might need again
---@field preventRename boolean For AddOns that have only global profiles, used in the intro wizard
---@field willOverrideProfile boolean If the profile will override the current profile when imported. Also for AddOns that only have global profiles
---@field nonNativeProfileString boolean
---@field isLoaded fun(self: LibAddonProfilesModule) : boolean
---@field needsInitialization fun(self: LibAddonProfilesModule) : boolean
---@field openConfig fun(self: LibAddonProfilesModule) : nil
---@field closeConfig fun(self: LibAddonProfilesModule) : nil
---@field getProfileKeys? fun(self: LibAddonProfilesModule,) : table<string, any>
---@field getCurrentProfileKey? fun(self: LibAddonProfilesModule,) : string
---@field getProfileAssignments? fun(self: LibAddonProfilesModule) : table<string, string> | nil The key should be in format "Playername - RealmName". The value should be the profile key.
---@field isDuplicate fun(self: LibAddonProfilesModule, profileKey: string) : boolean
---@field setProfile? fun(self: LibAddonProfilesModule, profileKey: string)
---@field testImport fun(self: LibAddonProfilesModule, profileString: string, profileKey: string | nil, profileData: table| nil, rawData: table | nil, moduleName: string | nil) : string | table | nil Test the profile string to see if it can be imported. Return the profile key if it can, nil otherwise. Tests profileData, rawData, and moduleName if they are provided, otherwise decodes the profileString and tests that.
---@field importProfile fun(self: LibAddonProfilesModule, profileString: string, profileKey: string, fromIntro: boolean) : nil
---@field exportProfile fun(self: LibAddonProfilesModule, profileKey: string | table) : string | table | nil
---@field exportOptions table<any, any> | nil
---@field exportGroup? fun(self: LibAddonProfilesModule, profileKey: string) : string | nil
---@field setExportOptions? fun(self: LibAddonProfilesModule, options: table) : nil
---@field areProfileStringsEqual fun(self: LibAddonProfilesModule, profileStringA: string | nil, profileStringB: string | nil , tableA : table | nil, tableB : table | nil) : areEqual: boolean, changedEntries: table | nil, removedEntries: table | nil
---@field refreshHookList table<number, RefreshHook> | nil Defines what functions should be hooked when wanting to monitor additions / deletions of profiles and changes to the currently active profile key.

---@type LibAddonProfilesModule
local m = {
  moduleName = "ExampleModule",
  icon = 9999999,
  slash = "/exampleslash",
  needReloadOnImport = false,
  needProfileKey = false,
  preventRename = false,
  willOverrideProfile = false,
  nonNativeProfileString = false,

  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("AddonName")
    return loaded
  end,

  needsInitialization = function(self)
    return false
  end,

  openConfig = function(self)

  end,

  closeConfig = function(self)

  end,

  getProfileKeys = function(self)
    return {
      ["Global"] = true
    }
  end,

  getCurrentProfileKey = function(self)
    return "Global"
  end,

  isDuplicate = function(self, profileKey)
    if not profileKey then return false end
    return self:getProfileKeys()[profileKey] ~= nil
  end,

  setProfile = function(self, profileKey)
    if not profileKey then return end
    if not self:getProfileKeys()[profileKey] then return end
  end,

  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    if not profileString then return end
  end,

  importProfile = function(self, profileString, profileKey, fromIntro)
    if not profileString then return end
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
  end,

  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then return false end
    local _, profileDataA = private:GenericDecode(profileStringA)
    local _, profileDataB = private:GenericDecode(profileStringB)
    if not profileDataA or not profileDataB then return false end
    return private:DeepCompareAsync(profileDataA, profileDataB)
  end,

  refreshHookList = {
    {
      tableFunc = function()
        return ExampleAddon.db
      end,
      functionNames = { "SetProfile", "DeleteProfile" }
    },
  }
}
private.modules[m.moduleName] = m
