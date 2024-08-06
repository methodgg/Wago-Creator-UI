---@class WagoUICreator
local addon = select(2, ...)
local DF = _G["DetailsFramework"]
local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")

local promptPanel
local defaultWidth = 320
local defaultHeight = 140

local function createPromptPanel(anchor)
  ---@diagnostic disable-next-line: undefined-field
  promptPanel = DF:CreateSimplePanel(anchor, defaultWidth, defaultHeight, "")
  addon.frames.mainFrame:HookScript("OnHide", function()
    promptPanel.Close:Click()
  end)
  anchor:HookScript("OnHide", function()
    promptPanel.Close:Click()
  end)
  ---@diagnostic disable-next-line: undefined-field
  DF:ApplyStandardBackdrop(promptPanel)
  DF:CreateBorder(promptPanel)
  promptPanel:ClearAllPoints()
  promptPanel:SetFrameStrata("FULLSCREEN")
  promptPanel:SetFrameLevel(105)
  promptPanel:SetMouseClickEnabled(false)
  promptPanel:Hide()
  promptPanel.buttons = {}

  ---@diagnostic disable-next-line: undefined-field
  local promptLabel = DF:CreateLabel(promptPanel, "", 14, "white")
  promptLabel:SetJustifyH("CENTER")
  promptLabel:SetPoint("TOPLEFT", promptPanel, "TOPLEFT", 10, 0)
  promptLabel:SetPoint("BOTTOMRIGHT", promptPanel, "BOTTOMRIGHT", -10, 30)
  promptPanel.promptLabel = promptLabel

  ---@diagnostic disable-next-line: undefined-field
  local cancelButton = DF:CreateButton(promptPanel, nil, 90, 30, "Cancel", nil, nil, nil, nil, nil, nil,
    options_dropdown_template)
  cancelButton.text_overlay:SetFont(cancelButton.text_overlay:GetFont(), 16)
  cancelButton:SetPoint("BOTTOMRIGHT", promptPanel, "BOTTOMRIGHT", -5, 10)
  cancelButton:SetClickFunction(function()
    promptPanel:Hide()
  end)
  promptPanel.cancelButton = cancelButton
end

function addon:ShowPrompt(promptText, choices, titleText, width, height, anchorFrom, anchor, anchorTo)
  if not promptPanel then createPromptPanel(anchor) end
  promptPanel:ClearAllPoints()
  promptPanel:SetPoint(anchorFrom or "CENTER", anchor or addon.frames.mainFrame, anchorTo or "CENTER")
  promptPanel:Show()
  promptPanel:SetTitle(titleText)
  promptPanel:SetWidth(width or defaultWidth)
  promptPanel:SetHeight(height or defaultHeight)
  promptPanel.promptLabel:SetText(promptText)

  --hide all buttons
  for _, button in ipairs(promptPanel.buttons) do
    button:Hide()
  end

  for i, choice in ipairs(choices) do
    local button = promptPanel.buttons[i]
    if not button then
      ---@diagnostic disable-next-line: undefined-field
      button = DF:CreateButton(promptPanel, nil, 90, 30, nil, nil, nil, nil, nil, nil, nil,
        options_dropdown_template)
      button:SetPoint("BOTTOMLEFT", promptPanel, "BOTTOMLEFT", 5 + (i - 1) * 100, 10)
      button.text_overlay:SetFont(button.text_overlay:GetFont(), 16)
      promptPanel.buttons[i] = button
    end
    button:Show()
    button:SetText(choice.text)
    button:SetTooltip(choice.tooltipText)
    button:SetClickFunction(function()
      promptPanel:Hide()
      choice.on_click()
    end)
  end
end
