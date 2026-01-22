---@class WagoUICreator
local addon = select(2, ...)
local LAP = LibStub:GetLibrary("LibAddonProfiles")

local defaultSortOrder = {
  "Additional Addons",
  "Blizzard Edit Mode",
  "ElvUI",
  "ElvUI Private Profile",
  "ElvUI Account Settings",
  "ElvUI Style Filters",
  "ElvUI Aura Filters",
  "Details",
  "Plater",
  "Kui Nameplates",
  "BigWigs",
  "Bartender4",
  "Cell",
  "Cell Unit Frames",
  "Unhalted Unit Frames",
  "BetterCooldownManager",
  "Grid2",
  "ShadowedUnitFrames",
  "WeakAuras",
  "Echo Raid Tools",
  "Talent Loadout Ex",
  "OmniCC",
  "NameplateSCT",
  "SexyMap",
  "TipTac Reborn",
  "BugSack",
  "WarpDeplete",
  "Quartz",
  "OmniCD",
  "OmniCD Spell Editor",
  "BlizzHUDTweaks",
  "OmniBar",
  "HidingBar",
  "NameplateAuras",
  "MinimapStats",
  "MPlusTimer",
  "TargetedSpells",
  "AzortharionUI",
  "BetterBlizzFrames",
  "BetterBlizzPlates",
  "sArenaReloaded",
  "SenseiClassResourceBar",
  "CooldownManager",
  "Cooldown Manager Centered",
  "Enhance QoL",
  "Enhance QoL Unit Frames",
  "Enhance QoL Resource Bars",
  "DandersFrames",
  "Prat3",
  "Midnight Simple Unit Frames"
}

for _, lapModule in pairs(LAP:GetAllModules()) do
  if lapModule.needSpecialInterface then
    ---@type ModuleConfig | nil
    local moduleConfig = addon.ModuleFunctions.specialModules[lapModule.moduleName]
    if moduleConfig then --tlex is not currently active
      moduleConfig.sortIndex =
          addon:TableGetIndex(
            defaultSortOrder,
            function(value)
              return value == lapModule.moduleName
            end
          ) or 100
      addon.ModuleFunctions:InsertModuleConfig(moduleConfig)
    end
  else
    local function dropdownOptions(index)
      local res = {}
      if not lapModule:isLoaded() and not lapModule:needsInitialization() then
        return res
      end
      local profileKeys = lapModule:getProfileKeys()
      local currentProfileKey = lapModule:getCurrentProfileKey()
      return addon.ModuleFunctions:CreateDropdownOptions(
        lapModule.moduleName,
        index,
        res,
        profileKeys,
        currentProfileKey
      )
    end

    ---@type ModuleConfig
    local moduleConfig = {
      moduleName = lapModule.moduleName,
      lapModule = lapModule,
      dropdownOptions = dropdownOptions,
      sortIndex = addon:TableGetIndex(
        defaultSortOrder,
        function(value)
          return value == lapModule.moduleName
        end
      ) or 100
    }

    addon.ModuleFunctions:InsertModuleConfig(moduleConfig)
  end
end
