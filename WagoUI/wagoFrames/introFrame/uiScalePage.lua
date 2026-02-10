---@class WagoUI
local addon = select(2, ...)
local DF = _G["DetailsFramework"]
local LWF = LibStub("LibWagoFramework")
local LAP = LibStub("LibAddonProfiles")
local L = addon.L

local pageName = "UIScalePage"
local page
local hasSkipped = false
local optionButtons = {}
local selectedOptionKey
local appliedLabel
local minimumScaleWithoutElvUI = 0.64

local function markReloadRequired()
  addon.state.needReload = true
  addon:ToggleReloadIndicator(true, L["IMPORT_RELOAD_WARNING1"])
end

---@return boolean
local function hasElvUIInstalled()
  if not C_AddOns or not C_AddOns.GetAddOnMetadata then
    return false
  end
  return C_AddOns.GetAddOnMetadata("ElvUI", "Version") ~= nil
end

---@param value number | string | nil
---@return string | nil
local function getUiScaleKey(value)
  local n = tonumber(value)
  if not n then
    return nil
  end
  return string.format("%.2f", n)
end

---@param button table
---@param option table
---@param recommendedKey string | nil
local function styleButton(button, option, recommendedKey)
  local text = string.format(L["UISCALE_INTRO_APPLY"], option.value)
  local isRecommended = option.key == recommendedKey
  if isRecommended then
    text = "|cff4ccf63" .. text .. "\n" .. L["UISCALE_INTRO_RECOMMENDED"]
  end
  if selectedOptionKey == option.key then
    text = text .. "\n" .. L["UISCALE_INTRO_CURRENT"]
  end
  if isRecommended then
    text = text .. "|r"
  end
  button:SetText(text)
end

---@param options table<number, table>
---@param recommendedKey string | nil
local function refreshButtonStyles(options, recommendedKey)
  for i, option in ipairs(options) do
    local button = optionButtons[i]
    if button then
      styleButton(button, option, recommendedKey)
    end
  end
end

---@param value number
---@return boolean
local function applyUiScale(value)
  local normalized = tonumber(string.format("%.2f", value))
  if not normalized then
    return false
  end

  local success = pcall(
    function()
      SetCVar("useUiScale", "1")
      SetCVar("uiScale", string.format("%.2f", normalized))

      local elvuiModule = LAP:GetModule("ElvUI")
      if elvuiModule and elvuiModule:isLoaded() then
        local E = ElvUI and ElvUI[1]
        if E and E.global and E.global.general then
          E.global.general.UIScale = normalized
        end
        if E and E.PixelScaleChanged then
          E:PixelScaleChanged()
        end
      end
    end
  )

  if success then
    selectedOptionKey = getUiScaleKey(normalized)
  end
  return success
end

---@param setupOptions table<number, table>
---@param recommendedKey string | nil
---@return table<number, table>, string | nil
local function getFilteredOptions(setupOptions, recommendedKey)
  if hasElvUIInstalled() then
    return setupOptions, recommendedKey
  end

  local filteredOptions = {}
  for _, option in ipairs(setupOptions) do
    if option.value >= minimumScaleWithoutElvUI then
      tinsert(filteredOptions, option)
    end
  end

  local filteredRecommended = recommendedKey
  local hasRecommendedAfterFilter = false
  for _, option in ipairs(filteredOptions) do
    if option.key == filteredRecommended then
      hasRecommendedAfterFilter = true
      break
    end
  end
  if not hasRecommendedAfterFilter then
    filteredRecommended = nil
  end

  return filteredOptions, filteredRecommended
end

---@param options table<number, table>
---@param recommendedKey string | nil
local function updateOptions(options, recommendedKey)
  local total = #options
  local columns = total > 1 and 2 or 1
  local buttonWidth = columns == 1 and 380 or 250
  local xOffset = columns == 1 and 0 or 150

  for i, option in ipairs(options) do
    local button = optionButtons[i]
    if not button then
      button = LWF:CreateButton(page, buttonWidth, 54, "", 18)
      optionButtons[i] = button
    end
    button:SetSize(buttonWidth, 54)
    button.option = option
    button:ClearAllPoints()
    local col = (i - 1) % columns
    local row = math.floor((i - 1) / columns)
    local x = columns == 1 and 0 or (col == 0 and -xOffset or xOffset)
    local y = -150 - (row * 64)
    button:SetPoint("TOP", page, "TOP", x, y)
    styleButton(button, option, recommendedKey)
    button:SetClickFunction(
      function()
        if not button.option then
          return
        end
        local previousOptionKey = selectedOptionKey
        local requestedOptionKey = button.option.key or getUiScaleKey(button.option.value)
        local success = applyUiScale(button.option.value)
        if success then
          if previousOptionKey ~= requestedOptionKey then
            markReloadRequired()
          end
          appliedLabel:SetText(string.format(L["UISCALE_INTRO_APPLIED"], button.option.value))
          appliedLabel:SetTextColor(0.4, 1, 0.4, 1)
          refreshButtonStyles(options, recommendedKey)
        else
          appliedLabel:SetText(L["UISCALE_INTRO_APPLY_ERROR"])
          appliedLabel:SetTextColor(1, 0.3, 0.3, 1)
        end
      end
    )
    button:Show()
  end

  for i = total + 1, #optionButtons do
    optionButtons[i]:Hide()
    optionButtons[i].option = nil
  end
end

local onShow = function()
  addon.db.introState.currentPage = pageName
  addon.db.introEnabled = true
  addon:ToggleNavigationButton("prev", true)
  addon:ToggleNavigationButton("next", true)

  local setup = addon.state.uiScaleSetup
  if not setup or not setup.enabled or not setup.options or #setup.options == 0 then
    if not hasSkipped then
      hasSkipped = true
      addon:NextPage()
    end
    return
  end

  local filteredOptions, filteredRecommended = getFilteredOptions(setup.options, setup.recommended)

  if #filteredOptions == 0 then
    if not hasSkipped then
      hasSkipped = true
      addon:NextPage()
    end
    return
  end
  hasSkipped = false

  selectedOptionKey = getUiScaleKey(GetCVar("uiScale"))
  appliedLabel:SetText("")
  updateOptions(filteredOptions, filteredRecommended)
end

local function createPage()
  page = addon:CreatePageProtoType(pageName)
  page:SetScript("OnShow", onShow)

  local header = DF:CreateLabel(page, L["UISCALE_INTRO_HEADER"], 30, "white")
  header:SetWidth(page:GetWidth() - 30)
  header:SetJustifyH("CENTER")
  header:SetPoint("TOP", page, "TOP", 0, -30)

  local subHeader = DF:CreateLabel(page, L["UISCALE_INTRO_SUBHEADER"], 18, "white")
  subHeader:SetWidth(page:GetWidth() - 40)
  subHeader:SetJustifyH("CENTER")
  subHeader:SetPoint("TOP", header, "BOTTOM", 0, -12)

  appliedLabel = DF:CreateLabel(page, "", 16, "white")
  appliedLabel:SetWidth(page:GetWidth() - 30)
  appliedLabel:SetJustifyH("CENTER")
  appliedLabel:SetPoint("BOTTOM", page, "BOTTOM", 0, 60)

  return page
end

addon:RegisterPage(createPage)
