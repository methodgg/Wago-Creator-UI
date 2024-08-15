---@class LAPLoadingNamespace
local loadingAddonNamespace = select(2, ...)
local MAJOR = "LibAddonProfiles"
local MINOR = 1

---@class LibAddonProfiles
local LibAddonProfiles = LibStub:NewLibrary(MAJOR, MINOR);

if LibAddonProfiles then
  wipe(LibAddonProfiles)

  ---@class LibAddonProfilesPrivate : table
  ---@field modules table<string, LibAddonProfilesModule>
  local LibAddonProfilesInternal = {
    modules = {}
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

  --- Checks if an addon can be enabled. AddOns that can be enabled will be enabled after a UI reload.
  --- Checks the first entry in the list of supplied AddOn names
  ---@param addonNames table<number, string> | nil Only first entry is checked
  ---@return boolean
  function LibAddonProfiles:CanEnableAddOn(addonNames)
    return LibAddonProfilesInternal:CanEnableAddOn(addonNames)
  end

  ---Enables a list of AddOns. AddOns that can be enabled will be enabled after a UI reload.
  ---@param addonNames table<number, string>
  function LibAddonProfiles:EnableAddOns(addonNames)
    return LibAddonProfilesInternal:EnableAddOns(addonNames)
  end

  ---@param ... any
  function LibAddonProfilesInternal:PrintError(...)
    print("|cff0092ff"..MAJOR.."|r:", tostringall(...))
  end
end
