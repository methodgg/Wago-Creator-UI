local addonName, addon = ...;
local DF = _G["DetailsFramework"];
local L = addon.L

local pageName = "ResolutionPage"
local page
local availableResolutions
local resolutionButtons = {}

local function isScreenResolutionCorrect(selectedResolution)
  local resolution = C_VideoOptions.GetCurrentGameWindowSize()
  local w = resolution.x
  local h = resolution.y
  if selectedResolution == "1080" then
    if w == 1920 and h == 1080 then
      return true
    end
  elseif selectedResolution == "1440" then
    if w == 2560 and h == 1440 then
      return true
    end
  end
  local supported = (w == 1920 and h == 1080) or (w == 2560 and h == 1440)
  return false, w, h, supported
end

local function addButtonToPage(button, i, total)
  button:Show()
  -- 3 buttons next to each other then a new row
  if total == 1 then
    button:SetPoint("CENTER", page, "CENTER", 0, -30)
  end
  if total == 2 then
    button:SetPoint("CENTER", page, "CENTER", i == 1 and -150 or 150, -30)
  end
end

local onShow = function()
  addon:ToggleNavigationButton("prev", true)
  addon:ToggleNavigationButton("next", false)
  addon:ToggleStatusBar(true)
  for _, button in pairs(resolutionButtons) do
    button:Hide()
    button:ClearAllPoints()
  end
  availableResolutions = addon:GetResolutionsForDropdown()
  for i, data in ipairs(availableResolutions) do
    local button = resolutionButtons[data.value]
    if not button then
      button = addon.DF:CreateResolutionButton(page, data.label)
      resolutionButtons[data.value] = button
    end
    button:SetClickFunction(function()
      local isCorrect, w, h, supported = isScreenResolutionCorrect(data.value)
      local successCallback = function()
        data.onclick()
        addon:NextPage()
      end
      if not isCorrect then
        local warning = string.format(L["WRONG_RESOLUTION_WARNING"], data.label, w, h, "")
        -- not supported and "This resolution is not supported!" or "")
        addon.DF:ShowPrompt(warning, successCallback)
        return
      end
      successCallback()
    end)
    addButtonToPage(resolutionButtons[data.value], i, #availableResolutions)
  end
end

local function createPage()
  page = addon:CreatePageProtoType(pageName)

  local header = DF:CreateLabel(page, L["Choose the Resolution that fits your UI and Monitor best"], 28, "white");
  header:SetWidth(page:GetWidth() - 10)
  header:SetJustifyH("CENTER")
  header:SetPoint("TOP", page, "TOP", 0, -160);

  page:SetScript("OnShow", onShow)
  return page
end

addon:RegisterPage(createPage)
