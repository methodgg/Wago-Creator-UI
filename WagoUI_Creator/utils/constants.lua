---@type string
local addonName = ...
---@class WagoUICreator
local addon = select(2, ...)
_G[addonName] = addon
local L = addon.L

addon.moduleConfigs = {}

---@type AddonResolutions
addon.resolutions = {
  entries = {
    {
      value = "any",
      displayNameLong = L["Any Resolution"],
      displayNameShort = L["Any Resolution"],
      width = nil,
      height = nil,
      defaultEnabled = true
    },
    {
      value = "1080",
      displayNameLong = "1920x1080",
      displayNameShort = "1080p",
      width = 1920,
      height = 1080,
      defaultEnabled = false
    },
    {
      value = "1440",
      displayNameLong = "2560x1440",
      displayNameShort = "1440p",
      width = 2560,
      height = 1440,
      defaultEnabled = false
    },
    {
      value = "2160",
      displayNameLong = "3840x2160",
      displayNameShort = "4k",
      width = 3840,
      height = 2160,
      defaultEnabled = false
    }
  },
  defaultValue = "any"
}

addon.dbDefaults = {
  debug = false,
  autoStart = false,
  hasLoggedInEver = false,
  anchorTo = "CENTER",
  anchorFrom = "CENTER",
  xoffset = 0,
  yoffset = 0,
  config = {},
  exportOptions = {
    ["WeakAuras"] = {
      purgeWago = true
    }
  },
  creatorUI = {},
  profileRemovals = {}
}

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
addon.colorRGB = {
  --used by status bar
  r = 201 / 255,
  g = 180 / 255,
  b = 0 / 255
}
addon.slashPrefixes = {
  "/wagoc",
  "/wagocreator",
  "/wuic"
}
addon.ADDON_WIDTH = 1000
addon.ADDON_HEIGHT = 800

addon.externalLinks = {
  {
    name = "GitHub",
    tooltip = L["Open an issue on GitHub"],
    url = "https://github.com/methodgg/Wago-Creator-UI"
  }
  -- {
  --   name = "Discord",
  --   tooltip = L["Provide feedback in Discord"],
  --   url = "<Placeholder Discord Link>"
  -- }
}
