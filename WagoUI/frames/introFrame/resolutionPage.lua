---@class WagoUI
local addon = select(2, ...)
local DF = _G["DetailsFramework"];
local LWF = LibStub("LibWagoFramework")
local L = addon.L

local pageName = "ResolutionPage"
local page
local availableResolutions
local resolutionButtons = {}
local hasCheckedAutoClickOnce = false

---@param selectedResolution string
---@return boolean
---@return number|nil
---@return number|nil
---@return boolean|nil
local function isScreenResolutionCorrect(selectedResolution)
  local detectedRes = C_VideoOptions.GetCurrentGameWindowSize()

  local matchedResolution
  for _, entry in ipairs(addon.resolutions.entries) do
    if entry.value == selectedResolution then
      matchedResolution = entry
      break
    end
  end

  -- resolution does not even exist (should not happen)
  if not matchedResolution then return false, detectedRes.x, detectedRes.y, false end

  -- "Any Resolution" is always correct
  if not matchedResolution.width or not matchedResolution.height then
    return true
  end

  -- resolution matches
  if matchedResolution.width == detectedRes.x and matchedResolution.height == detectedRes.y then
    return true
  end
  -- resolution does not match
  local supported = (detectedRes.x == 1920 and detectedRes.y == 1080)
      or (detectedRes.x == 2560 and detectedRes.y == 1440)

  return false, detectedRes.x, detectedRes.y, supported
end

---@alias addButtonToPage function
local function addButtonToPage(button, i, total)
  button:Show()
  -- 3 buttons next to each other then a new row
  if total == 1 then
    button:SetPoint("CENTER", page, "CENTER", 0, -30)
  elseif total == 2 then
    button:SetPoint("CENTER", page, "CENTER", i == 1 and -150 or 150, -30)
  elseif total == 3 then
    button:SetPoint("CENTER", page, "CENTER", i == 1 and -260 or i == 2 and 0 or 260, -30)
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
    local button = resolutionButtons[i]
    if not button then
      button = LWF:CreateBigChoiceButton(page, data.label)
      resolutionButtons[i] = button
    end
    button:SetText(data.label)
    button:SetClickFunction(function()
      local isCorrect, w, h, supported = isScreenResolutionCorrect(data.value)
      local successCallback = function()
        data.onclick()
        addon:NextPage()
      end
      if not isCorrect then
        local warning = string.format(L["WRONG_RESOLUTION_WARNING"],
          addon:GetResolutionString(data.value, "displayNameLong"), w, h, "")
        addon:ShowPrompt(warning, successCallback)
        return
      end
      successCallback()
    end)
    addButtonToPage(resolutionButtons[i], i, #availableResolutions)
  end
  -- auto select if only one resolution is available
  if #availableResolutions <= 1 and not hasCheckedAutoClickOnce then
    if resolutionButtons[1] then
      hasCheckedAutoClickOnce = true
      if isScreenResolutionCorrect(availableResolutions[1].value) then
        resolutionButtons[1]:Click()
      end
    end
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
