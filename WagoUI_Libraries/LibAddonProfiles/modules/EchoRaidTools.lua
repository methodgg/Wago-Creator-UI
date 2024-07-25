local _, loadingAddonNamespace = ...;
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal();
if (not private) then return; end

---@return boolean
local isLoaded = function()
  local loaded = C_AddOns.IsAddOnLoaded("EchoRaidTools")
  return loaded
end

---@return boolean
local needsInitialization = function()
  return false
end

---@return nil
local openConfig = function()
  SlashCmdList["ACECONSOLE_ECHORT"]()
end

---@return nil
local closeConfig = function()
  EchoRaidToolsMainFrame:Hide()
end

---@param profileKey string
---@return boolean
local isDuplicate = function(profileKey)
  return true
end

---@param profileString string
---@param profileKey string | nil
---@param profileData table | nil
---@param rawData table | nil
---@return string | nil
local testImport = function(profileString, profileKey, profileData, rawData)
  local _, _, isEcho, module, groupType, encoded = string.find(profileString, "^(!ECHO):(.+):(%d+)!(.+)$")
  return (isEcho and module == "CD" and groupType == "1" or groupType == "2") and "" or nil
end

---@param profileString string
---@param profileKey string
local importProfile = function(profileString, profileKey, fromIntro)
  EchoCooldowns.importStringExternal(profileString)
end

---@param  id number | nil
---@return string | nil
local exportGroup = function(id)
  if not id then return end
  return EchoCooldowns.getExportStringForGroupIndex(id)
end

---@param groupNames table | nil
---@return table | nil
local exportProfile = function(groupNames)
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
end

local function decodeString(importString)
  local LibDeflate = LibStub:GetLibrary("LibDeflateAsync");
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

---@param profileTableA table
---@param profileTableB table
---@return boolean
---@return table
---@return table
local areProfileStringsEqual = function(profileTableA, profileTableB)
  local allEqual = true
  local changedEntries = {}
  local removedEntries = {}
  local inBoth = {}

  if not profileTableA or not profileTableB then
    return false, profileTableB, removedEntries
  end

  for groupIdx in pairs(profileTableB) do
    if profileTableA[groupIdx] then
      inBoth[groupIdx] = true
    else
      allEqual = false
      changedEntries[groupIdx] = true
    end
  end

  for groupIdx in pairs(profileTableA) do
    if profileTableB[groupIdx] then
      inBoth[groupIdx] = true
    else
      allEqual = false
      removedEntries[groupIdx] = true
    end
  end

  --check in both
  for groupIdx in pairs(inBoth) do
    local dataA = decodeString(profileTableA[groupIdx])
    local dataB = decodeString(profileTableB[groupIdx])
    if dataA and dataB then
      if not private:DeepCompareAsync(dataA, dataB) then
        allEqual = false
        changedEntries[groupIdx] = true
      end
    end
  end

  return allEqual, changedEntries, removedEntries
end

---@type LibAddonProfilesModule
local m = {
  moduleName = "Echo Raid Tools",
  icon = [[Interface\AddOns\EchoRaidTools\assets\textures\ELp3.tga]],
  slash = "/echort",
  needReloadOnImport = false,
  needsInitialization = needsInitialization,
  needProfileKey = false,
  isLoaded = isLoaded,
  openConfig = openConfig,
  closeConfig = closeConfig,
  isDuplicate = isDuplicate,
  testImport = testImport,
  importProfile = importProfile,
  exportProfile = exportProfile,
  exportGroup = exportGroup,
  areProfileStringsEqual = areProfileStringsEqual,
}
private.modules[m.moduleName] = m
