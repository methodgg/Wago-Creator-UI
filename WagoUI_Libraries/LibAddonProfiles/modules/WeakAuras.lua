local _, loadingAddonNamespace = ...;
---@type LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal();
if (not private) then return; end

---@return boolean
local isLoaded = function()
  return WeakAuras and true or false
end

---@return boolean
local needsInitialization = function()
  return false
end

---@return nil
local openConfig = function()
  SlashCmdList["WEAKAURAS"]("")
end

---@return nil
local closeConfig = function()
  WeakAurasOptions:Hide()
end

---@param profileKey string
---@return boolean
local isDuplicate = function(profileKey)
  return false
end

-- START duplication, code from WA addon
local function privateAddParents(data)
  local parent = data.parent
  if (parent) then
    local parentData = WeakAuras.GetData(parent)
    WeakAuras.Add(parentData)
    privateAddParents(parentData)
  end
end

local function privateDuplicateAura(data, newParent, massEdit, targetIndex)
  local base_id = data.id.." "
  local num = 2

  -- if the old id ends with a number increment the number
  local matchName, matchNumber = string.match(data.id, "^(.-)(%d*)$")
  matchNumber = tonumber(matchNumber)
  if (matchName ~= "" and matchNumber ~= nil) then
    base_id = matchName
    num = matchNumber + 1
  end

  local new_id = base_id..num
  while (WeakAuras.GetData(new_id)) do
    new_id = base_id..num
    num = num + 1
  end

  local newData = CopyTable(data)
  newData.id = new_id
  newData.parent = nil
  newData.uid = WeakAuras.GenerateUniqueID()
  if newData.controlledChildren then
    newData.controlledChildren = {}
  end
  WeakAuras.Add(newData)
  -- WeakAuras.NewDisplayButton(newData, massEdit)
  if (newParent or data.parent) then
    local parentId = newParent or data.parent
    local parentData = WeakAuras.GetData(parentId)
    local index
    if targetIndex then
      index = targetIndex
    elseif newParent then
      index = #parentData.controlledChildren + 1
    else
      index = tIndexOf(parentData.controlledChildren, data.id) + 1
    end
    if (index) then
      tinsert(parentData.controlledChildren, index, newData.id)
      newData.parent = parentId
      WeakAuras.Add(newData)
      WeakAuras.Add(parentData)
      privateAddParents(parentData)
      -- ignore UI stuff, we don't need
    end
  end
  return newData
end

local function duplicateGroups(sourceParent, targetParent, mapping)
  for index, childId in pairs(sourceParent.controlledChildren) do
    local childData = WeakAuras.GetData(childId)
    if childData.controlledChildren then
      local newChildGroup = privateDuplicateAura(childData, targetParent.id)
      mapping[childData] = newChildGroup
      duplicateGroups(childData, newChildGroup, mapping)
    end
  end
end

local function duplicateAuras(sourceParent, targetParent, mapping)
  for index, childId in pairs(sourceParent.controlledChildren) do
    local childData = WeakAuras.GetData(childId)
    if childData.controlledChildren then
      duplicateAuras(childData, mapping[childData], mapping)
    else
      privateDuplicateAura(childData, targetParent.id, true, index)
    end
  end
end

local function duplicateDisplay(id)
  local data = WeakAuras.GetData(id)
  if (WeakAuras.IsImporting()) then return end;
  if data.controlledChildren then
    local newGroup = privateDuplicateAura(data)
    local mapping = {}
    -- This builds the group skeleton
    duplicateGroups(data, newGroup, mapping)
    -- And this fills in the leafs
    duplicateAuras(data, newGroup, mapping)
  end
end
-- END duplication

local function decodeWeakAuraString(importString)
  local Serializer = LibStub:GetLibrary("AceSerializer-3.0Async")
  local LibDeflate = LibStub:GetLibrary("LibDeflateAsync");

  local _, _, encodeVersion, encoded = importString:find("^(!WA:%d+!)(.+)$");
  if (encodeVersion) then
    encodeVersion = tonumber(encodeVersion:match("%d+"));
  else
    encoded, encodeVersion = importString:gsub("^%!", "");
  end

  if (encoded) then
    local decoded = LibDeflate:DecodeForPrint(encoded);
    if not decoded then return end
    local decompressed = LibDeflate:DecompressDeflate(decoded);
    local _, deserialized;
    if (encodeVersion == 2) then
      deserialized = private:LibSerializeDeserializeAsync(decompressed);
    else
      _, deserialized = Serializer:Deserialize(decompressed);
    end
    return deserialized;
  end

  return nil;
end

---@param profileString string
---@param profileKey string | nil
---@param profileData table | nil
---@param rawData table | nil
---@return table | nil --decoded WA table
local testImport = function(profileString, profileKey, profileData, rawData)
  local data = decodeWeakAuraString(profileString);
  if (data and data.d) then
    return data
  end
end

---@param profileString string
---@param profileKey string
local importProfile = function(profileString, profileKey, fromIntro)
  local data = decodeWeakAuraString(profileString);
  WeakAuras.Import(data);
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
      trigger.custom = nil;
      trigger.customDuration = nil;
      trigger.customName = nil;
      trigger.customIcon = nil;
      trigger.customTexture = nil;
      trigger.customStacks = nil;
      if (untrigger) then
        untrigger.custom = nil;
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
  local non_transmissable_fields = version >= 2000 and p_non_transmissable_fields_v2000
      or p_non_transmissable_fields
  stripNonTransmissableFields(copiedData, non_transmissable_fields)
  copiedData.tocversion = WeakAuras.BuildInfo
  return copiedData;
end

---@format disable-next
local bytetoB64 = {
  [0]="a","b","c","d","e","f","g","h",
  "i","j","k","l","m","n","o","p",
  "q","r","s","t","u","v","w","x",
  "y","z","A","B","C","D","E","F",
  "G","H","I","J","K","L","M","N",
  "O","P","Q","R","S","T","U","V",
  "W","X","Y","Z","0","1","2","3",
  "4","5","6","7","8","9","(",")"
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

function TableToString(inTable)
  local LibDeflate = LibStub:GetLibrary("LibDeflateAsync");
  local serialized = private:LibSerializeSerializeAsyncEx(configForLS, inTable)
  local compressed = LibDeflate:CompressDeflate(serialized, configForDeflate)
  local encoded = "!WA:2!"
  encoded = encoded..LibDeflate:EncodeForPrint(compressed)
  return encoded
end

local exportOptions = {
  purgeWago = false
}
local setExportOptions = function(options)
  for k, v in pairs(options) do
    exportOptions[k] = v
  end
end

local function purgeWago(data)
  data.wagoID = nil
  --do not touch user provided urls
  local testString = "https://wago.io"
  if data.url and string.sub(data.url, 1, #testString) == testString then
    data.url = nil
  end
end

---@param id string | nil
---@return string | nil
local exportGroup = function(id)
  local data = WeakAuras.GetData(id);

  if (data) then
    data.uid = data.uid or GenerateUniqueID()
    -- Check which transmission version we want to use
    local version = 1421
    for child in PTraverseSubGroups(data) do
      version = 2000
      break;
    end
    local transmitData = CompressDisplay(data, version);
    local transmit = {
      m = "d",
      d = transmitData,
      v = version,
      s = WeakAuras.versionString
    };
    if (data.controlledChildren) then
      transmit.c = {};
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
        transmit.c[index] = CompressDisplay(child, version);
        index = index + 1
        coroutine.yield()
      end
    end
    if exportOptions.purgeWago then
      purgeWago(transmit.d)
      if transmit.c then
        for _, child in ipairs(transmit.c) do
          purgeWago(child)
        end
      end
    end
    return TableToString(transmit);
  else
    return "";
  end
end

---@param displayIds table | nil
---@return table | nil table of export strings
local exportAllDisplays = function(displayIds)
  local exportStrings = {}
  if displayIds then
    for id in pairs(displayIds) do
      local exportString = exportGroup(id)
      if exportString then
        exportStrings[id] = exportString
      end
    end
  end
  return exportStrings
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
    local dataA = decodeWeakAuraString(profileTableA[groupIdx])
    local dataB = decodeWeakAuraString(profileTableB[groupIdx])
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
  moduleName = "WeakAuras",
  icon = [[Interface\AddOns\WeakAuras\Media\Textures\icon]],
  slash = "/wa",
  needReloadOnImport = false,
  needsInitialization = needsInitialization,
  needProfileKey = false,
  isLoaded = isLoaded,
  openConfig = openConfig,
  closeConfig = closeConfig,
  isDuplicate = isDuplicate,
  testImport = testImport,
  importProfile = importProfile,
  exportProfile = exportAllDisplays,
  setExportOptions = setExportOptions,
  exportGroup = exportGroup,
  areProfileStringsEqual = areProfileStringsEqual,
}
private.modules[m.moduleName] = m
