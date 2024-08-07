---@class WagoUI
local addon = select(2, ...)
local LAP = LibStub:GetLibrary("LibAddonProfiles")
local db

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
  for resolution, modules in pairs(source.profileKeys) do
    addon.wagoData[resolution] = {}
    for moduleName, moduleData in pairs(modules) do
      if type(moduleData) == "string" then
        local profileData = source.profiles[resolution][moduleName]
        local lap = LAP:GetModule(moduleName)
        if profileData and lap then
          tinsert(addon.wagoData[resolution], {
            lap = lap,
            moduleName = moduleName,
            profileKey = moduleData,
            profileMetadata = source.profileMetadata[resolution][moduleName],
            profile = profileData,
            enabled = true,
          })
        end
      elseif moduleName == "WeakAuras" or moduleName == "Echo Raid Tools" then
        for groupId in pairs(moduleData) do
          local profile = source.profiles[resolution][moduleName] and source.profiles[resolution][moduleName][groupId]
          local lap = LAP:GetModule(moduleName)
          if profile and lap then
            tinsert(addon.wagoData[resolution], {
              lap = lap,
              moduleName = moduleName,
              entryName = groupId,
              profileKey = groupId,
              profileMetadata = source.profileMetadata[resolution][moduleName],
              profile = profile,
              enabled = true,
            })
          end
        end
      else
        --TODO: TalentLoadoutEx
      end
    end
  end
end

function addon:GetWagoDataForDropdown()
  local wagoData = {}
  if WagoUI_Storage then
    for key, data in pairs(WagoUI_Storage) do
      local entry = {
        value = key,
        label = data.localName,
        onclick = function()
          db.selectedWagoData = key
          addon:RefreshResolutionDropdown()
          addon:SetupWagoData()
          addon:UpdateRegisteredDataConsumers()
        end
      }
      tinsert(wagoData, entry)
    end
  end
  return wagoData
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
          label = key,
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

-- Important:
-- We are storing the timestamp of when the profile has been updated by the creator
-- NOT the time when the user imported the profile
-- This is to check if the profile has been updated since the user last imported it
function addon:StoreImportedProfileData(timestamp, moduleName, profileKey, entryName)
  if not db.importedProfiles[moduleName] then
    db.importedProfiles[moduleName] = entryName and
        {
          entries = {},
        } or {}
  end
  if entryName then
    db.importedProfiles[moduleName].entries[entryName] = {
      lastUpdatedAt = timestamp
    }
  else
    db.importedProfiles[moduleName].profileKey = profileKey
    db.importedProfiles[moduleName].lastUpdatedAt = timestamp
  end
end

---@param moduleName string
---@param entryName? string Name of the profile if the profile is from a module that has multiple profiles (e.g. WeakAuras).
---@return number | nil lastUpdatedAt Timestamp of when the profile was last updated by the creator
---@return string | nil profileKey Profile the imported profile was imported as. The user could have changed the profile key during the intro wizard
function addon:GetImportedProfileData(moduleName, entryName)
  if entryName then
    local data = db.importedProfiles[moduleName]
        and db.importedProfiles[moduleName].entries
        and db.importedProfiles[moduleName].entries[entryName]
        and db.importedProfiles[moduleName].entries[entryName]
    if not data then return end
    return data.lastUpdatedAt, data.profileKey
  end
  local data = db.importedProfiles[moduleName]
  if not data then return end
  return data.lastUpdatedAt, data.profileKey
end
