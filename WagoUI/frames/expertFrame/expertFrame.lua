local addonName, addon = ...;
local DF = _G["DetailsFramework"];
local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE");
local db
local L = addon.L

local widths = {
  options = 60,
  name = 350,
  profile = 200,
  -- version = 100,
  lastUpdate = 150,
}

local uiPackDropdown, resolutionDropdown

local onShow = function()
  if uiPackDropdown then
    uiPackDropdown:Select(addon.db.selectedWagoData)
    resolutionDropdown:Select(addon.db.selectedWagoDataResolution)
  end
end

function addon:CreateExpertFrame(f)
  local expertFrame = CreateFrame("Frame", addonName.."ExpertFrame", f)
  expertFrame:SetAllPoints(f)
  expertFrame:Hide()
  addon.frames.expertFrame = expertFrame
  db = addon.db
  local frameWidth = expertFrame:GetWidth() - 0
  local frameHeight = expertFrame:GetHeight() - 40
  local initialXOffset = 2
  local initialYOffset = -30

  local totalHeight = -initialYOffset
  local function addLine(widgets, xOffset, yOffset, xGap, yGap)
    xOffset = xOffset or 0
    yOffset = yOffset or 0
    xGap = xGap or 10
    yGap = yGap or 10
    local maxHeight = 0
    for i, widget in ipairs(widgets) do
      if i == 1 then
        widget:SetPoint("TOPLEFT", expertFrame, "TOPLEFT", xOffset + initialXOffset, 0 - totalHeight + yOffset)
      else
        widget:SetPoint("LEFT", widgets[i - 1], "RIGHT", xGap + xOffset, 0)
      end
      maxHeight = math.max(maxHeight, widget:GetHeight())
    end
    totalHeight = totalHeight + maxHeight + yGap - yOffset
  end


  local wagoDataDropdownFunc = function() return addon:GetWagoDataForDropdown() end
  uiPackDropdown = addon.DF:CreateDropdown(expertFrame, 180, 40, 16, 1.2, wagoDataDropdownFunc)
  if not db.selectedWagoData then
    uiPackDropdown:NoOptionSelected()
  else
    uiPackDropdown:Select(db.selectedWagoData)
  end

  local resolutionDropdownFunc = function() return addon:GetResolutionsForDropdown() end
  resolutionDropdown = addon.DF:CreateDropdown(expertFrame, 180, 40, 16, 1.2, resolutionDropdownFunc)
  if not db.selectedWagoDataResolution then
    if resolutionDropdown.func()[1] and resolutionDropdown.func()[1].value then
      resolutionDropdown:Select(resolutionDropdown.func()[1].value)
      db.selectedWagoDataResolution = resolutionDropdown.func()[1].value
    else
      resolutionDropdown:NoOptionSelected()
    end
  else
    resolutionDropdown:Select(db.selectedWagoDataResolution)
  end

  function addon:RefreshResolutionDropdown()
    resolutionDropdown:Refresh()                             --update the dropdown options
    resolutionDropdown:Close()
    resolutionDropdown:Select(db.selectedWagoDataResolution) --selected profile could have been renamed, need to refresh like this
    local values = {}
    for _, v in pairs(resolutionDropdown.func()) do          --if the selected profile got deleted
      if v.value then values[v.value] = true end
    end
    if not db.selectedWagoDataResolution or not values[db.selectedWagoDataResolution] then
      --pick first one
      if resolutionDropdown.func()[1] and resolutionDropdown.func()[1].value then
        resolutionDropdown:Select(resolutionDropdown.func()[1].value)
        db.selectedWagoDataResolution = resolutionDropdown.func()[1].value
      else
        resolutionDropdown:NoOptionSelected()
        db.selectedWagoDataResolution = nil
      end
    end
  end

  local introButton = addon.DF:CreateButton(expertFrame, 100, 40, L["Intro"], 16)
  introButton:SetClickFunction(function()
    addon.frames.introFrame:Show()
    addon.frames.expertFrame:Hide()
    addon.db.introEnabled = true
  end);

  local altButton = addon.DF:CreateButton(expertFrame, 160, 40, L["Alt Character"], 16)
  altButton:SetClickFunction(function()
    addon:SetAltFrameHeaderText(L["altFrameHeader3"])
    addon.frames.altFrame:Show()
    addon.frames.expertFrame:Hide()
  end);

  -- TODO: An update all button is not really possible
  -- some modules require user input to continue importing/updating (WA / EchoRT)

  -- local updateAllButton = DF:CreateButton(f, nil, 250, 40, L["Update All"], nil, nil, nil, nil, nil, nil,
  --   options_dropdown_template);
  -- updateAllButton.text_overlay:SetFont(updateAllButton.text_overlay:GetFont(), 16);
  -- updateAllButton:SetClickFunction(function()
  --   --TODO: Implement
  --   print("Updating All")
  -- end);
  -- f.updateAllButton = updateAllButton

  addLine({ uiPackDropdown, resolutionDropdown, introButton, altButton --[[, updateAllButton ]] }, 0, 0)

  db.selectedWagoDataTab = db.selectedWagoDataTab or 1
  local profileTabButton = addon.DF:CreateTabButton(expertFrame, (frameWidth / 2) - 2, 40, L["Profiles"], 16)
  local weakaurasTabButton = addon.DF:CreateTabButton(expertFrame, (frameWidth / 2) - 2, 40, L["WeakAuras"], 16)
  addLine({ profileTabButton, weakaurasTabButton }, 0, 0, 0, 0)

  local profileList = addon.DF:CreateProfileList(expertFrame, frameWidth, frameHeight - totalHeight + 4)

  local updateData = function(data)
    local filtered = {}
    if data then
      if db.selectedWagoDataTab == 1 then
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
      if db.selectedWagoDataTab == 2 then
        for _, entry in ipairs(data) do
          if entry.moduleName == "WeakAuras" or entry.moduleName == "Echo Raid Tools" then
            tinsert(filtered, entry)
          end
        end
        --sort weakauras on top, alphabetically afterwards
        table.sort(filtered, function(a, b)
          local orderA = a.moduleName == "WeakAuras" and 1 or 0
          local orderB = b.moduleName == "WeakAuras" and 1 or 0
          if orderA == orderB then
            return a.entryName < b.entryName
          end
          return orderA > orderB
        end)
      end
    end
    profileList.updateData(filtered)
  end

  addon:RegisterDataConsumer(updateData)

  local tabFunction = function(tabIndex)
    db.selectedWagoDataTab = tabIndex
    addon:UpdateRegisteredDataConsumers()
  end
  addon.DF:CreateTabStructure({ profileTabButton, weakaurasTabButton }, tabFunction, db.selectedWagoDataTab)

  addLine({ profileList.header }, 0, 0)

  expertFrame:SetScript("OnShow", onShow)
end

function addon:ShowExpertFrame()
  local wagoData = addon:GetWagoDataForDropdown()
  if #wagoData == 0 then
    addon.frames.introFrame:Show()
    addon.frames.expertFrame:Hide()
    return
  end
  addon.frames.expertFrame:Show()
end
