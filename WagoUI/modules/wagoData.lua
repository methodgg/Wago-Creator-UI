local addonName, addon = ...;
local LAP = LibStub:GetLibrary("LibAddonProfiles")
local db

function addon:SetupWagoData()
  db = addon.db
  if not db.selectedWagoData then
    if WagoUIData then
      for key in pairs(WagoUIData) do
        db.selectedWagoData = key
        break
      end
    end
  end
  if not WagoUIData and not WagoUIData[db.selectedWagoData] then
    db.selectedWagoData = nil
    addon.wagoData = nil
    return
  end
  local source = WagoUIData[db.selectedWagoData]
  addon.wagoData = {}

  for resolution, modules in pairs(source.profileKeys) do
    addon.wagoData[resolution] = {}
    for moduleName, moduleData in pairs(modules) do
      --TODO: add grouped profiles (WeakAuras etc)
      if type(moduleData) == "string" then
        tinsert(addon.wagoData[resolution], {
          lap = LAP:GetModule(moduleName),
          moduleName = moduleName,
          profileKey = moduleData,
          profileMetadata = source.profileMetadata[resolution][moduleName],
          profile = source.profiles[resolution][moduleName],
        })
      elseif moduleName == "WeakAuras" or moduleName == "Echo Raid Tools" then
        for groupId in pairs(moduleData) do
          tinsert(addon.wagoData[resolution], {
            lap = LAP:GetModule(moduleName),
            moduleName = moduleName,
            entryName = groupId,
            profileKey = groupId,
            profileMetadata = source.profileMetadata[resolution][moduleName],
            profile = source.profiles[resolution][moduleName][groupId],
          })
        end
      else
        --TODO: TalentLoadoutEx
        --vdt(moduleData, moduleName)
      end
    end
  end
end

function addon:GetWagoDataForDropdown()
  local wagoData = {}
  if WagoUIData then
    for key, data in pairs(WagoUIData) do
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
  local selectedWagoUIData = db.selectedWagoData and WagoUIData[db.selectedWagoData]
  local resolutions = selectedWagoUIData and selectedWagoUIData.resolutions.enabled

  if WagoUIData and resolutions then
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
