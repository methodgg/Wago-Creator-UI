local addonName, addon = ...;
local DF = _G["DetailsFramework"];
local L = addon.L

local pageName = "DirectProfilesPage"
local filtered

local onShow = function()
  addon:ToggleNavgiationButton("prev", true)
  addon:ToggleNavgiationButton("next", true)
end

local function createPage()
  local page = addon:CreatePageProtoType(pageName)

  local text = L["Choose the profiles you would like to install."]
  local header = DF:CreateLabel(page, text, 22, "white");
  header:SetWidth(page:GetWidth() - 10)
  header:SetJustifyH("CENTER")
  header:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -15);

  local list = addon.DF:CreateProfileSelectionList(page, page:GetWidth() - 160, page:GetHeight() - 160)
  local updateData = function(data)
    filtered = {}
    if data then
      for _, entry in ipairs(data) do
        if entry.moduleName ~= "WeakAuras" and entry.moduleName ~= "Echo Raid Tools" then
          tinsert(filtered, entry)
        end
      end
      --sort disabled modules to bottom, alphabetically afterwards
      table.sort(filtered, function(a, b)
        local orderA = (a.lap.isLoaded() or a.lap.needsInitialization()) and 1 or 0
        local orderB = (b.lap.isLoaded() or b.lap.needsInitialization()) and 1 or 0
        if orderA == orderB then
          return a.moduleName < b.moduleName
        end
        return orderA > orderB
      end)
    end
    list.updateData(filtered)
  end
  addon:RegisterDataConsumer(updateData)
  addon:UpdateRegisteredDataConsumers()
  list.header:SetPoint("TOPLEFT", page, "TOPLEFT", 80, -60)

  local installButton = addon.DF:CreateButton(page, 180, 40, L["Install Profiles"], 18)
  installButton:SetPoint("BOTTOM", page, "BOTTOM", 0, 10)
  installButton:SetClickFunction(function()
    for _, entry in ipairs(filtered) do
      if entry.enabled then
        --TODO: Implement profile installation, respect renamed profile keys
      end
    end
    addon:NextPage()
  end);


  page:SetScript("OnShow", onShow)
  return page
end

addon:RegisterPage(createPage)
