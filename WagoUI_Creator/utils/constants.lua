local addonName, addon = ...
_G[addonName] = addon
local L = addon.L

addon.moduleConfigs = {}

function addon:SetUpDB()
  WagoUICreatorDB = WagoUICreatorDB or {}
  WagoUICreatorDB.profileKeys = WagoUICreatorDB.profileKeys or {}
  WagoUICreatorDB.profiles = WagoUICreatorDB.profiles or {}
  WagoUICreatorDB.disabledModules = WagoUICreatorDB.disabledModules or {}
  for _, config in pairs(addon.moduleConfigs) do
    WagoUICreatorDB.profileKeys[config.name] = WagoUICreatorDB.profileKeys[config.name] or {}
    WagoUICreatorDB.profiles[config.name] = WagoUICreatorDB.profiles[config.name] or {}
  end
  addon.db = WagoUICreatorDB
end

addon.color = "FFE2CB00"
addon.colorRGB = { --used by status bar
  r = 201 / 255,
  g = 180 / 255,
  b = 0 / 255,
}
addon.slashPrefixes = {
  "/wuic", "/wagouicreator", "/wagoc",
}
addon.ADDON_WIDTH = 1000
addon.ADDON_HEIGHT = 800

addon.externalLinks = {
  {
    name = "GitHub",
    tooltip = L["Open an issue on GitHub"],
    url = "<Placeholder GitHub Link>",
  },
  {
    name = "Discord",
    tooltip = L["Provide feedback in Discord"],
    url = "<Placeholder Discord Link>",
  },
}
