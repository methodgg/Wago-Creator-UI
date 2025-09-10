---@type string
local addonName = ...
---@class WagoUI
local addon = select(2, ...)
local DF = _G["DetailsFramework"]
local LWF = LibStub("LibWagoFramework")
local L = addon.L

local currentPage = 1

local pages = {}
local pagesToCreate = {}

function addon:RegisterPage(pageFunc)
  table.insert(pagesToCreate, pageFunc)
end

function addon:CreatePageProtoType(pageName)
  local parent = addon.frames.introFrame
  local pagePrototype = CreateFrame("Frame", addonName .. pageName, parent)
  ---@diagnostic disable-next-line: inject-field
  pagePrototype.pageName = pageName
  pagePrototype:SetPoint("TOPLEFT", parent, "TOPLEFT", 3, -25)
  pagePrototype:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -3, 40)
  pagePrototype:Hide()
  return pagePrototype
end

local function createStatusBar(parent)
  -- parent frame to give the statusbar a background
  local statusBar = CreateFrame("Frame", addonName .. "StatusBar", parent, "BackdropTemplate")
  addon.frames.introFrameStatusBar = statusBar
  statusBar:SetBackdropBorderColor(1, 0, 0, 0)
  statusBar:SetSize(400, 28)
  statusBar:SetFrameStrata("DIALOG")
  statusBar:SetFrameLevel(101)
  statusBar:SetPoint("BOTTOM", parent, "BOTTOM", 0, 6)
  DF:CreateBorder(statusBar, 1, 0, 0)

  -- actual status bar, child of parent above
  ---@diagnostic disable-next-line: inject-field
  statusBar.bar = CreateFrame("StatusBar", nil, statusBar)
  statusBar.bar:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
  statusBar.bar:SetStatusBarColor(unpack(addon.colorRGB))
  statusBar.bar:SetPoint("TOPLEFT", 0, 0)
  statusBar.bar:SetPoint("BOTTOMRIGHT", 0, 0)

  ---@diagnostic disable-next-line: inject-field
  statusBar.bar.text = statusBar.bar:CreateFontString()
  statusBar.bar.text:SetPoint("CENTER", statusBar, "CENTER")
  statusBar.bar.text:SetFontObject("GameFontNormalMed3")
  statusBar.bar.text:SetTextColor(1, 1, 1, 1)
  statusBar.bar.text:SetJustifyH("CENTER")
  statusBar.bar.text:SetJustifyV("MIDDLE")
  statusBar.bar.text:SetHeight(20)

  Mixin(statusBar.bar, SmoothStatusBarMixin)

  ---@diagnostic disable-next-line: undefined-field
  statusBar.bar:SetMinMaxSmoothedValue(0, #pages - 1)

  function addon:UpdateProgressBar(page)
    ---@diagnostic disable-next-line: undefined-field
    statusBar.bar:SetSmoothedValue(page - 1)
    local text = (page - 1) .. "/" .. #pages - 1
    statusBar.bar.text:SetText(text)
  end

  addon:UpdateProgressBar(currentPage)
end

function addon:CreateIntroFrame(f)
  local introFrame = CreateFrame("Frame", addonName .. "IntroFrame", f)
  introFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -10)
  introFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
  introFrame:Hide()
  addon.frames.introFrame = introFrame

  local nextButton = LWF:CreateButton(introFrame, 80, 30, "Next >>", 16)
  nextButton:SetPoint("BOTTOMRIGHT", introFrame, "BOTTOMRIGHT", -5, 5)
  nextButton:SetClickFunction(
    function()
      addon:NextPage()
    end
  )

  local prevButton = LWF:CreateButton(introFrame, 80, 30, "<< Back", 16)
  prevButton:SetPoint("BOTTOMLEFT", introFrame, "BOTTOMLEFT", 5, 5)
  prevButton:SetClickFunction(
    function()
      addon:PrevPage()
    end
  )

  function addon:ToggleNavigationButton(type, show)
    local button = type == "next" and nextButton or type == "prev" and prevButton
    if not button then
      return
    end
    if show then
      button:Show()
    else
      button:Hide()
    end
  end

  function addon:ToggleStatusBar(show)
    if show then
      addon.frames.introFrameStatusBar:Show()
    else
      addon.frames.introFrameStatusBar:Hide()
    end
  end

  for _, pageFunc in pairs(pagesToCreate) do
    table.insert(pages, pageFunc())
  end

  createStatusBar(introFrame)

  local function updatePages()
    for i = 1, #pages do
      pages[i]:Hide()
    end
    pages[currentPage]:Show()
    addon:UpdateProgressBar(currentPage)
  end

  hooksecurefunc(
    introFrame,
    "Show",
    function()
      updatePages()
      addon:UpdateProgressBar(currentPage)
    end
  )

  function addon:NextPage()
    currentPage = math.min(currentPage + 1, #pages)
    updatePages()
  end

  function addon:PrevPage()
    currentPage = math.max(currentPage - 1, 1)
    updatePages()
  end

  function addon:GotoPage(pageName)
    for i, page in ipairs(pages) do
      if page.pageName == pageName then
        currentPage = i
        updatePages()
        return
      end
    end
  end
end

function addon:ShowIntroFrame()
  addon.frames.introFrame:Show()
end
