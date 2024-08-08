---@class WagoUICreator
local addon = select(2, ...)
local DF = _G["DetailsFramework"]
local LWF = LibStub("LibWagoFramework")
local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")

local choiceFrame
local defaultWidth = 200
local defaultHeight = 70

local function createChoiceFrame()
  ---@diagnostic disable-next-line: undefined-field
  choiceFrame = DF:CreateSimplePanel(UIParent, defaultWidth, defaultHeight, "")
  ---@diagnostic disable-next-line: undefined-field
  DF:ApplyStandardBackdrop(choiceFrame)
  DF:CreateBorder(choiceFrame)
  choiceFrame:ClearAllPoints()
  choiceFrame:SetFrameStrata("FULLSCREEN")
  choiceFrame:SetFrameLevel(100)
  choiceFrame:SetMouseClickEnabled(false)
  choiceFrame:Hide()
  choiceFrame.buttons = {}
end

function addon:ShowChoiceFrame(choices, titleText, width, height, anchorFrom, anchor, anchorTo)
  if not choiceFrame then createChoiceFrame() end
  choiceFrame:ClearAllPoints()
  choiceFrame:SetPoint(anchorFrom or "CENTER", anchor or addon.frames.mainFrame, anchorTo or "CENTER")
  -- choiceFrame:SetPoint("CENTER", addon.frames.mainFrame, "CENTER")
  choiceFrame:Show()
  choiceFrame:SetTitle(titleText)
  choiceFrame:SetWidth(width or defaultWidth)
  choiceFrame:SetHeight(height or defaultHeight)
  for i, choice in ipairs(choices) do
    local button = choiceFrame.buttons[i]
    if not button then
      button = LWF:CreateButton(choiceFrame, 90, 30, "", 16)
      if (#choices % 2 == 0) then
        button:SetPoint("CENTER", choiceFrame, "CENTER", (i - (#choices / 2) - 0.5) * 95, -11)
      else
        button:SetPoint("CENTER", choiceFrame, "CENTER", (i - math.ceil(#choices / 2)) * 95, -11)
      end
      if choice.tooltipText then
        button:SetTooltip(choice.tooltipText)
      end
      choiceFrame.buttons[i] = button
    end
    button:SetText(choice.text)
    button:SetClickFunction(function()
      choiceFrame:Hide()
      choice.on_click()
    end)
  end
end
