local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

local function call(method, ...)
  if not ForeverAurasAPI then return end
  local results = { xpcall(ForeverAurasAPI[method], geterrorhandler(), ForeverAurasAPI, ...) }
  if results[1] then return unpack(results, 2) end
end

---@type LibAddonProfilesModule
local m = {
  moduleName = "ForeverAuras",
  wagoId = "4N2kJZ6L",
  flavors = { "forever" },
  oldestSupported = "0.90.25",
  addonNames = { "ForeverAuras", "ForeverAurasArchive", "ForeverAurasModelPaths", "ForeverAurasOptions", "ForeverAurasTemplates" },
  icon = C_AddOns.GetAddOnMetadata("ForeverAuras", "IconTexture"),
  slash = "/fa",
  needReloadOnImport = false,
  needProfileKey = false,
  preventRename = false,
  willOverrideProfile = false,
  nonNativeProfileString = false,
  needSpecialInterface = true,
  isLoaded = function(self)
    return C_AddOns.IsAddOnLoaded("ForeverAuras")
  end,
  -- Versions before the API cannot share auras.
  isUpdated = function(self)
    return ForeverAurasAPI ~= nil and private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    call("OpenConfig")
  end,
  closeConfig = function(self)
    call("CloseConfig")
  end,
  getConfigFrame = function(self)
    return call("GetConfigFrame")
  end,
  getAuras = function(self)
    return call("GetAuras") or {}
  end,
  isDuplicate = function(self, profileKey)
    return false
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    local data = call("DecodeAuraString", profileString)
    return data and data.d and data
  end,
  importInteractive = function(self, profileString, callback)
    local opened, reason = call("ImportAura", profileString, callback)
    self.importFailureReason = not opened and ("ForeverAuras could not open the import: " .. (reason or "unknown error") .. ".")
      or nil
    return opened == true, reason
  end,
  -- The player confirms every import in ForeverAuras' import window.
  importProfile = function(self, profileString, profileKey, fromIntro)
    return (self:importInteractive(profileString))
  end,
  exportGroup = function(self, profileKey, blockedIds)
    return call("ExportAura", profileKey, blockedIds)
  end,
  exportProfile = function(self, profileKey)
    if type(profileKey) ~= "string" then return end
    return self:exportGroup(profileKey)
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    if not profileStringA or not profileStringB then return false end
    local dataA, dataB = call("DecodeAuraString", profileStringA), call("DecodeAuraString", profileStringB)
    if not dataA or not dataB then return false end
    return private:DeepCompareAsync(dataA, dataB)
  end,
}

private.modules[m.moduleName] = m
