---@class LAPLoadingNamespace
local loadingAddonNamespace = select(2, ...)
local MAJOR = "LibAddonProfiles"
local MINOR = 23

-- Keyed by WOW_PROJECT_ID, which PTR and beta clients share with their live flavor. The names match Wago's game types.
-- Numeric keys because the WOW_PROJECT_* constants of other flavors are not defined on every client.
---@type table<number, GameFlavor>
local GAME_FLAVORS = {
  [1] = "retail",
  [2] = "classic",
  [5] = "bc",
  [11] = "wotlk",
  [14] = "cata",
  [18] = "forever",
  [19] = "mop",
}

---@class LibAddonProfiles
local LibAddonProfiles = LibStub:NewLibrary(MAJOR, MINOR)

if LibAddonProfiles then
  wipe(LibAddonProfiles)

  ---@class LibAddonProfilesPrivate : table
  ---@field modules table<string, LibAddonProfilesModule>
  ---@field gameFlavor GameFlavor | nil
  local LibAddonProfilesInternal = {
    modules = {},
    gameFlavor = GAME_FLAVORS[WOW_PROJECT_ID],
  }

  function loadingAddonNamespace:GetLibAddonProfilesInternal()
    return LibAddonProfilesInternal
  end

  ---@param moduleName string
  ---@return LibAddonProfilesModule module
  function LibAddonProfiles:GetModule(moduleName)
    return LibAddonProfilesInternal.modules[moduleName]
  end

  ---@return table<string, LibAddonProfilesModule>
  function LibAddonProfiles:GetAllModules()
    return LibAddonProfilesInternal.modules
  end

  ---The flavor of the running client, nil for clients WagoUI does not know (e.g. Plunderstorm).
  ---@return GameFlavor | nil
  function LibAddonProfiles:GetGameFlavor()
    return LibAddonProfilesInternal.gameFlavor
  end

  ---@param profileKey string
  ---@param profile table
  ---@param moduleName string
  ---@return string profileString The encoded profile string
  function LibAddonProfiles:GenericEncode(profileKey, profile, moduleName)
    return LibAddonProfilesInternal:GenericEncode(profileKey, profile, moduleName)
  end

  ---@param profileString string
  ---@return string | nil profileKey
  ---@return table | nil profileData
  ---@return table | nil rawData
  ---@return string | nil moduleName
  function LibAddonProfiles:GenericDecode(profileString)
    return LibAddonProfilesInternal:GenericDecode(profileString)
  end

  --- Checks if any addon from the list can enabled.
  ---@param addonNames table<number, string> | nil
  ---@return boolean
  function LibAddonProfiles:CanEnableAnyAddOn(addonNames)
    return LibAddonProfilesInternal:CanEnableAnyAddOn(addonNames)
  end

  ---Enables a list of AddOns. AddOns that can be enabled will be enabled after a UI reload.
  ---@param addonNames table<number, string>
  function LibAddonProfiles:EnableAddOns(addonNames)
    return LibAddonProfilesInternal:EnableAddOns(addonNames)
  end

  ---Disables a list of AddOns.
  ---If the Addon is in selectedModules and has field checked set to true, it will not be disabled
  ---@param addonNames table<number, string>
  ---@param selectedModules table<string, {checked: boolean}>
  function LibAddonProfiles:DisableConflictingAddons(addonNames, selectedModules)
    return LibAddonProfilesInternal:DisableConflictingAddons(addonNames, selectedModules)
  end

  ---Why exporting a profile under this name is a bad idea, or nil when the name is fine.
  ---Flags names most players already have, which installing would replace, and names taken from the creator's character.
  ---@param moduleName string
  ---@param profileKey string
  ---@return string | nil warning
  function LibAddonProfiles:GetProfileNameWarning(moduleName, profileKey)
    return LibAddonProfilesInternal:GetProfileNameWarning(moduleName, profileKey)
  end

  ---@param ... any
  function LibAddonProfilesInternal:PrintError(...)
    print("|cff0092ff"..MAJOR.."|r:", tostringall(...))
  end
end
