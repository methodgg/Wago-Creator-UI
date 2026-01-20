---@class WagoUICreator
local addon = select(2, ...)
local L = addon.L
local LAP = LibStub:GetLibrary("LibAddonProfiles")


---@param lapModule LibAddonProfilesModule
function addon:AddAlternateProfile(lapModule)
  local currentPack = addon:GetCurrentPackStashed()
  if not currentPack.alternateProfiles then
    currentPack.alternateProfiles = {
      profileKeys = {},
      profiles = {},
      profileMetadata = {},
    }
    for _, config in pairs(addon.moduleConfigs) do
      WagoUICreatorDB.profileKeys[config.name] = WagoUICreatorDB.profileKeys[config.name] or {}
      WagoUICreatorDB.profiles[config.name] = WagoUICreatorDB.profiles[config.name] or {}
    end
  end
end

---@param lapModule LibAddonProfilesModule
---@param alternateIndex number
function addon:RemoveAlternateProfile(lapModule, alternateIndex)

end
