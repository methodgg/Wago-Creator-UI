local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

-- Each route ships as its own group record, keyed by its MDT uid. MDT lists the routes of an import in its own window,
-- where the player confirms them; several routes go into that window together.

local MAX_LABEL = 120

local function call(method, ...)
  local api = MythicDungeonToolsAPI
  if not api then return end
  local function results(ok, ...)
    if ok then return ... end
  end
  return results(xpcall(api[method], geterrorhandler(), api, ...))
end

-- Pack record names are limited to 120 bytes; cut on a character boundary.
local function shorten(text)
  if #text <= MAX_LABEL then return text end
  local cut = MAX_LABEL
  while cut > 0 and text:byte(cut + 1) and text:byte(cut + 1) >= 128 and text:byte(cut + 1) < 192 do cut = cut - 1 end
  return text:sub(1, cut)
end

-- Trimmed like pack record names, so a saved name matches the next label.
local function routeLabel(route)
  local text = shorten((route.dungeonName or "?") .. ": " .. route.name)
  return (text:match("^%s*(.-)%s*$"))
end

-- Listing routes loads MDT's interface addon; in combat the last list stands in.
local lastRoutes
local function shareableRoutes()
  if InCombatLockdown() and lastRoutes then return lastRoutes end
  lastRoutes = call("GetShareableRoutes") or {}
  return lastRoutes
end

local function finishCallback(callback)
  return callback and function(imported) callback(imported or {}) end
end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Mythic Dungeon Tools",
  wagoId = "rN4VrAKD",
  flavors = { "retail" },
  oldestSupported = "6.3.15",
  addonNames = { "MythicDungeonTools" },
  icon = C_AddOns.GetAddOnMetadata("MythicDungeonTools", "IconTexture"),
  slash = "/mdt",
  needReloadOnImport = false,
  needProfileKey = false,
  preventRename = false,
  willOverrideProfile = false,
  nonNativeProfileString = false,
  needSpecialInterface = true,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("MythicDungeonTools")
    return loaded
  end,
  -- Versions before the route API cannot share routes.
  isUpdated = function(self)
    return MythicDungeonToolsAPI ~= nil and MythicDungeonToolsAPI.ImportRoutes ~= nil and private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    call("ShowInterface", true)
  end,
  -- Every route with pulls, keyed by uid, in MDT's order: newest season first, then by dungeon. Also the route's own
  -- name and its author, whose class colors the name. currentSeason marks the season selected in MDT.
  getAuras = function(self)
    local routes = {}
    for index, route in ipairs(shareableRoutes()) do
      routes[route.uid] = {
        label = routeLabel(route), category = route.dungeonName, categoryIcon = route.dungeonIcon, order = index,
        icon = self.icon,
        name = route.name, author = route.author, authorClass = route.authorClass,
        currentSeason = route.currentSeason,
      }
    end
    return routes
  end,
  getGroupLabel = function(self, profileKey)
    for _, route in ipairs(shareableRoutes()) do
      if route.uid == profileKey then return routeLabel(route) end
    end
  end,
  isDuplicate = function(self, profileKey)
    return false
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    local routes = call("DecodeRoutes", profileString)
    return routes and routes[1] and routes[1].uid
  end,
  importInteractive = function(self, profileString, callback)
    local opened, reason = call("ImportRoutes", profileString, callback and function(imported)
      callback(next(imported or {}) ~= nil)
    end)
    self.importFailureReason = not opened and ("Mythic Dungeon Tools could not open the import: " .. (reason or "unknown error") .. ".")
      or nil
    return opened == true, reason
  end,
  importInteractiveGroups = function(self, profileStrings, callback)
    local opened, reason = call("ImportRoutes", profileStrings, finishCallback(callback))
    self.importFailureReason = not opened and ("Mythic Dungeon Tools could not open the import: " .. (reason or "unknown error") .. ".")
      or nil
    return opened == true, reason
  end,
  -- The player confirms every import in MDT's import window.
  importProfile = function(self, profileString, profileKey, fromIntro)
    return (self:importInteractive(profileString))
  end,
  exportGroup = function(self, profileKey)
    if type(profileKey) ~= "string" then return end
    return call("ExportRoutes", profileKey)
  end,
  exportProfile = function(self, profileKey)
    return self:exportGroup(profileKey)
  end,
  -- MDT ignores the version that exported a route, so updating MDT alone never marks a route as changed.
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then return false end
    return call("AreRouteStringsEqual", profileStringA, profileStringB) == true
  end,
}

private.modules[m.moduleName] = m
