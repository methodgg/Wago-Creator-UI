local addonName, addon = ...
_G[addonName] = addon
local L = addon.L

addon.moduleConfigs = {}

function addon:SetUpDB()
  UIManagerDB = UIManagerDB or {}
  UIManagerDB.profileKeys = UIManagerDB.profileKeys or {}
  UIManagerDB.profiles = UIManagerDB.profiles or {}
  UIManagerDB.disabledModules = UIManagerDB.disabledModules or {}
  for _, config in pairs(addon.moduleConfigs) do
    UIManagerDB.profileKeys[config.name] = UIManagerDB.profileKeys[config.name] or {}
    UIManagerDB.profiles[config.name] = UIManagerDB.profiles[config.name] or {}
  end
  addon.db = UIManagerDB
end

addon.color = "FFE2CB00"
addon.colorRGB = { --used by status bar
  r = 201 / 255,
  g = 180 / 255,
  b = 0 / 255,
}
addon.slashPrefixes = {
  "/uim", "/uimanager",
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
