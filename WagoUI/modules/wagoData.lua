---@class WagoUI
local addon = select(2, ...)
local LAP = LibStub:GetLibrary("LibAddonProfiles")
local db

--- We want to get the latest imported profile for a character and module.
--- This is most likely the profile the user wants to use.
---@param characterName string Character name in format "Playername - Realm Name"
---@param moduleName string LibAddonProfiles module name
---@return string | nil latestProfileKey key of the latest imported profile
---@return number | nil latestUpdatedAt
---@return number | nil latestImportedAt
function addon:GetLatestImportedProfile(characterName, moduleName)
  local packs = addon.db.importedProfiles[characterName]
  local latest = 0
  local latestProfileKey = nil
  local latestUpdatedAt = nil
  local latestImportedAt = nil
  for _, pack in pairs(packs) do
    for resolutionKey, imports in pairs(pack) do
      if imports[moduleName] and imports[moduleName].importedAt and imports[moduleName].importedAt > latest then
        latest = imports[moduleName].importedAt
        latestProfileKey = imports[moduleName].profileKey
        latestUpdatedAt = imports[moduleName].lastUpdatedAt
        latestImportedAt = imports[moduleName].importedAt
      end
    end
  end
  return latestProfileKey, latestUpdatedAt, latestImportedAt
end

---@param profileKey string
---@param lap LibAddonProfilesModule
---@return string newProfileKey
local findAppropriateProfileKey = function(profileKey, lap)
  if profileKey == "Global" then
    return profileKey
  end
  if not lap:isLoaded() then
    return profileKey
  end
  local newProfileKey = profileKey
  local i = 1
  while lap:isDuplicate(newProfileKey) do
    newProfileKey = profileKey.."_"..i
    i = i + 1
  end
  return newProfileKey
end

function addon:SetupWagoData()
  db = addon.db
  if not db.selectedWagoData then
    if WagoUI_Storage then
      for key in pairs(WagoUI_Storage) do
        db.selectedWagoData = key
        break
      end
    end
  end
  if not WagoUI_Storage or not WagoUI_Storage[db.selectedWagoData] then
    db.selectedWagoData = nil
    addon.wagoData = nil
    return
  end
  local source = WagoUI_Storage[db.selectedWagoData]
  addon.wagoData = {}
  local newIntroImportState = {}
  for _, entry in pairs(addon.resolutions.entries) do
    newIntroImportState[entry.value] = {}
  end
  for resolution, modules in pairs(source.profileKeys) do
    addon.wagoData[resolution] = {}
    for moduleName, moduleData in pairs(modules) do
      if type(moduleData) == "string" then
        newIntroImportState[resolution][moduleName] = {}
        local profileData = source.profiles[resolution][moduleName]
        local lap = LAP:GetModule(moduleName)
        if profileData and lap then
          if lap:needsInitialization() then
            lap:openConfig()
            C_Timer.After(
              0,
              function()
                lap:closeConfig()
              end
            )
          end

          local previousState = addon.db.introImportState
              and addon.db.introImportState[resolution]
              and addon.db.introImportState[resolution][moduleName]
          local newChecked
          if not previousState then
            newChecked = true
          else
            newChecked = previousState.checked
          end
          local profileKey = findAppropriateProfileKey(moduleData, lap)
          newIntroImportState[resolution][moduleName] = {
            checked = newChecked,
            profileMetadata = source.profileMetadata[resolution][moduleName],
            profileKey = profileKey,
            profile = profileData
          }

          tinsert(
            addon.wagoData[resolution],
            {
              lap = lap,
              moduleName = moduleName,
              profileKey = profileKey,
              profileMetadata = source.profileMetadata[resolution][moduleName],
              profile = profileData,
              enabled = newIntroImportState[resolution][moduleName].checked
            }
          )
        end
      elseif moduleName == "WeakAuras" or moduleName == "Echo Raid Tools" then
        for groupId in pairs(moduleData) do
          local profile = source.profiles[resolution][moduleName] and source.profiles[resolution][moduleName][groupId]
          local lap = LAP:GetModule(moduleName)
          if profile and lap then
            tinsert(
              addon.wagoData[resolution],
              {
                lap = lap,
                moduleName = moduleName,
                entryName = groupId,
                profileKey = groupId,
                profileMetadata = source.profileMetadata[resolution][moduleName],
                profile = profile,
                enabled = true
              }
            )
          end
        end
      else
        --TODO: TalentLoadoutEx
      end
    end
  end
  addon.db.introImportState = newIntroImportState
end

function addon:GetWagoDataForDropdown()
  local wagoData = {}
  if WagoUI_Storage then
    for key, data in pairs(WagoUI_Storage) do
      local entry = {
        value = key,
        label = data.localName,
        onclick = function()
          addon:SetActivePack(key)
        end
      }
      tinsert(wagoData, entry)
    end
  end
  return wagoData
end

---@param packId string
function addon:SetActivePack(packId)
  db.selectedWagoData = packId
  addon:RefreshResolutionDropdown()
  addon:SetUIPackDropdownToPack(packId)
  addon:SetupWagoData()
  addon:UpdateRegisteredDataConsumers()
end

---@param resolution string
---@param type  "displayNameLong" | "displayNameShort"
---@return string
function addon:GetResolutionString(resolution, type)
  for _, entry in ipairs(addon.resolutions.entries) do
    if entry.value == resolution then
      --- @as string
      return entry[type]
    end
  end
  return ""
end

function addon:GetResolutionsForDropdown()
  local res = {}
  local selectedWagoUI_Storage = db.selectedWagoData and WagoUI_Storage[db.selectedWagoData]
  local resolutions = selectedWagoUI_Storage and selectedWagoUI_Storage.resolutions.enabled

  if WagoUI_Storage and resolutions then
    for key, enabled in pairs(resolutions) do
      if enabled then
        local entry = {
          value = key,
          label = addon:GetResolutionString(key, "displayNameShort"),
          onclick = function()
            db.selectedWagoDataResolution = key
            addon:SetupWagoData()
            addon:UpdateRegisteredDataConsumers()
          end
        }
        tinsert(res, entry)
      end
    end
  end
  return res
end

do
  local consumers = {}
  function addon:RegisterDataConsumer(func)
    tinsert(consumers, func)
  end

  function addon:UpdateRegisteredDataConsumers()
    local wagoData = addon.wagoData and addon.wagoData[db.selectedWagoDataResolution]
    for _, consumer in ipairs(consumers) do
      consumer(wagoData)
    end
  end
end

local function wrapStringInCurrentClassColor(name)
  local res = name
  local _, class = UnitClass("player")
  if class ~= "Adventurer" then
    local _, _, _, classHexString = GetClassColor(class)
    res = "|c"..classHexString..res.."|r"
  end
  return res
end

function addon:GetClassColoredNameFromDB(name)
  return addon.db.classColoredCharacters[name] or name
end

---@class ImportMetaDataEntry
---@field lastUpdatedAt number
---@field importedAt number

---@class ImportMetaData
---@field lastUpdatedAt? number
---@field importedAt? number
---@field profileKey? string
---@field entries? table<string, ImportMetaData>

---@return table<string, ImportMetaData>>
function addon:GetImportedProfilesTarget()
  local currentCharacter = UnitName("player").." - "..GetRealmName()
  local packKey = addon.db.selectedWagoData
  local resolution = addon.db.selectedWagoDataResolution
  addon.db.importedProfiles[currentCharacter] = addon.db.importedProfiles[currentCharacter] or {}
  addon.db.importedProfiles[currentCharacter][packKey] = addon.db.importedProfiles[currentCharacter][packKey] or {}
  addon.db.importedProfiles[currentCharacter][packKey][resolution] =
      addon.db.importedProfiles[currentCharacter][packKey][resolution] or {}
  addon.db.classColoredCharacters[currentCharacter] = wrapStringInCurrentClassColor(currentCharacter)
  return addon.db.importedProfiles[currentCharacter][packKey][resolution]
end

-- Important:
-- We are storing the timestamp of when the profile has been updated by the creator
-- This is to check if the profile has been updated since the user last imported it
-- Additionally we store the timestamp of when the profile was imported by the user
---@param timestamp number
---@param moduleName string
---@param profileKey string
---@param entryName? string
function addon:StoreImportedProfileData(timestamp, moduleName, profileKey, entryName)
  local target = addon:GetImportedProfilesTarget()
  if not target[moduleName] then
    target[moduleName] = entryName and { entries = {} } or {}
  end
  if entryName then
    target[moduleName].entries[entryName] = {
      lastUpdatedAt = timestamp,
      importedAt = GetServerTime()
    }
  else
    target[moduleName].profileKey = profileKey
    target[moduleName].lastUpdatedAt = timestamp
    target[moduleName].importedAt = GetServerTime()
  end
end

---@param moduleName string
---@param entryName? string Name of the profile if the profile is from a module that has multiple profiles (e.g. WeakAuras).
---@return number | nil lastUpdatedAt Timestamp of when the profile was last updated by the creator
---@return string | nil profileKey Profile the imported profile was imported as. The user could have changed the profile key during the intro wizard
---@return number | nil importedAt Timestamp of when the profile was imported by the user
function addon:GetImportedProfileData(moduleName, entryName)
  local target = addon:GetImportedProfilesTarget()
  if not target[moduleName] then
    return
  end
  if entryName then
    local data = target[moduleName] and target[moduleName].entries and target[moduleName].entries[entryName]
    if not data then
      return
    end
    return data.lastUpdatedAt, data.profileKey, data.importedAt
  end
  return target[moduleName].lastUpdatedAt, target[moduleName].profileKey, target[moduleName].importedAt
end
