---@class WagoUICreator
local addon = select(2, ...)
local L = addon.L
local moduleName = "UI Scale"
local LAP = LibStub:GetLibrary("LibAddonProfiles")
local lapModule = LAP:GetModule(moduleName)
local DF = _G["DetailsFramework"]
local LWF = LibStub("LibWagoFramework")

local m
local isRefreshingRows = false

local frameWidth = 760
local frameHeight = 620
local optionRowsMax = 12
local recommendedColumnStartX = 545
local commonScaleLabels = {
  ["0.36"] = "4k",
  ["0.53"] = "1440p",
  ["0.64"] = "1200p",
  ["0.71"] = "1080p",
}
local defaultOptions = {
  0.36,
  0.53,
  0.64,
  0.71,
  1.00
}
local minimumScaleWithoutElvUI = 0.64

---@class UiScaleOption
---@field key string
---@field value number
---@field label string
---@field isElvuiCurrent boolean
---@field lockedWithoutElvui boolean

---@param value number | string | nil
---@return number | nil
local function normalizeScaleValue(value)
  local n = tonumber(value)
  if not n then
    return nil
  end
  return tonumber(string.format("%.2f", n))
end

---@param value number | string | nil
---@return string | nil
local function getScaleKey(value)
  local normalized = normalizeScaleValue(value)
  if not normalized then
    return nil
  end
  return string.format("%.2f", normalized)
end

---@return table | nil
local function getCurrentPack()
  return addon:GetCurrentPackStashed()
end

---@return table | nil
local function getUiScaleSetup()
  local pack = getCurrentPack()
  if not pack then
    return nil
  end
  pack.uiScaleSetup = pack.uiScaleSetup or {
    enabled = false,
    options = {},
    recommended = nil
  }
  pack.uiScaleSetup.options = pack.uiScaleSetup.options or {}
  if pack.uiScaleSetup.recommended and not pack.uiScaleSetup.options[pack.uiScaleSetup.recommended] then
    pack.uiScaleSetup.recommended = nil
  end
  return pack.uiScaleSetup
end

---@return number | nil
local function getElvUICurrentScale()
  local elvuiModule = LAP:GetModule("ElvUI")
  if not elvuiModule or not elvuiModule:isLoaded() then
    return nil
  end
  local E = ElvUI and ElvUI[1]
  if not E or not E.global or not E.global.general then
    return nil
  end
  return normalizeScaleValue(E.global.general.UIScale)
end

---@return boolean
local function hasElvUILoaded()
  local elvuiModule = LAP:GetModule("ElvUI")
  return elvuiModule and elvuiModule:isLoaded() or false
end

---@param setup table | nil
---@param elvuiLoaded boolean
---@return UiScaleOption[]
local function buildUiScaleOptions(setup, elvuiLoaded)
  if not setup then
    return {}
  end
  ---@type table<string, UiScaleOption>
  local optionsByKey = {}
  local function addOption(value, isElvuiCurrent)
    local normalized = normalizeScaleValue(value)
    local key = getScaleKey(normalized)
    if not normalized or not key then
      return
    end
    optionsByKey[key] = optionsByKey[key] or {
      key = key,
      value = normalized,
      isElvuiCurrent = false,
    }
    optionsByKey[key].isElvuiCurrent = optionsByKey[key].isElvuiCurrent or isElvuiCurrent
  end

  for _, value in ipairs(defaultOptions) do
    addOption(value, false)
  end

  for key, value in pairs(setup.options) do
    local optionValue = value == true and key or value
    addOption(optionValue or key, false)
  end

  local elvuiScale = getElvUICurrentScale()
  if elvuiScale then
    addOption(elvuiScale, true)
  end

  ---@type UiScaleOption[]
  local options = {}
  for _, option in pairs(optionsByKey) do
    option.lockedWithoutElvui = not elvuiLoaded and option.value < minimumScaleWithoutElvUI
    option.label = string.format(L["UISCALE_OPTION_LABEL"], option.value)
    local commonLabel = commonScaleLabels[option.key]
    if commonLabel then
      option.label = option.label.." ("..commonLabel..")"
    end
    if option.lockedWithoutElvui then
      option.label = option.label.." "..L["UISCALE_OPTION_ELVUI_REQUIRED"]
    end
    if option.isElvuiCurrent then
      option.label = option.label.." "..L["UISCALE_OPTION_ELVUI_TAG"]
    end
    tinsert(options, option)
  end

  table.sort(
    options,
    function(a, b)
      return a.value < b.value
    end
  )

  return options
end

local function refreshCreatorContent()
  if addon.frames.mainFrame and addon.frames.mainFrame.frameContent and addon.frames.mainFrame.frameContent.contentScrollbox then
    addon.frames.mainFrame.frameContent.contentScrollbox:Refresh()
  end
end

---@param setup table
---@param options UiScaleOption[]
---@param elvuiLoaded boolean
local function sanitizeSetupSelection(setup, options, elvuiLoaded)
  local availableByKey = {}
  for _, option in ipairs(options) do
    availableByKey[option.key] = true
    if not elvuiLoaded and option.lockedWithoutElvui then
      if setup.options[option.key] then
        setup.options[option.key] = nil
      end
      if setup.recommended == option.key then
        setup.recommended = nil
      end
    end
  end

  if setup.recommended and not availableByKey[setup.recommended] then
    setup.recommended = nil
  end

  for key in pairs(setup.options) do
    if not availableByKey[key] then
      setup.options[key] = nil
    end
  end

  if setup.recommended and not setup.options[setup.recommended] then
    setup.recommended = nil
  end
end

---@param optionsCount number
local function positionRestrictionLabel(optionsCount)
  local lastVisibleRowIndex = math.min(optionsCount, optionRowsMax)
  local anchorRow = m.optionRows[lastVisibleRowIndex] or m.optionRows[optionRowsMax]
  if not anchorRow then
    return
  end
  m.elvuiRestrictionLabel:ClearAllPoints()
  m.elvuiRestrictionLabel:SetPoint("TOPLEFT", anchorRow, "BOTTOMLEFT", 0, -8)
end

local function refreshManageFrame()
  if not m then
    return
  end
  local setup = getUiScaleSetup()
  if not setup then
    return
  end

  local elvuiLoaded = hasElvUILoaded()
  local options = buildUiScaleOptions(setup, elvuiLoaded)
  sanitizeSetupSelection(setup, options, elvuiLoaded)

  isRefreshingRows = true
  m.enableCheckbox:SetValue(setup.enabled)

  positionRestrictionLabel(#options)
  m.elvuiRestrictionLabel:Show()

  for i = 1, optionRowsMax do
    local row = m.optionRows[i]
    local option = options[i]
    if option then
      row.option = option
      row:Show()
      row.label:SetText(option.label)

      local isIncluded = setup.options[option.key] ~= nil
      row.includeCheckbox:SetValue(isIncluded)
      row.recommendedCheckbox:SetValue(setup.recommended == option.key and isIncluded)

      if setup.enabled then
        local canToggle = not option.lockedWithoutElvui
        if canToggle then
          row.includeCheckbox:Enable()
          row.recommendedCheckbox:Enable()
        else
          row.includeCheckbox:Disable()
          row.recommendedCheckbox:Disable()
        end
        if option.lockedWithoutElvui then
          row.label:SetTextColor(0.5, 0.5, 0.5, 1)
        else
          row.label:SetTextColor(1, 1, 1, 1)
        end
      else
        row.includeCheckbox:Disable()
        row.recommendedCheckbox:Disable()
        row.label:SetTextColor(0.5, 0.5, 0.5, 1)
      end
    else
      row.option = nil
      row:Hide()
    end
  end

  isRefreshingRows = false
end

local function createManageFrame(w, h)
  local panelOptions = {
    DontRightClickClose = true,
    NoTUISpecialFrame = false
  }
  m = DF:CreateSimplePanel(UIParent, w, h, "", nil, panelOptions)
  LWF:ScaleFrameByUIParentScale(m, 0.5333333333333)
  DF:ApplyStandardBackdrop(m)
  DF:CreateBorder(m)
  m:ClearAllPoints()
  m:SetFrameStrata("FULLSCREEN")
  m:SetFrameLevel(100)
  m.__background:SetAlpha(1)
  m:SetMouseClickEnabled(true)
  m:SetTitle(L["UI Scale"])
  m:Hide()
  m.buttons = {}
  m.StartMoving = function()
  end

  local explainerLabel = DF:CreateLabel(m, L["UISCALE_MANAGE_EXPLAINER"], 17, "white")
  explainerLabel:SetPoint("TOPLEFT", m, "TOPLEFT", 10, -40)
  explainerLabel:SetPoint("TOPRIGHT", m, "TOPRIGHT", -10, -40)

  m.enableCheckbox = LWF:CreateCheckbox(
    m,
    44,
    function(_, _, value)
      if isRefreshingRows then
        return
      end
      local setup = getUiScaleSetup()
      if not setup then
        return
      end
      setup.enabled = value and true or false
      refreshManageFrame()
      refreshCreatorContent()
    end,
    false
  )
  m.enableCheckbox:SetPoint("TOPLEFT", m, "TOPLEFT", 40, -140)

  local enableLabel = DF:CreateLabel(m, L["UISCALE_ENABLE_LABEL"], 22, "white")
  enableLabel:SetPoint("LEFT", m.enableCheckbox, "RIGHT", 10, 0)

  local enableHint = DF:CreateLabel(m, L["UISCALE_ENABLE_HINT"], 14, "grey")
  enableHint:SetPoint("TOPLEFT", enableLabel, "BOTTOMLEFT", 0, -2)

  local sectionLabel = DF:CreateLabel(m, L["UISCALE_OPTION_SECTION_LABEL"], 16, "white")
  sectionLabel:SetPoint("TOPLEFT", m, "TOPLEFT", 40, -200)

  local includeLabel = DF:CreateLabel(m, L["UISCALE_OPTION_INCLUDE_LABEL"], 12, "white")
  includeLabel:SetPoint("TOPLEFT", m, "TOPLEFT", 40, -224)

  local recommendedLabel = DF:CreateLabel(m, L["UISCALE_OPTION_RECOMMENDED_LABEL"], 12, "white")
  recommendedLabel:SetPoint("TOPLEFT", m, "TOPLEFT", recommendedColumnStartX, -224)

  m.elvuiRestrictionLabel = DF:CreateLabel(m, L["UISCALE_ELVUI_REQUIRED_HINT"], 12, "white")
  m.elvuiRestrictionLabel:Hide()

  m.optionRows = {}
  for i = 1, optionRowsMax do
    local row = CreateFrame("Frame", nil, m)
    row:SetSize(650, 24)
    row:SetPoint("TOPLEFT", m, "TOPLEFT", 40, -246 - ((i - 1) * 25))

    row.includeCheckbox = LWF:CreateCheckbox(
      row,
      20,
      function(_, _, value)
        if isRefreshingRows or not row.option then
          return
        end
        if row.option.lockedWithoutElvui and value then
          row.includeCheckbox:SetValue(false)
          return
        end
        local setup = getUiScaleSetup()
        if not setup then
          return
        end
        if value then
          setup.options[row.option.key] = row.option.value
        else
          setup.options[row.option.key] = nil
          if setup.recommended == row.option.key then
            setup.recommended = nil
          end
        end
        refreshManageFrame()
        refreshCreatorContent()
      end,
      false
    )
    row.includeCheckbox:SetPoint("LEFT", row, "LEFT", 0, 0)

    row.label = DF:CreateLabel(row, "", 14, "white")
    row.label:SetPoint("LEFT", row.includeCheckbox, "RIGHT", 10, 0)

    row.recommendedCheckbox = LWF:CreateCheckbox(
      row,
      18,
      function(_, _, value)
        if isRefreshingRows or not row.option then
          return
        end
        local setup = getUiScaleSetup()
        if not setup then
          return
        end
        if value then
          setup.options[row.option.key] = row.option.value
          setup.recommended = row.option.key
        elseif setup.recommended == row.option.key then
          setup.recommended = nil
        end
        refreshManageFrame()
        refreshCreatorContent()
      end,
      false
    )
    row.recommendedCheckbox:SetPoint("LEFT", row, "LEFT", recommendedColumnStartX - 40, 0)

    row:Hide()
    m.optionRows[i] = row
  end

  local okayButton = LWF:CreateButton(m, 220, 40, L["Okay"], 16)
  okayButton:SetClickFunction(
    function()
      m:Hide()
    end
  )
  okayButton:SetPoint("BOTTOM", m, "BOTTOM", 0, 20)

  m:HookScript(
    "OnShow",
    function()
      LWF:ToggleLockoutFrame(true, addon.frames, addon.frames.mainFrame)
    end
  )

  m:HookScript(
    "OnHide",
    function()
      LWF:ToggleLockoutFrame(false, addon.frames, addon.frames.mainFrame)
    end
  )

  return m
end

local function showManageFrame(anchor)
  if not m then
    m = createManageFrame(frameWidth, frameHeight)
  end
  getUiScaleSetup()
  refreshManageFrame()
  m:ClearAllPoints()
  m:SetPoint("CENTER", anchor, "CENTER", 0, 0)
  m:Show()
end

local function dropdownOptions()
  return {}
end

---@type ModuleConfig
local moduleConfig = {
  moduleName = moduleName,
  lapModule = lapModule,
  dropdownOptions = dropdownOptions,
  hasGroups = true,
  manageFunc = showManageFrame,
}

addon.ModuleFunctions.specialModules[moduleName] = moduleConfig
