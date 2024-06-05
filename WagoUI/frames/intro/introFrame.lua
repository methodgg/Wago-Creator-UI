local addonName, addon = ...;
local DF = _G["DetailsFramework"];
local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE");
local db
local L = addon.L

local currentPage = 0
local maxPages = 10

local function createStatusBar(parent)
  -- parent frame to give the statusbar a background
  local statusBar = CreateFrame("Frame", addonName.."StatusBar", parent, "BackdropTemplate")
  statusBar:SetBackdropBorderColor(1, 0, 0, 0)
  statusBar:SetSize(400, 28)
  statusBar:SetFrameStrata("DIALOG")
  statusBar:SetFrameLevel(101)
  statusBar:SetPoint("BOTTOM", parent, "BOTTOM", 0, 6)
  DF:CreateBorder(statusBar, 1, 0, 0);

  -- actual status bar, child of parent above
  ---@diagnostic disable-next-line: inject-field
  statusBar.bar = CreateFrame("StatusBar", nil, statusBar)
  statusBar.bar:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
  statusBar.bar:SetStatusBarColor(unpack(addon.colorRGB))
  statusBar.bar:SetPoint("TOPLEFT", 0, 0)
  statusBar.bar:SetPoint("BOTTOMRIGHT", 0, 0)

  ---@diagnostic disable-next-line: inject-field
  statusBar.bar.text = statusBar.bar:CreateFontString()
  statusBar.bar.text:SetPoint('CENTER', statusBar, "CENTER")
  statusBar.bar.text:SetFontObject("GameFontNormalMed3")
  statusBar.bar.text:SetTextColor(1, 1, 1, 1)
  statusBar.bar.text:SetJustifyH("CENTER")
  statusBar.bar.text:SetJustifyV("MIDDLE")
  statusBar.bar.text:SetHeight(20)

  Mixin(statusBar.bar, SmoothStatusBarMixin)

  ---@diagnostic disable-next-line: undefined-field
  statusBar.bar:SetMinMaxSmoothedValue(currentPage, maxPages)

  function addon:UpdateProgressBar(page)
    ---@diagnostic disable-next-line: undefined-field
    statusBar.bar:SetSmoothedValue(page)
    local text = page.."/"..maxPages - 1
    statusBar.bar.text:SetText(text)
  end

  currentPage = currentPage + 1
  addon:UpdateProgressBar(currentPage)
end

function addon:CreateIntroFrame(f)
  local introFrame = CreateFrame("Frame", addonName.."IntroFrame", f)
  introFrame:SetAllPoints(f)
  introFrame:Hide()
  addon.frames.introFrame = introFrame
  local frameWidth = introFrame:GetWidth() - 0
  local frameHeight = introFrame:GetHeight() - 40

  local expertButton = DF:CreateButton(introFrame, nil, 100, 40, "Expert", nil, nil, nil, nil, nil, nil,
    options_dropdown_template);
  expertButton.text_overlay:SetFont(expertButton.text_overlay:GetFont(), 16);
  expertButton:SetPoint("TOPRIGHT", introFrame, "TOPRIGHT", -4, -30)
  expertButton:SetClickFunction(function()
    addon.frames.introFrame:Hide()
    addon.frames.profileFrame:Show()
  end);

  createStatusBar(introFrame)

  local nextButton = DF:CreateButton(introFrame, nil, 80, 30, "Next >>", nil, nil, nil, nil, nil, nil,
    options_dropdown_template);
  nextButton.text_overlay:SetFont(nextButton.text_overlay:GetFont(), 16);
  nextButton:SetPoint("BOTTOMRIGHT", introFrame, "BOTTOMRIGHT", -5, 5);
  nextButton:SetClickFunction(function()
    currentPage = currentPage + 1
    addon:UpdateProgressBar(currentPage)
  end);
end
