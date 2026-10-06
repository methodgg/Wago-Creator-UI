-- Brings UI Packs made by the previous creator forward. Those stored one profile set per fixed resolution;
-- each enabled resolution becomes a variation, and a profile that is identical in several is shared.
local addon = select(2, ...)
local LAP = LibStub("LibAddonProfiles")
local Legacy = {}
addon.Legacy = Legacy

local RESOLUTIONS = {
  { key = "any", name = "Default" },
  { key = "1080", name = "1080p", width = 1920, height = 1080 },
  { key = "1440", name = "1440p", width = 2560, height = 1440 },
  { key = "2160", name = "4K", width = 3840, height = 2160 },
}
local GROUPED = { WeakAuras = true, ["Echo Raid Tools"] = true }
local CDM = "Blizzard Cooldown Manager"

local function valid(value)
  if type(value) ~= "string" then return false end
  local trimmed = value:match("^%s*(.-)%s*$")
  return #trimmed > 0 and #trimmed <= 120
end

local function timestamp(value)
  return type(value) == "number" and value >= 0 and value < math.huge and value or nil
end

-- IDs must stay the same every time the pack is converted, so install history keeps matching.
local function recordID(...)
  local id = table.concat({ "legacy", ... }, "-")
  if #id <= 120 then return id end
  local hash = 5381
  for index = 1, #id do hash = (hash * 33 + id:byte(index)) % 4294967296 end
  return id:sub(1, 100) .. "-" .. string.format("%08x", hash)
end

local function sortedKeys(map)
  local keys = {}
  for key in pairs(type(map) == "table" and map or {}) do
    if type(key) == "string" or type(key) == "number" then table.insert(keys, key) end
  end
  table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
  return keys
end

function Legacy.IsLegacy(pack)
  return type(pack) == "table" and pack.schemaVersion == nil and type(pack.profileKeys) == "table"
    and type(pack.resolutions) == "table"
end

function Legacy.Convert(id, source)
  local pack = {
    schemaVersion = 2, id = id, name = valid(source.localName) and source.localName or id, revision = 1, nextID = 0,
    variations = {}, variationOrder = {}, profiles = {}, profileOrder = {}, additionalAddons = {}, releaseNotes = {},
    includedAddons = {}, collectedWagoIds = {}, gameVersion = source.gameVersion, gameFlavor = source.gameFlavor,
    createdBy = source.createdBy,
  }
  -- The first enabled resolution takes the Default slot every pack needs.
  local variationOf = {}
  pack.legacyVariations = variationOf
  local enabled = type(source.resolutions.enabled) == "table" and source.resolutions.enabled or {}
  for _, r in ipairs(RESOLUTIONS) do
    if enabled[r.key] then
      local variationID = #pack.variationOrder == 0 and "default" or ("r" .. r.key)
      pack.variations[variationID] = {
        name = r.name, description = "", resolutions = r.width and { { width = r.width, height = r.height } } or nil,
      }
      table.insert(pack.variationOrder, variationID)
      variationOf[r.key] = variationID
    end
  end
  if #pack.variationOrder == 0 then
    pack.variations.default = { name = "Default", description = "" }
    pack.variationOrder = { "default" }
  end

  local shared = {}
  local function add(resolution, moduleName, key, data, updatedAt, kind, entry)
    if not valid(key) or type(data) ~= "string" or #data == 0 then return end
    local variationID = variationOf[resolution]
    local sharedKey = table.concat({ moduleName, key, data }, "\0")
    local p = shared[sharedKey]
    if not p then
      p = {
        id = entry and recordID(resolution, moduleName, entry) or recordID(resolution, moduleName),
        moduleName = moduleName, sourceKey = key, name = key, kind = kind, variations = {}, data = data,
        lastUpdatedAt = updatedAt or 0, legacy = {},
      }
      if pack.profiles[p.id] then return end
      shared[sharedKey] = p
      pack.profiles[p.id] = p
      table.insert(pack.profileOrder, p.id)
    end
    p.variations[variationID] = true
    p.lastUpdatedAt = math.max(p.lastUpdatedAt, updatedAt or 0)
    table.insert(p.legacy, { resolution = resolution, entry = entry })
  end

  local profiles = type(source.profiles) == "table" and source.profiles or {}
  local metadata = type(source.profileMetadata) == "table" and source.profileMetadata or {}
  for _, r in ipairs(RESOLUTIONS) do
    local keys = variationOf[r.key] and source.profileKeys[r.key]
    local data, meta = profiles[r.key] or {}, metadata[r.key] or {}
    for _, moduleName in ipairs(sortedKeys(keys)) do
      local value, moduleMeta = keys[moduleName], type(meta[moduleName]) == "table" and meta[moduleName] or {}
      if valid(moduleName) and moduleName ~= CDM then
        if type(value) == "string" and not GROUPED[moduleName] then
          local lap = LAP:GetModule(moduleName)
          add(r.key, moduleName, value, data[moduleName], timestamp(moduleMeta.lastUpdatedAt),
            lap and lap.preventRename and "snapshot" or "profile")
        elseif type(value) == "table" and GROUPED[moduleName] and type(data[moduleName]) == "table" then
          local times = type(moduleMeta.lastUpdatedAt) == "table" and moduleMeta.lastUpdatedAt or {}
          for _, group in ipairs(sortedKeys(value)) do
            add(r.key, moduleName, group, data[moduleName][group], timestamp(times[group]), "group", group)
          end
        end
      end
    end
    local wagoIDs = type(source.collectedWagoIds) == "table" and source.collectedWagoIds[r.key]
    if variationOf[r.key] and type(wagoIDs) == "table" then
      for wagoID, label in pairs(wagoIDs) do pack.collectedWagoIds[wagoID] = label end
    end
  end

  -- Cooldown Manager layouts were already shared by every resolution.
  local cdm = type(source.cdmData) == "table" and source.cdmData or {}
  local layouts = type(cdm.profiles) == "table" and cdm.profiles or {}
  for _, tag in ipairs(sortedKeys(cdm.profileKeys)) do
    local classAndSpecTag = tonumber(tag)
    for _, key in ipairs(sortedKeys(cdm.profileKeys[tag])) do
      local info = type(cdm.profileKeys[tag][key]) == "table" and cdm.profileKeys[tag][key] or {}
      local data = type(layouts[tag]) == "table" and layouts[tag][key]
      local times = type(info.metaData) == "table" and type(info.metaData.lastUpdatedAt) == "table"
        and info.metaData.lastUpdatedAt or {}
      local p = {
        id = recordID("cdm", tag, key), moduleName = CDM, sourceKey = key, name = key, kind = "cdm", variations = {},
        data = data, lastUpdatedAt = timestamp(times[key]) or 0, classAndSpecTag = classAndSpecTag, legacy = {},
      }
      if valid(key) and type(data) == "string" and #data > 0 and classAndSpecTag and classAndSpecTag > 0
        and classAndSpecTag < 1000 and classAndSpecTag == math.floor(classAndSpecTag) and not pack.profiles[p.id] then
        for _, variationID in ipairs(pack.variationOrder) do p.variations[variationID] = true end
        pack.profiles[p.id] = p
        table.insert(pack.profileOrder, p.id)
      end
    end
  end

  for at, note in pairs(type(source.releaseNotes) == "table" and source.releaseNotes or {}) do
    if tonumber(at) and type(note) == "string" then
      pack.releaseNotes[tostring(at)] = note:gsub("\\n", "\n"):sub(1, 100000)
    end
  end
  -- Included addons that no integration covers are the pack's additional addons.
  local covered = {}
  for moduleName, lap in pairs(LAP:GetAllModules()) do
    covered[moduleName] = true
    for name in pairs(lap.additionalWagoIds or {}) do covered[name] = true end
  end
  for name, wagoID in pairs(type(source.includedAddons) == "table" and source.includedAddons or {}) do
    if valid(name) and valid(wagoID) then
      pack.includedAddons[name] = wagoID
      if not covered[name] and wagoID ~= "baseline" then pack.additionalAddons[wagoID] = name end
    end
  end
  return pack
end

-- The previous installer kept history per resolution and addon; carry it over so earlier installs show as
-- installed or as having an update, instead of as new.
function Legacy.MigrateHistory(db, pack)
  if type(db.importedProfiles) ~= "table" then return end
  for character, packs in pairs(db.importedProfiles) do
    local old = type(packs) == "table" and packs[pack.id]
    if type(old) == "table" then
      for _, id in ipairs(pack.profileOrder) do
        local p = pack.profiles[id]
        local best
        local function consider(resolution, info)
          if type(info) == "table" and timestamp(info.importedAt) and (not best or info.importedAt > best.importedAt) then
            best = { info = info, resolution = resolution }
          end
        end
        if p.kind == "cdm" then
          for resolution, modules in pairs(old) do
            local entry = type(modules) == "table" and modules[CDM]
            consider(resolution, type(entry) == "table" and type(entry.entries) == "table" and entry.entries[p.sourceKey])
          end
        else
          for _, ref in ipairs(p.legacy) do
            local modules = old[ref.resolution]
            local entry = type(modules) == "table" and modules[p.moduleName]
            if type(entry) == "table" then
              if ref.entry then consider(ref.resolution, type(entry.entries) == "table" and entry.entries[ref.entry])
              else consider(ref.resolution, entry) end
            end
          end
        end
        if best then
          db.profileHistory[character] = db.profileHistory[character] or {}
          local history = db.profileHistory[character]
          history[pack.id] = history[pack.id] or {}
          if not history[pack.id][p.id] then
            history[pack.id][p.id] = {
              moduleName = p.moduleName, kind = p.kind, importedAt = best.info.importedAt,
              profileKey = type(best.info.profileKey) == "string" and best.info.profileKey or p.sourceKey,
              lastUpdatedAt = timestamp(best.info.lastUpdatedAt), variationID = pack.legacyVariations[best.resolution],
            }
          end
        end
      end
    end
  end
end
