local addonName, addon = ...;
local DF = _G["DetailsFramework"];
local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE");
local db
local L = addon.L

local pageName = "WelcomePage"

local function createPage()
  local page = addon:CreatePageProtoType(pageName)

  local header = DF:CreateLabel(page, string.format(L["Welcome to |c%sWago|rUI!"], addon.color), 38, "white");
  header:SetWidth(page:GetWidth() - 10)
  header:SetJustifyH("CENTER")
  header:SetPoint("TOP", page, "TOP", 0, -100);

  local logo = DF:CreateImage(page, [[Interface\AddOns\]]..addonName..[[\media\wagoLogo512]], 256, 256)
  logo:SetPoint("TOP", header, "BOTTOM", 0, 50)

  local startButton = DF:CreateButton(page, nil, 230, 50, "Full Installation", nil, nil, nil, nil, nil,
    nil,
    options_dropdown_template);
  startButton:SetScript("OnEnter", function(self)
    startButton.button:SetBackdropBorderColor(1, 1, 1, 1)
  end)
  startButton:SetScript("OnLeave", function(self)
    startButton.button:SetBackdropBorderColor(1, 1, 1, 0)
  end)
  startButton:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 140, 100);
  startButton.text_overlay:SetFont(startButton.text_overlay:GetFont(), 22);
  startButton:SetClickFunction(function()

  end);

  local expertButton = DF:CreateButton(page, nil, 230, 50, "Expert Mode", nil, nil, nil, nil
    , nil, nil,
    options_dropdown_template);
  expertButton:SetScript("OnEnter", function(self)
    expertButton.button:SetBackdropBorderColor(1, 1, 1, 1)
  end)
  expertButton:SetScript("OnLeave", function(self)
    expertButton.button:SetBackdropBorderColor(1, 1, 1, 0)
  end)
  expertButton:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -140, 100);
  expertButton.text_overlay:SetFont(expertButton.text_overlay:GetFont(), 22);
  expertButton:SetClickFunction(function()

  end);


  return page
end

addon:RegisterPage(createPage)
