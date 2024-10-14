---@class WagoUI
local addon = select(2, ...)
local DF = _G["DetailsFramework"]
local LWF = LibStub("LibWagoFramework")
local L = addon.L

local pageName = "DirectProfilesPage"
local hasSkipped = false
local filtered

local onShow = function()
  if not hasSkipped and #filtered == 0 then
    addon:NextPage()
    hasSkipped = true
    return
  end
  addon.db.introState.currentPage = pageName
  addon.db.introEnabled = true
  addon:ToggleNavigationButton("prev", true)
  addon:ToggleNavigationButton("next", true)
  addon:UpdateRegisteredDataConsumers()
end

local function createPage()
  local page = addon:CreatePageProtoType(pageName)

  local text = L["Choose the profiles you would like to install."]
  local header = DF:CreateLabel(page, text, 22, "white")
  header:SetWidth(page:GetWidth() - 10)
  header:SetJustifyH("CENTER")
  header:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -15)

  local checkboxDefaultValue = true
  local res = addon.db.selectedWagoDataResolution or addon.resolutions.defaultValue
  if addon.db.introImportState[res] then
    for _, data in pairs(addon.db.introImportState[res]) do
      if not data.checked then
        checkboxDefaultValue = false
        break
      end
    end
  end
  local allCheckbox = LWF:CreateCheckbox(page, 40,
    function(self, _, value)
      for _, data in pairs(addon.db.introImportState[res]) do
        data.checked = value
      end
      addon:SetupWagoData()
      addon:UpdateRegisteredDataConsumers()
    end,
    checkboxDefaultValue
  )
  allCheckbox:SetPoint("BOTTOMRIGHT", page, "BOTTOM", -37, 10)
  local checkboxLabel = DF:CreateLabel(page, L["Import All"], 16, "white")
  checkboxLabel:SetPoint("LEFT", allCheckbox, "RIGHT", 5, 0)

  local updateCheckbox = function()
    local val = true
    for _, data in pairs(addon.db.introImportState[res]) do
      if not data.checked then
        val = false
        break
      end
    end
    allCheckbox:SetValue(val)
  end

  local list = addon:CreateProfileSelectionList(page, page:GetWidth(), page:GetHeight() - 140, updateCheckbox)
  local updateData = function(data)
    filtered = {}
    if data then
      for _, entry in ipairs(data) do
        if entry.moduleName ~= "WeakAuras" and entry.moduleName ~= "Echo Raid Tools" then
          tinsert(filtered, entry)
        end
      end
      --sort disabled modules to bottom, alphabetically afterwards
      table.sort(
        filtered,
        function(a, b)
          local orderA = (a.lap:isLoaded() or a.lap:needsInitialization()) and 1 or 0
          local orderB = (b.lap:isLoaded() or b.lap:needsInitialization()) and 1 or 0
          if orderA == orderB then
            return a.moduleName < b.moduleName
          end
          return orderA > orderB
        end
      )
    end
    list.updateData(filtered)
  end

  function addon:GetFilteredProfileInstallData()
    return filtered
  end

  addon:RegisterDataConsumer(updateData)
  list.header:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -60)

  page:SetScript("OnShow", onShow)
  return page
end

addon:RegisterPage(createPage)
