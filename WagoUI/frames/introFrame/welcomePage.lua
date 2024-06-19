local addonName, addon = ...;
local DF = _G["DetailsFramework"];
local L = addon.L

local pageName = "WelcomePage"

local function createPage()
  local page = addon:CreatePageProtoType(pageName)

  local header = DF:CreateLabel(page, string.format(L["Welcome to |c%sWago|rUI:"], addon.color), 38,
    "white");
  header:SetJustifyH("CENTER")
  header:SetPoint("TOP", page, "TOP", 0, -75);

  -- label or dropdown, depending on if single or multiple ui packs available
  local dropdownData = addon:GetWagoDataForDropdown()
  if #dropdownData == 0 then
    local noDataLabel = DF:CreateLabel(page, L["No UI Packs found"], 26, "white");
    noDataLabel:SetJustifyH("CENTER")
    noDataLabel:SetPoint("TOP", header, "BOTTOM", 0, -70)
    return page
  end
  if #dropdownData > 1 then
    local dropdownFunc = function() return addon:GetWagoDataForDropdown() end
    local uiPackDropdown = addon.DF:CreateDropdown(page, 250, 40, 20, dropdownFunc)
    uiPackDropdown:SetPoint("TOP", header, "BOTTOM", 0, -10)
  else
    local uiPackLabel = DF:CreateLabel(page, dropdownData[1].label, 38, "white");
    uiPackLabel:SetJustifyH("CENTER")
    uiPackLabel:SetPoint("TOP", header, "BOTTOM", 0, -10)
  end

  local logo = DF:CreateImage(page, [[Interface\AddOns\]]..addonName..[[\media\wagoLogo512]], 256, 256)
  logo:SetPoint("TOP", header, "BOTTOM", 0, -20)

  local startButton = addon.DF:CreateButton(page, 230, 50, "Full Installation", 22)
  startButton:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 140, 80);
  startButton:SetClickFunction(function()
    addon:NextPage()
  end);

  local expertButton = addon.DF:CreateButton(page, 230, 50, "Expert Mode", 22)
  expertButton:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -140, 80);
  expertButton:SetClickFunction(function()
    addon.frames.introFrame:Hide()
    addon.frames.expertFrame:Show()
    addon.db.introEnabled = false
  end);


  return page
end

addon:RegisterPage(createPage)
