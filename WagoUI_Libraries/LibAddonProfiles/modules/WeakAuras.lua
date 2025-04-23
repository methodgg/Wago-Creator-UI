local _, loadingAddonNamespace = ...
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

local function decodeWeakAuraString(importString)
  local Serializer = LibStub:GetLibrary("AceSerializer-3.0Async")
  local LibDeflate = LibStub:GetLibrary("LibDeflateAsync")

  local _, _, encodeVersion, encoded = importString:find("^(!WA:%d+!)(.+)$")
  if (encodeVersion) then
    encodeVersion = tonumber(encodeVersion:match("%d+"))
  else
    encoded, encodeVersion = importString:gsub("^%!", "")
  end

  if (encoded) then
    local decoded = LibDeflate:DecodeForPrint(encoded)
    if not decoded then
      return
    end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    local _, deserialized
    if (encodeVersion == 2) then
      deserialized = private:LibSerializeDeserializeAsync(decompressed)
    else
      _, deserialized = Serializer:Deserialize(decompressed)
    end
    return deserialized
  end

  return nil
end

local function stripNonTransmissableFields(datum, fieldMap)
  for k, v in pairs(fieldMap) do
    if type(v) == "table" and type(datum[k]) == "table" then
      stripNonTransmissableFields(datum[k], v)
    elseif v == true then
      datum[k] = nil
    end
  end
end

local function CompressDisplay(data, version)
  -- Clean up custom trigger fields that are unused
  -- Those can contain lots of unnecessary data.
  -- Also we warn about any custom code, so removing unnecessary
  -- custom code prevents unnecessary warnings
  for triggernum, triggerData in ipairs(data.triggers) do
    local trigger, untrigger = triggerData.trigger, triggerData.untrigger

    if (trigger and trigger.type ~= "custom") then
      trigger.custom = nil
      trigger.customDuration = nil
      trigger.customName = nil
      trigger.customIcon = nil
      trigger.customTexture = nil
      trigger.customStacks = nil
      if (untrigger) then
        untrigger.custom = nil
      end
    end
  end
  local p_non_transmissable_fields = {
    controlledChildren = true,
    parent = true,
    authorMode = true,
    skipWagoUpdate = true,
    ignoreWagoUpdate = true,
    preferToUpdate = true,
    information = {
      saved = true
    }
  }

  -- For nested groups, we do transmit parent + controlledChildren
  local p_non_transmissable_fields_v2000 = {
    authorMode = true,
    skipWagoUpdate = true,
    ignoreWagoUpdate = true,
    preferToUpdate = true,
    information = {
      saved = true
    }
  }

  local copiedData = CopyTable(data)
  local non_transmissable_fields = version >= 2000 and p_non_transmissable_fields_v2000 or p_non_transmissable_fields
  stripNonTransmissableFields(copiedData, non_transmissable_fields)
  copiedData.tocversion = WeakAuras.BuildInfo
  return copiedData
end

---@format disable-next
local bytetoB64 = {
  [0] = "a", "b",  "c",  "d",  "e",  "f",  "g",  "h",  "i",  "j",  "k",  "l",  "m",  "n",  "o",  "p",  "q",
        "r", "s",  "t",  "u",  "v",  "w",  "x",  "y",  "z",  "A",  "B",  "C",  "D",  "E",  "F",  "G",  "H",
        "I", "J",  "K",  "L",  "M",  "N",  "O",  "P",  "Q",  "R",  "S",  "T",  "U",  "V",  "W",  "X",  "Y",
        "Z", "0", "1",  "2",  "3",  "4",  "5",  "6",  "7",  "8",  "9",  "(",  ")"
}

local function GenerateUniqueID()
  -- generates a unique random 11 digit number in base64
  local s = {}
  for i = 1, 11 do
    tinsert(s, bytetoB64[math.random(0, 63)])
  end
  return table.concat(s)
end

local function shouldInclude(data, includeGroups, includeLeafs)
  if data.controlledChildren then
    return includeGroups
  else
    return includeLeafs
  end
end

local function Traverse(data, includeSelf, includeGroups, includeLeafs)
  if includeSelf and shouldInclude(data, includeGroups, includeLeafs) then
    coroutine.yield(data)
  end

  if data.controlledChildren then
    for _, child in ipairs(data.controlledChildren) do
      Traverse(WeakAuras.GetData(child), true, includeGroups, includeLeafs)
    end
  end
end
local function TraverseSubGroups(data)
  return Traverse(data, false, true, false)
end

local function TraverseAllChildren(data)
  return Traverse(data, false, true, true)
end

-- All Children, excludes self
function PTraverseAllChildren(data)
  return coroutine.wrap(TraverseAllChildren), data
end

-- All groups, excludes self
function PTraverseSubGroups(data)
  return coroutine.wrap(TraverseSubGroups), data
end

local configForDeflate = { level = 5 }
local configForLS = {
  errorOnUnserializableType = false
}
---@param inTable table
---@return string
function TableToString(inTable)
  local LibDeflate = LibStub:GetLibrary("LibDeflateAsync")
  local serialized = private:LibSerializeSerializeAsyncEx(configForLS, inTable)
  local compressed = LibDeflate:CompressDeflate(serialized, configForDeflate)
  local encoded = "!WA:2!"
  encoded = encoded..LibDeflate:EncodeForPrint(compressed)
  return encoded
end

local collectedWagoIds = {}

local function purgeWago(data)
  if data.wagoID then
    if not collectedWagoIds[data.wagoID] then
      collectedWagoIds[data.wagoID] = data.id
    end
  end
  data.wagoID = nil
  --do not touch user provided urls
  local testString = "https://wago.io"
  if data.url and string.sub(data.url, 1, #testString) == testString then
    data.url = nil
  end
end

---@type LibAddonProfilesModule
local m = {
  moduleName = "WeakAuras",
  wagoId = "VBNBxKx5",
  oldestSupported = "5.17.0",
  addonNames = { "WeakAuras", "WeakAurasArchive", "WeakAurasModelPaths", "WeakAurasOptions", "WeakAurasTemplates" },
  icon = C_AddOns.GetAddOnMetadata("WeakAuras", "IconTexture"),
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
    local data = decodeWeakAuraString(profileString)
    if (data and data.d) then
      return data
    end
  end,
  importProfile = function(self, profileString, profileKey, fromIntro)
    local data = decodeWeakAuraString(profileString)
    WeakAuras.Import(data)
  end,
  exportProfile = function(self, profileKey)
    if type(profileKey) ~= "table" then return end
    collectedWagoIds = {}
    local displayIds = {}
    local blockedIds = {}
    for id, data in pairs(profileKey) do
      if not data.blocked then
        displayIds[id] = true
      else
        blockedIds[id] = true
      end
    end
    local exportStrings = {}
    for id in pairs(displayIds) do
      local exportString = self:exportGroup(id, blockedIds)
      if exportString then
        exportStrings[id] = exportString
      end
    end
    return exportStrings
  end,
  getCollectedWagoIds = function(self)
    return collectedWagoIds
  end,
  exportOptions = {
    purgeWago = false
  },
  setExportOptions = function(self, options)
    for k, v in pairs(options) do
      self.exportOptions[k] = v
    end
  end,
  exportGroup = function(self, profileKey, blockedIds)
    local id = profileKey
    local original = WeakAuras.GetData(id)
    local data = private:DeepCopyAsync(original)

    if (data) then
      data.uid = data.uid or GenerateUniqueID()
      -- Check which transmission version we want to use
      local version = 1421
      for child in PTraverseSubGroups(data) do
        version = 2000
        break
      end
      local transmitData = CompressDisplay(data, version)
      local transmit = {
        m = "d",
        d = transmitData,
        v = version,
        s = WeakAuras.versionString
      }
      if (data.controlledChildren) then
        transmit.c = {}
        local uids = {}
        local index = 1
        for child in PTraverseAllChildren(data) do
          if child.uid then
            if uids[child.uid] then
              child.uid = GenerateUniqueID()
            else
              uids[child.uid] = true
            end
          else
            child.uid = GenerateUniqueID()
          end
          transmit.c[index] = CompressDisplay(child, version)
          index = index + 1
          coroutine.yield()
        end
      end
      if self.exportOptions.purgeWago then
        purgeWago(transmit.d)
        if transmit.c then
          for _, child in ipairs(transmit.c) do
            purgeWago(child)
          end
        end
      end
      -- remove blocked data and remove blocked from controlled children
      if transmit.c then
        for k, child in pairs(transmit.c) do
          if blockedIds and blockedIds[child.id] then
            tremove(transmit.c, k)
          elseif child.controlledChildren then
            for i, controlledChild in pairs(child.controlledChildren) do
              if blockedIds and blockedIds[controlledChild] then
                tremove(child.controlledChildren, i)
              end
            end
          end
        end
      end
      return TableToString(transmit)
    else
      return nil
    end
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
      local dataA = decodeWeakAuraString(tableA[groupIdx])
      local dataB = decodeWeakAuraString(tableB[groupIdx])
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
