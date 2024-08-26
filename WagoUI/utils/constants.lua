---@class WagoUI
local addon = select(2, ...)
local L = addon.L

---If there are more than 4 resolutions here the choice buttons need to be updated
---@see addButtonToPage

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

addon.color = "FFC1272D"
addon.colorRGB = {
  193 / 255,
  39 / 255,
  45 / 255
}
addon.dbKey = "WagoUIDB"
addon.dbCKey = "WagoUICDB"
addon.slashPrefixes = {
  "/wago",
  "/wui",
  "/wagoui"
}
addon.ADDON_WIDTH = 800
addon.ADDON_HEIGHT = 600
addon.dbDefaults = {
  debug = false,
  autoStart = false,
  anchorTo = "CENTER",
  anchorFrom = "CENTER",
  xoffset = 0,
  yoffset = 0,
  config = {},
  introEnabled = true,
  introState = {
    currentPage = "WelcomePage"
  },
  introImportState = {},
  importedProfiles = {},
  classColoredCharacters = {},
  minimap = {
    hide = false,
    compartmentHide = false
  },
  latestSeenReleasenotes = {}
}

addon.state = {}

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
