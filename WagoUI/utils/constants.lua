local addonName, addon = ...;
local L = addon.L

addon.color = "FFC1272D";
addon.colorRGB = {
  193 / 255,
  39 / 255,
  45 / 255,
}
addon.dbKey = "WagoUIDB"
addon.slashPrefixes = {
  "/wago", "/wui", "/wagoui"
}
addon.ADDON_WIDTH = 800
addon.ADDON_HEIGHT = 600
addon.dbDefaults = {
  anchorTo = "CENTER",
  anchorFrom = "CENTER",
  xoffset = 0,
  yoffset = 0,
  config = {},
  introEnabled = true,
};

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
