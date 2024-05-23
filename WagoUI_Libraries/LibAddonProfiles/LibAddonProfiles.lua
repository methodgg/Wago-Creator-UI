local loadingAddon, loadingAddonNamespace = ...;
local MAJOR = "LibAddonProfiles";
local MINOR = 1;
local LibAddonProfiles = LibStub:NewLibrary(MAJOR, MINOR);
if LibAddonProfiles then
  wipe(LibAddonProfiles)
  local LibAddonProfilesInternal = {
    modules = {}
  }

  function loadingAddonNamespace:GetLibAddonProfilesInternal()
    return LibAddonProfilesInternal
  end

  function LibAddonProfiles:GetModule(moduleName)
    return LibAddonProfilesInternal.modules[moduleName]
  end

  function LibAddonProfiles:GetAllModules()
    return LibAddonProfilesInternal.modules
  end

  function LibAddonProfiles:GenericEncode(profileKey, profile)
    return LibAddonProfilesInternal:GenericEncode(profileKey, profile)
  end

  function LibAddonProfiles:GenericDecode(profileKey)
    return LibAddonProfilesInternal:GenericDecode(profileKey)
  end

  function LibAddonProfilesInternal:PrintError(...)
    print("|cff0092ff"..MAJOR.."|r:", tostringall(...));
  end
end
