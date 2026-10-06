local addon = select(2, ...)
local Packs = {}
addon.Packs = Packs

local function name(value)
  assert(type(value) == "string", "Enter a name.")
  value = value:match("^%s*(.-)%s*$")
  assert(#value > 0 and #value <= 120, "Names must contain 1–120 characters.")
  return value
end

local function touch(pack)
  pack.revision = pack.revision + 1
end

local function nextID(pack, prefix)
  pack.nextID = pack.nextID + 1
  return prefix .. pack.nextID
end

local MAX_RESOLUTIONS = 10
Packs.MAX_RESOLUTIONS = MAX_RESOLUTIONS

-- A variation lists the screens it was designed for; none means Any resolution.
local function resolutions(list)
  if list == nil then return end
  assert(type(list) == "table" and #list <= MAX_RESOLUTIONS, "Invalid resolutions.")
  local count = 0
  for _ in pairs(list) do count = count + 1 end
  assert(count == #list, "Invalid resolutions.")
  local result, seen = {}, {}
  for _, value in ipairs(list) do
    assert(type(value) == "table", "Invalid resolution.")
    for _, key in ipairs({ "width", "height" }) do
      local n = value[key]
      assert(type(n) == "number" and n >= 1 and n <= 32768 and n == math.floor(n),
        "Enter a valid width and height.")
    end
    local key = value.width .. "x" .. value.height
    assert(not seen[key], "That resolution is already listed.")
    seen[key] = true
    table.insert(result, { width = value.width, height = value.height })
  end
  return #result > 0 and result or nil
end

-- Cooldown Manager layouts are class-specific and ship with every variation.
local function everyVariation(pack)
  local tags = {}
  for _, id in ipairs(pack.variationOrder) do tags[id] = true end
  return tags
end

local function membership(pack, tags, required)
  assert(type(tags) == "table", "Choose a variation.")
  local result = {}
  for id, enabled in pairs(tags) do
    assert(pack.variations[id] and enabled == true, "Unknown variation.")
    result[id] = true
  end
  assert(not required or next(result), "Choose at least one variation.")
  return result
end

function Packs.New(id, label)
  return {
    schemaVersion = 2, id = id, name = name(label), revision = 1, nextID = 0,
    variations = { default = { name = "Default", description = "" } },
    variationOrder = { "default" }, profiles = {}, profileOrder = {},
    additionalAddons = {}, releaseNotes = {},
  }
end

function Packs.Rename(pack, label)
  pack.name = name(label)
  touch(pack)
end

-- New variations start empty; the creator assigns profiles on their rows.
function Packs.SaveVariation(pack, id, label, sizes, description)
  label = name(label)
  for otherID, variation in pairs(pack.variations) do
    assert(otherID == id or variation.name:lower() ~= label:lower(), "That variation already exists.")
  end
  sizes = resolutions(sizes)
  assert(type(description or "") == "string" and #(description or "") <= 2000, "Description is too long.")
  if id then assert(pack.variations[id], "Unknown variation.") end
  local isNew = not id
  if isNew then
    id = nextID(pack, "v")
    table.insert(pack.variationOrder, id)
  end
  pack.variations[id] = { name = label, resolutions = sizes, description = description or "" }
  if isNew then
    for _, profile in pairs(pack.profiles) do
      if profile.kind == "cdm" then profile.variations[id] = true end
    end
  end
  touch(pack)
  return id
end

local function removeID(order, id)
  for index, value in ipairs(order) do
    if value == id then table.remove(order, index); return end
  end
end

function Packs.RemoveVariation(pack, id)
  assert(id ~= "default", "Default is the destination for first profiles.")
  assert(pack.variations[id], "Unknown variation.")
  pack.variations[id] = nil
  removeID(pack.variationOrder, id)
  for _, profile in pairs(pack.profiles) do profile.variations[id] = nil end
  touch(pack)
end

function Packs.AddProfile(pack, moduleName, sourceKey, label, tags, kind, sourceCharacter, classAndSpecTag)
  moduleName, sourceKey, label = name(moduleName), name(sourceKey), name(label)
  kind = kind or "profile"
  assert(kind == "profile" or kind == "group" or kind == "snapshot" or kind == "cdm", "Invalid profile kind.")
  local first = true
  for _, profile in pairs(pack.profiles) do
    if profile.moduleName == moduleName then
      first = false
      assert(kind == "snapshot" or profile.sourceKey ~= sourceKey or profile.sourceCharacter ~= sourceCharacter,
        "Profile already added. Edit its variations instead.")
    end
  end
  -- Alternates may start without variations; the creator assigns them on the row.
  if kind == "cdm" then tags = everyVariation(pack) end
  tags = membership(pack, tags or (first and { default = true }), tags == nil)
  local id = nextID(pack, "p")
  pack.profiles[id] = {
    id = id, moduleName = moduleName, sourceKey = sourceKey, name = label, kind = kind,
    sourceCharacter = sourceCharacter, classAndSpecTag = classAndSpecTag, variations = tags,
  }
  table.insert(pack.profileOrder, id)
  touch(pack)
  return id
end

function Packs.SetMembership(pack, id, tags)
  assert(pack.profiles[id], "Unknown profile.")
  pack.profiles[id].variations = membership(pack, tags, false)
  touch(pack)
end

function Packs.SetSource(pack, id, source)
  local profile = assert(pack.profiles[id], "Unknown profile.")
  local key = name(source.key)
  for otherID, other in pairs(pack.profiles) do
    assert(otherID == id or other.moduleName ~= profile.moduleName or source.kind == "snapshot"
      or other.sourceKey ~= key or other.sourceCharacter ~= source.character,
      "Profile already added. Edit its variations instead.")
  end
  if profile.sourceKey == key and profile.sourceCharacter == source.character and profile.kind == source.kind then return end
  profile.sourceKey, profile.name, profile.kind = key, key, source.kind
  profile.sourceCharacter, profile.classAndSpecTag = source.character, source.classAndSpecTag
  profile.data, profile.lastUpdatedAt, profile.lastSavedAt, profile.collectedWagoIds = nil, nil, nil, nil
  touch(pack)
end

function Packs.RemoveProfile(pack, id)
  assert(pack.profiles[id], "Unknown profile.")
  pack.profiles[id] = nil
  removeID(pack.profileOrder, id)
  touch(pack)
end

-- Brings older drafts up to date: single resolutions become lists, and layouts join every variation.
function Packs.Upgrade(pack)
  if type(pack) ~= "table" or type(pack.variations) ~= "table" then return end
  for _, v in pairs(pack.variations) do
    if type(v) == "table" and v.resolution ~= nil then
      v.resolutions, v.resolution = v.resolutions or { v.resolution }, nil
    end
  end
  for _, profile in pairs(type(pack.profiles) == "table" and pack.profiles or {}) do
    if type(profile) == "table" and profile.kind == "cdm" and type(pack.variationOrder) == "table" then
      profile.variations = everyVariation(pack)
    end
  end
end

function Packs.Profiles(pack, variationID)
  local profiles = {}
  for _, id in ipairs(pack.profileOrder) do
    local profile = pack.profiles[id]
    if not variationID or profile.variations[variationID] then table.insert(profiles, profile) end
  end
  return profiles
end

-- Validate the transport boundary before any UI or integration consumes a pack.
function Packs.Validate(pack)
  local function validate()
    assert(type(pack) == "table" and pack.schemaVersion == 2, "This pack needs the new WagoUI format. Download an updated pack.")
    name(pack.id); name(pack.name)
    assert(type(pack.variations) == "table" and type(pack.profiles) == "table", "Invalid pack records.")
    local function order(list, records)
      assert(type(list) == "table" and #list <= 10000, "Invalid record order.")
      local seen = {}
      for _, id in ipairs(list) do
        name(id)
        assert(type(records[id]) == "table" and not seen[id], "Invalid record reference.")
        seen[id] = true
      end
      local count = 0
      for index in pairs(list) do
        assert(type(index) == "number" and index >= 1 and index <= #list and index == math.floor(index), "Invalid record order.")
        count = count + 1
      end
      assert(count == #list, "Invalid record order.")
      for id in pairs(records) do assert(seen[id], "Missing record order.") end
    end
    order(pack.variationOrder, pack.variations)
    order(pack.profileOrder, pack.profiles)
    assert(pack.variations.default, "Missing Default variation.")
    local names = {}
    for _, v in pairs(pack.variations) do
      local label = name(v.name):lower()
      assert(not names[label], "Duplicate variation name.")
      names[label] = true
      assert(v.resolution == nil, "This pack needs the new WagoUI format. Download an updated pack.")
      resolutions(v.resolutions)
      assert(type(v.description or "") == "string" and #(v.description or "") <= 2000, "Invalid description.")
    end
    local bytes = 0
    for id, p in pairs(pack.profiles) do
      assert(p.id == id, "Profile ID mismatch.")
      name(p.moduleName); name(p.name); name(p.sourceKey)
      assert(p.kind == "profile" or p.kind == "snapshot" or p.kind == "group" or p.kind == "cdm", "Invalid profile kind.")
      local grouped = p.moduleName == "WeakAuras" or p.moduleName == "Echo Raid Tools"
      assert((p.kind == "group") == grouped, "Invalid group integration.")
      assert((p.kind == "cdm") == (p.moduleName == "Blizzard Cooldown Manager"), "Invalid layout integration.")
      membership(pack, p.variations, false)
      assert(p.data == nil or (type(p.data) == "string" and #p.data > 0), "Invalid profile payload.")
      assert(not p.data or p.lastUpdatedAt, "Missing profile version.")
      bytes = bytes + #(p.data or "")
      assert(bytes <= 64 * 1024 * 1024, "Pack exceeds 64 MiB.")
      assert(p.lastUpdatedAt == nil or (type(p.lastUpdatedAt) == "number" and p.lastUpdatedAt >= 0 and p.lastUpdatedAt < math.huge), "Invalid profile version.")
      assert(p.lastSavedAt == nil or (type(p.lastSavedAt) == "number" and p.lastSavedAt >= 0 and p.lastSavedAt < math.huge), "Invalid save time.")
      if p.kind == "cdm" then
        assert(type(p.classAndSpecTag) == "number" and p.classAndSpecTag > 0 and p.classAndSpecTag < 1000
          and p.classAndSpecTag == math.floor(p.classAndSpecTag), "Invalid class metadata.")
      end
      assert(p.sourceCharacter == nil or type(p.sourceCharacter) == "string", "Invalid profile source.")
    end
    assert(type(pack.releaseNotes or {}) == "table" and type(pack.additionalAddons or {}) == "table", "Invalid pack metadata.")
    for timestamp, note in pairs(pack.releaseNotes or {}) do
      assert(tonumber(timestamp) and type(note) == "string" and #note <= 100000, "Invalid release notes.")
    end
    for id, label in pairs(pack.additionalAddons or {}) do name(id); name(label) end
    return true
  end
  local ok, result = pcall(validate)
  if ok then return true end
  -- Messages read without the file and line assert adds.
  return false, (tostring(result):gsub("^[^\n]-:%d+: ", ""))
end
