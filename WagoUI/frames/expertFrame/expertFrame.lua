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

function addon:CreateExpertFrame(f)
  local profileFrame = CreateFrame("Frame", addonName.."ExpertFrame", f)
  profileFrame:SetAllPoints(f)
  profileFrame:Hide()
  addon.frames.profileFrame = profileFrame
  db = addon.db
  local frameWidth = profileFrame:GetWidth() - 0
  local frameHeight = profileFrame:GetHeight() - 40
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
        widget:SetPoint("TOPLEFT", profileFrame, "TOPLEFT", xOffset + initialXOffset, 0 - totalHeight + yOffset)
      else
        widget:SetPoint("LEFT", widgets[i - 1], "RIGHT", xGap + xOffset, 0)
      end
      maxHeight = math.max(maxHeight, widget:GetHeight())
    end
    totalHeight = totalHeight + maxHeight + yGap - yOffset
  end


  local wagoDataDropdownFunc = function() return addon:GetWagoDataForDropdown() end
  local wagoDataDropdown = addon.DF:CreateDropdown(profileFrame, 180, 40, 16, wagoDataDropdownFunc)
  if not db.selectedWagoData then
    wagoDataDropdown:NoOptionSelected()
  else
    wagoDataDropdown:Select(db.selectedWagoData)
  end

  local resolutionDropdownFunc = function() return addon:GetResolutionsForDropdown() end
  local resolutionDropdown = addon.DF:CreateDropdown(profileFrame, 180, 40, 16, resolutionDropdownFunc)
  if not db.selectedWagoDataResolution then
    resolutionDropdown:NoOptionSelected()
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
      resolutionDropdown:NoOptionSelected()
      db.selectedWagoDataResolution = nil
    end
  end

  local introButton = addon.DF:CreateButton(profileFrame, 100, 40, "Intro", 16)
  introButton:SetClickFunction(function()
    addon.frames.introFrame:Show()
    addon.frames.profileFrame:Hide()
    addon.db.introEnabled = true
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

  addLine({ wagoDataDropdown, resolutionDropdown, introButton --[[, updateAllButton ]] }, 0, 0)

  db.selectedWagoDataTab = db.selectedWagoDataTab or 1
  local profileTabButton = addon.DF:CreateTabButton(profileFrame, (frameWidth / 2) - 2, 40, "Profiles", 16)
  local weakaurasTabButton = addon.DF:CreateTabButton(profileFrame, (frameWidth / 2) - 2, 40, "Weakauras", 16)
  addLine({ profileTabButton, weakaurasTabButton }, 0, 0, 0, 0)

  local profileList = addon.DF.CreateProfileList(profileFrame, frameWidth, frameHeight - totalHeight + 4)

  local tabFunction = function(tabIndex)
    db.selectedWagoDataTab = tabIndex
    if db.selectedWagoDataResolution and addon.wagoData then
      profileList.updateData(addon.wagoData[db.selectedWagoDataResolution][db.selectedWagoDataTab])
    end
  end
  addon.DF:CreateTabStructure({ profileTabButton, weakaurasTabButton }, tabFunction, db.selectedWagoDataTab)

  addLine({ profileList.header }, 0, 0)
end
