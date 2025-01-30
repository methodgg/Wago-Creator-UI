local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

local function decodeString(importString)
  local LibDeflate = LibStub:GetLibrary("LibDeflateAsync")
  local Serializer = LibStub:GetLibrary("AceSerializer-3.0Async")
  local _, _, isEcho, module, groupType, encoded = string.find(importString, "^(!ECHO):(.+):(%d+)!(.+)$")
  if isEcho and module == "CD" then
    local decoded, decompressed, success, deserialized
    if groupType == "1" then
      decoded = LibDeflate:DecodeForPrint(encoded)
      decompressed = LibDeflate:DecompressDeflate(decoded)
      success, deserialized = Serializer:Deserialize(decompressed)
    elseif groupType == "2" then
      decoded = LibDeflate:DecodeForPrint(encoded)
      decompressed = LibDeflate:DecompressDeflate(decoded)
      success, deserialized = Serializer:Deserialize(decompressed)
    end
    return deserialized
  end
end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Echo Raid Tools",
  wagoId = "none",
  oldestSupported = "1.5.8",
  addonNames = { "EchoRaidTools" },
  icon = C_AddOns.GetAddOnMetadata("EchoRaidTools", "IconTexture"),
  slash = "/echort",
  needReloadOnImport = false,
  needProfileKey = false,
  preventRename = false,
  willOverrideProfile = false,
  nonNativeProfileString = false,
  needSpecialInterface = true,
  isLoaded = function(self)
    local loaded = C_AddOns.IsAddOnLoaded("EchoRaidTools")
    return loaded
  end,
  isUpdated = function(self)
    return private:GenericVersionCheck(self)
  end,
  needsInitialization = function(self)
    return false
  end,
  openConfig = function(self)
    if not SlashCmdList["ACECONSOLE_ECHORT"] then return end
    SlashCmdList["ACECONSOLE_ECHORT"]()
  end,
  closeConfig = function(self)
    EchoRaidToolsMainFrame:Hide()
  end,
  isDuplicate = function(self, profileKey)
    return true
  end,
  testImport = function(self, profileString, profileKey, profileData, rawData, moduleName)
    local _, _, isEcho, module, groupType, encoded = string.find(profileString, "^(!ECHO):(.+):(%d+)!(.+)$")
    return (isEcho and module == "CD" and groupType == "1" or groupType == "2") and "" or nil
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    EchoCooldowns.importStringExternal(profileString)
  end,
  exportGroup = function(self, profileKey)
    if not profileKey then return end
    return EchoCooldowns.getExportStringForGroupIndex(profileKey)
  end,
  exportProfile = function(self, profileKey)
    local groupNames = profileKey
    if type(groupNames) ~= "table" then return end
    if not groupNames then return end
    local res = {}
    for id, group in pairs(EchoRaidToolsDB.Cooldowns.groups) do
      if groupNames[group.name] then
        local exportString = EchoCooldowns.getExportStringForGroupIndex(id)
        if exportString then
          res[group.name] = exportString
        end
      end
    end
    return res
  end,
  areProfileStringsEqual = function(self, profileStringA, profileStringB, tableA, tableB)
    local allEqual = true
    local changedEntries = {}
    local removedEntries = {}
    local inBoth = {}

    if not tableA or not tableB then
      return false, tableB, removedEntries
    end

    for groupIdx in pairs(tableB) do
      if tableA[groupIdx] then
        inBoth[groupIdx] = true
      else
        allEqual = false
        changedEntries[groupIdx] = true
      end
    end

    for groupIdx in pairs(tableA) do
      if tableB[groupIdx] then
        inBoth[groupIdx] = true
      else
        allEqual = false
        removedEntries[groupIdx] = true
      end
    end

    --check in both
    for groupIdx in pairs(inBoth) do
      local dataA = decodeString(tableA[groupIdx])
      local dataB = decodeString(tableB[groupIdx])
      if dataA and dataB then
        if not private:DeepCompareAsync(dataA, dataB) then
          allEqual = false
          changedEntries[groupIdx] = true
        end
      end
    end

    return allEqual, changedEntries, removedEntries
  end
}

private.modules[m.moduleName] = m
