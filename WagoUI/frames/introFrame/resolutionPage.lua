local addonName, addon = ...;
local DF = _G["DetailsFramework"];
local L = addon.L

local pageName = "ResolutionPage"
local page
local availableResolutions
local resolutionButtons = {}

local function addButtonToPage(button, i, total)
  button:Show()
  -- 3 buttons next to each other then a new row
  if total == 1 then
    button:SetPoint("CENTER", page, "CENTER", 0, -70)
  end
  if total == 2 then
    button:SetPoint("CENTER", page, "CENTER", i == 1 and -150 or 150, -70)
  end
end

local onShow = function()
  for _, button in pairs(resolutionButtons) do
    button:Hide()
    button:ClearAllPoints()
  end
  availableResolutions = addon:GetResolutionsForDropdown()
  for i, data in ipairs(availableResolutions) do
    if not resolutionButtons[data.value] then
      local button = addon.DF:CreateResolutionButton(page, data.label)
      button:SetScript("OnClick", data.onclick)
      resolutionButtons[data.value] = button
    end
    addButtonToPage(resolutionButtons[data.value], i, #availableResolutions)
  end
end

local function createPage()
  page = addon:CreatePageProtoType(pageName)

  local header = DF:CreateLabel(page, "Choose the Resolution that fits your UI and Monitor best", 38, "white");
  header:SetWidth(page:GetWidth() - 10)
  header:SetJustifyH("CENTER")
  header:SetPoint("TOP", page, "TOP", 0, -130);

  page:SetScript("OnShow", onShow)
  return page
end

addon:RegisterPage(createPage)
