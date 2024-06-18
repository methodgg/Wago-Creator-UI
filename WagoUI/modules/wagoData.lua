local addonName, addon = ...;
local LAP = LibStub:GetLibrary("LibAddonProfiles")
local db

function addon:SetupWagoData()
  db = addon.db
  if not db.selectedWagoData then
    if WagoUI_Data then
      for key in pairs(WagoUI_Data) do
        db.selectedWagoData = key
        break
      end
    end
  end
  if not WagoUI_Data or not WagoUI_Data[db.selectedWagoData] then
    db.selectedWagoData = nil
    addon.wagoData = nil
    return
  end
  local source = WagoUI_Data[db.selectedWagoData]
  addon.wagoData = {}
  for resolution, modules in pairs(source.profileKeys) do
    addon.wagoData[resolution] = {}
    addon.wagoData[resolution][1] = {} -- TODO: hardcoded 2 tabs right now
    addon.wagoData[resolution][2] = {}
    for moduleName, moduleData in pairs(modules) do
      if type(moduleData) == "string" then
        tinsert(addon.wagoData[resolution][1], {
          lap = LAP:GetModule(moduleName),
          moduleName = moduleName,
          profileKey = moduleData,
          profileMetadata = source.profileMetadata[resolution][moduleName],
          profile = source.profiles[resolution][moduleName],
        })
      elseif moduleName == "WeakAuras" or moduleName == "Echo Raid Tools" then
        for groupId in pairs(moduleData) do
          tinsert(addon.wagoData[resolution][2], {
            lap = LAP:GetModule(moduleName),
            moduleName = moduleName,
            sortOrder = moduleName == "WeakAuras" and 1 or 2,
            entryName = groupId,
            profileKey = groupId,
            profileMetadata = source.profileMetadata[resolution][moduleName],
            profile = source.profiles[resolution][moduleName][groupId],
          })
        end
      else
        --TODO: TalentLoadoutEx
      end
    end
    --sort weakauras on top
    table.sort(addon.wagoData[resolution][2], function(a, b)
      return a.sortOrder < b.sortOrder
    end)
  end
end

function addon:GetWagoDataForDropdown()
  local wagoData = {}
  if WagoUI_Data then
    for key, data in pairs(WagoUI_Data) do
      local entry = {
        value = key,
        label = data.name,
        onclick = function()
          db.selectedWagoData = key
          addon:SetupWagoData()
          addon:RefreshResolutionDropdown()
          addon:UpdateProfileTable(addon.wagoData[db.selectedWagoDataResolution])
        end
      }
      tinsert(wagoData, entry)
    end
  end
  return wagoData
end

function addon:GetResolutionsForDropdown()
  local res = {}
  local selectedWagoUI_Data = db.selectedWagoData and WagoUI_Data[db.selectedWagoData]
  local resolutions = selectedWagoUI_Data and selectedWagoUI_Data.resolutions.enabled

  if WagoUI_Data and resolutions then
    for key, enabled in pairs(resolutions) do
      if enabled then
        local entry = {
          value = key,
          label = key,
          onclick = function()
            db.selectedWagoDataResolution = key
            addon:SetupWagoData()
            addon:UpdateProfileTable(addon.wagoData[key])
          end
        }
        tinsert(res, entry)
      end
    end
  end
  return res
end
