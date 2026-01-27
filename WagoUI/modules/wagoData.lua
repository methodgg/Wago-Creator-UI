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

local isClassAndSpecTagSameClass = function(tagA, tagB)
  local classA = math.floor(tagA / 10)
  local classB = math.floor(tagB / 10)
  return classA == classB
end

--Blizzard Cooldown Manager
local function addCdmData(source)
  if not source.cdmData then return end
  local lap = LAP:GetModule("Blizzard Cooldown Manager")
  local currentClassAndSpecTag = CooldownViewerUtil.GetCurrentClassAndSpecTag()

  if not lap then return end
  local profilesToAdd = {}
  for classAndSpecTag, profiles in pairs(source.cdmData.profileKeys) do
    for profileKey, profile in pairs(profiles) do
      local profileString = source.cdmData.profiles[classAndSpecTag] and
          source.cdmData.profiles[classAndSpecTag][profileKey]
      if profileString then
        tinsert(profilesToAdd, {
          profileData = profile,
          profileKey = profile.profileKey,
          entryName = profile.profileKey,
          entryNameDisplay = "CDM: "..profile.coloredName,
          icon = profile.icon,
          lap = lap,
          moduleName = lap.moduleName,
          profileMetadata = profile.metaData,
          profile = profileString,
          enabled = true,
          matchingInfo = {
            matching = isClassAndSpecTagSameClass(currentClassAndSpecTag, profile.classAndSpecTag)
          },
        })
      end
    end
  end

  --add data to every resolution (only if there is atleast one entry for the resolution)
  local hasAdded = false
  for _, data in pairs(addon.wagoData) do
    if next(data) then
      for _, profile in pairs(profilesToAdd) do
        tinsert(data, profile)
      end
      hasAdded = true
    end
  end
  --Exception: There is no profiles in any resolution, add to "Any"
  if not hasAdded then
    for _, profile in pairs(profilesToAdd) do
      tinsert(addon.wagoData[addon.resolutions.defaultValue], profile)
    end
  end
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
          local profileKey = moduleData
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
  addCdmData(source)
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
