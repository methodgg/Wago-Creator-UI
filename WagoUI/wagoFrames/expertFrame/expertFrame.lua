---@type string
local addonName = ...
---@class WagoUI
local addon = select(2, ...)
local LWF = LibStub("LibWagoFramework")
local DF = _G["DetailsFramework"]
local LAP = LibStub("LibAddonProfiles")
local db
local L = addon.L

local uiPackDropdown, resolutionDropdown

local onShow = function()
  if uiPackDropdown then
    uiPackDropdown:Select(addon.db.selectedWagoData)
    resolutionDropdown:Select(addon.db.selectedWagoDataResolution)
  end
  addon.state.hasSetupSplitView = false
end

function addon:CreateExpertFrame(f)
  local expertFrame = CreateFrame("Frame", addonName.."ExpertFrame", f)
  expertFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -10)
  expertFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
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

  local wagoDataDropdownFunc = function()
    return addon:GetWagoDataForDropdown()
  end
  uiPackDropdown = LWF:CreateDropdown(expertFrame, 250, 40, 16, 1.2, wagoDataDropdownFunc)
  if not db.selectedWagoData then
    uiPackDropdown:NoOptionSelected()
  else
    uiPackDropdown:Select(db.selectedWagoData)
  end

  function addon:SetUIPackDropdownToPack(packId)
    uiPackDropdown:Select(packId)
  end

  local resolutionDropdownFunc = function()
    return addon:GetResolutionsForDropdown()
  end
  resolutionDropdown = LWF:CreateDropdown(expertFrame, 180, 40, 16, 1.2, resolutionDropdownFunc)
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
      if v.value then
        values[v.value] = true
      end
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

  local introButton = LWF:CreateButton(expertFrame, 100, 40, L["Intro"], 16)
  introButton:SetClickFunction(
    function()
      addon.frames.introFrame:Show()
      addon.frames.expertFrame:Hide()
      addon.db.introEnabled = true
    end
  )

  local altButton = LWF:CreateButton(expertFrame, 160, 40, L["Alt Character"], 16)
  if not addon.db.anyInstalled then
    altButton:Disable()
  end
  altButton:SetClickFunction(
    function()
      addon:SetAltFrameHeaderText(L["altFrameHeader3"])
      addon.frames.altFrame:Show()
      addon.frames.expertFrame:Hide()
    end
  )

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

  local profileList = addon:CreateProfileList(expertFrame, frameWidth, frameHeight - totalHeight - 30)

  local updateData = function(data)
    local filtered = {}
    if data then
      for _, entry in ipairs(data) do
        tinsert(filtered, entry)
      end
      --sort disabled modules to bottom, alphabetically afterwards, WAs at bottom
      table.sort(
        filtered,
        function(a, b)
          local orderA = (a.lap:isLoaded() or a.lap:needsInitialization()) and 1 or 0
          local orderB = (b.lap:isLoaded() or b.lap:needsInitialization()) and 1 or 0
          if a.moduleName == "WeakAuras" then
            orderA = orderA - 100
          end
          if b.moduleName == "WeakAuras" then
            orderB = orderB - 100
          end
          if a.moduleName == "WeakAuras" and b.moduleName == "WeakAuras" then
            return a.entryName < b.entryName
          elseif orderA == orderB then
            return a.moduleName < b.moduleName
          end
          return orderA > orderB
        end
      )
    end
    profileList.updateData(filtered)
  end

  addon:RegisterDataConsumer(updateData)
  addon:UpdateRegisteredDataConsumers()

  addLine({ profileList.header }, 0, 0)

  local text = L["Scroll down for WeakAuras!"]
  local footer = DF:CreateLabel(expertFrame, text, 22, "white")
  footer:SetJustifyH("CENTER")
  footer:SetPoint("BOTTOM", expertFrame, "BOTTOM", 0, 15)
  local waLap = LAP:GetModule("WeakAuras")
  local warningIconLeft = LWF:CreateIconButton(expertFrame, 30, waLap.icon)
  local warningIconRight = LWF:CreateIconButton(expertFrame, 30, waLap.icon)
  warningIconLeft:SetPoint("RIGHT", footer, "LEFT", -5, 0)
  warningIconRight:SetPoint("LEFT", footer, "RIGHT", 5, 0)

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
