-- WoW UI library. Currently only really a wrapper around DetailsFramework.
-- We want to simplify the creation of widgets in our style and make it easier to maintain
local MAJOR, MINOR = "LibWagoFramework", 1
---@class LibWagoFramework
local LibWagoFramework, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if not LibWagoFramework then
  return
end
local DF = _G["DetailsFramework"]
if not DF then
  return
end

local odt = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")

---Scale based on effective scale of UIParent so the window size is always the same relative size to the screen
---@param frame Frame
---@param defaultScale number Default scale of the frame
function LibWagoFramework:ScaleFrameByUIParentScale(frame, defaultScale)
  local scale = 1 / UIParent:GetEffectiveScale()
  frame:SetScale(scale / (1 / defaultScale))
end

---A normal grey rectangular button with text
---@param parent any
---@param width number
---@param height number
---@param text string
---@param fontSize number
---@return table
function LibWagoFramework:CreateButton(parent, width, height, text, fontSize)
  local button = DF:CreateButton(parent, nil, width, height, text, nil, nil, nil, nil, nil, nil, odt)
  button:SetScript(
    "OnEnter",
    function(self)
      button.button:SetBackdropBorderColor(1, 1, 1, 1)
      button:ShowTooltip()
    end
  )
  button:SetScript(
    "OnLeave",
    function(self)
      button.button:SetBackdropBorderColor(0, 0, 0, 1)
      button:HideTooltip()
    end
  )
  button.button:SetBackdropBorderColor(0, 0, 0, 1)
  button:SetBackdropColor(1, 1, 1, 0.7)
  button.text_overlay:SetFont(button.text_overlay:GetFont(), fontSize)
  -- the default text alignment is off, so we need to adjust it
  -- TODO: there is still issues with this, won' fix for now
  button:HookScript(
    "OnMouseUp",
    function()
      button.button.text:SetPoint("center", button.button, "center", 0, -2)
    end
  )
  return button
end

---Simple grey dropdown
---@param parent any
---@param width number
---@param height number
---@param fontSize number | nil
---@param frameScale number
---@param dropdownFunc function
---@return table
function LibWagoFramework:CreateDropdown(parent, width, height, fontSize, frameScale, dropdownFunc)
  local dropdown = DF:CreateDropDown(parent, dropdownFunc, nil, width, height, nil, nil, odt)
  dropdown:SetBackdropColor(1, 1, 1, 0.7)
  dropdown:SetBackdropBorderColor(0, 0, 0, 1)
  dropdown:SetScript(
    "OnEnter",
    function(self)
      dropdown:SetBackdropColor(1, 1, 1, 0.7)
      dropdown:SetBackdropBorderColor(1, 1, 1, 1)
    end
  )
  dropdown:SetScript(
    "OnLeave",
    function(self)
      dropdown:SetBackdropColor(1, 1, 1, 0.7)
      dropdown:SetBackdropBorderColor(0, 0, 0, 1)
    end
  )
  if fontSize then
    dropdown.dropdown.text:SetFont(dropdown.dropdown.text:GetFont(), fontSize)
  end
  dropdown.dropdown.dropdownframe:SetScale(frameScale)
  return dropdown
end

---A button that is part of a tab structure
---@param parent any
---@param width number
---@param height number
---@param text string
---@param fontSize number
---@return table
function LibWagoFramework:CreateTabButton(parent, width, height, text, fontSize)
  local button = LibWagoFramework:CreateButton(parent, width, height, text, fontSize)
  button.disabled_overlay:SetDrawLayer("BORDER")
  button:SetScript(
    "OnEnter",
    function(self)
      button.button:SetBackdropBorderColor(1, 1, 1, 1)
      button.disabled_overlay:Hide()
    end
  )
  button:SetScript(
    "OnLeave",
    function(self)
      button.button:SetBackdropBorderColor(0, 0, 0, 1)
      if button:IsEnabled() then
        button.disabled_overlay:Show()
      end
    end
  )
  return button
end

---Tab structure that handles logic for switching tabs
---@param buttons table<Frame>
---@param tabFunction function
---@param defaultTab number
function LibWagoFramework:CreateTabStructure(buttons, tabFunction, defaultTab)
  for i, button in ipairs(buttons) do
    button:SetClickFunction(
      function()
        for j, b in ipairs(buttons) do
          if i == j then
            b:Disable()
            b.disabled_overlay:Hide()
          else
            b:Enable()
            b.disabled_overlay:Show()
          end
        end
        tabFunction(i)
      end
    )
    if i == defaultTab then
      button:Disable()
      button.disabled_overlay:Hide()
    else
      button:Disable()
      button:Enable()
      button.disabled_overlay:Show()
    end
  end
  tabFunction(defaultTab)
end

---Big button for big choices
---@param parent any
---@param text string
---@return table
function LibWagoFramework:CreateBigChoiceButton(parent, text)
  local button = DF:CreateButton(parent, nil, 250, 80, text, nil, nil, nil, nil, nil, nil, odt)
  button:SetBackdropColor(1, 1, 1, 0.7)
  button:SetScript(
    "OnEnter",
    function(self)
      button.button:SetBackdropBorderColor(1, 1, 1, 1)
    end
  )
  button:SetScript(
    "OnLeave",
    function(self)
      button.button:SetBackdropBorderColor(1, 1, 1, 0)
    end
  )
  button.text_overlay:SetFont(button.text_overlay:GetFont(), 28)
  return button
end

---Prompt frame that doubles as a blocking frame for the parent
---@param parent any
---@param okayText string
---@param cancelText string
---@return table
function LibWagoFramework:CreatePrompFrame(parent, okayText, cancelText)
  local promptFrame = CreateFrame("Frame", nil, parent)
  promptFrame.defaultOkayText = okayText
  promptFrame.defaultCancelText = cancelText
  promptFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT")
  promptFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -20)
  promptFrame:SetFrameStrata("DIALOG")
  promptFrame:EnableMouse(true)
  local tex = promptFrame:CreateTexture(nil, "BACKGROUND")
  tex:SetAllPoints(promptFrame)
  tex:SetColorTexture(0, 0, 0, 0.9)
  promptFrame.label = DF:CreateLabel(promptFrame, "", 22, "white")
  promptFrame.label:SetWidth(promptFrame:GetWidth() - 10)
  promptFrame.label:SetJustifyH("CENTER")
  promptFrame.label:SetPoint("TOP", promptFrame, "TOP", 0, -120)
  promptFrame.okayButton = LibWagoFramework:CreateButton(promptFrame, 180, 40, "", 18)
  promptFrame.okayButton:SetPoint("BOTTOMRIGHT", promptFrame, "BOTTOM", -60, 60)
  promptFrame.cancelButton = LibWagoFramework:CreateButton(promptFrame, 180, 40, "", 18)
  promptFrame.cancelButton:SetPoint("BOTTOMLEFT", promptFrame, "BOTTOM", 60, 60)
  promptFrame:Hide()
  return promptFrame
end

---@param show boolean
---@param storageTable table
---@param parent Frame
---@param xOffset number | nil
---@param yOffset number | nil
function LibWagoFramework:ToggleLockoutFrame(show, storageTable, parent, xOffset, yOffset)
  local lockoutFrame = storageTable.LWFLockoutFrame
  if show and not lockoutFrame then
    storageTable.LWFLockoutFrame = CreateFrame("Frame", nil, parent)
    lockoutFrame = storageTable.LWFLockoutFrame
    lockoutFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT")
    lockoutFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset or 0, yOffset or -20)
    lockoutFrame:SetFrameStrata("DIALOG")
    lockoutFrame:EnableMouse(true)
    lockoutFrame:Hide()
    local tex = lockoutFrame:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints(lockoutFrame)
    tex:SetColorTexture(0, 0, 0, 0.7)
  end
  if show then
    lockoutFrame:Show()
  else
    if not lockoutFrame then
      return
    end
    lockoutFrame:Hide()
  end
end

---Simple checkbox
---@param parent any
---@param size number
---@param switchFunc function | nil
---@param defaultValue boolean
---@return table
function LibWagoFramework:CreateCheckbox(parent, size, switchFunc, defaultValue)
  local checkBox =
    DF:CreateSwitch(
    parent,
    switchFunc or function()
      end,
    false,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    DF:GetTemplate("switch", "OPTIONS_CHECKBOX_BRIGHT_TEMPLATE")
  )
  checkBox:SetValue(defaultValue)
  checkBox:SetSize(size, size)
  checkBox:SetAsCheckBox()
  return checkBox
end

---Simple text entry
---@param parent any
---@param width number
---@param height number
---@param textChangedCallback function | nil
---@param fontSize number | nil
---@return table
function LibWagoFramework:CreateTextEntry(parent, width, height, textChangedCallback, fontSize)
  local textEntry = DF:CreateTextEntry(parent, textChangedCallback, width, height, nil, nil, nil, odt)
  textEntry:SetBackdropColor(1, 1, 1, 0.7)
  textEntry:SetBackdropBorderColor(0, 0, 0, 1)
  textEntry:SetScript(
    "OnEnter",
    function(self)
      if textEntry.editbox:IsEnabled() then
        textEntry:SetBackdropBorderColor(1, 1, 1, 1)
      end
    end
  )
  textEntry:SetScript(
    "OnLeave",
    function(self)
      textEntry:SetBackdropBorderColor(0, 0, 0, 1)
    end
  )
  if fontSize then
    textEntry:SetFont(textEntry:GetFont(), fontSize, "")
  end
  textEntry.editbox:SetHighlightColor(0.1, 0.1, 0.1, 1)
  return textEntry
end

---Simple icon button
---@param parent any
---@param size number
---@param icon string | number
---@param tooltipText string | nil
---@return table
function LibWagoFramework:CreateIconButton(parent, size, icon, tooltipText)
  local button = DF:CreateButton(parent, nil, size, size, "", nil, nil, icon)
  if tooltipText then
    button:SetTooltip(tooltipText)
  end
  return button
end

---@param myFrame Frame
---@param otherFrame Frame
---@param mineLeft boolean
---@param xOffset number | nil
function LibWagoFramework:StartSplitView(myFrame, otherFrame, mineLeft, xOffset)
  if not otherFrame or not otherFrame:IsShown() then
    return
  end
  xOffset = (mineLeft and -1 or 1) * (xOffset or 10)
  otherFrame:ClearAllPoints()
  otherFrame:SetPoint(mineLeft and "LEFT" or "RIGHT", UIParent, "CENTER", -1 * xOffset, 0)
  myFrame:ClearAllPoints()
  myFrame:SetPoint(mineLeft and "RIGHT" or "LEFT", UIParent, "CENTER", xOffset, 0)
end

---@param resetFunc function
---@param otherFrame Frame
function LibWagoFramework:EndSplitView(otherFrame, resetFunc)
  if not otherFrame or not otherFrame:IsShown() then
    return
  end
  if not otherFrame or not otherFrame:IsShown() then
    return
  end
  otherFrame:Hide()
  resetFunc()
end
