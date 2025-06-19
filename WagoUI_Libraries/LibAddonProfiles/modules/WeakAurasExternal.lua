local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Wago WeakAuras",
  wagoId = "VBNBxKx5",
  oldestSupported = "5.17.0",
  addonNames = { "WeakAuras", "WeakAurasArchive", "WeakAurasModelPaths", "WeakAurasOptions", "WeakAurasTemplates" },
  icon = [[Interface\AddOns\WagoUI_Creator\media\wagoLogo512]],
  slash = "/wa",
  needReloadOnImport = false,
  needProfileKey = false,
  preventRename = false,
  willOverrideProfile = false,
  nonNativeProfileString = false,
  needSpecialInterface = true,
  isLoaded = function(self)
    return WeakAuras and true or false
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    if not SlashCmdList["WEAKAURAS"] then return end
    SlashCmdList["WEAKAURAS"]("")
  end,
  closeConfig = function(self)
    WeakAurasOptions:Hide()
  end,
  isDuplicate = function(self, profileKey)
    return false
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
  end,
  exportProfile = function(self, profileKey)
    if type(profileKey) ~= "table" then return end
    local displayIds = profileKey
    local wagoSlugs = {}
    for id in pairs(displayIds) do
      local slug = self:exportGroup(id)
      if slug then
        wagoSlugs[id] = slug
      end
    end
    return wagoSlugs
  end,
  exportGroup = function(self, profileKey)
    local id = profileKey
    local original = WeakAuras.GetData(id)
    if not original.url then return end
    local wagoSlug = original.url:match("https://wago.io/([^/%s]+)")
    return wagoSlug
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not tableA or not tableB then return false end
    return private:DeepCompareAsync(tableA, tableB)
  end,
}

private.modules[m.moduleName] = m
