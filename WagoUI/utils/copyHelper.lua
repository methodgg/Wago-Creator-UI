---@type string
local addonName = ...
---@class WagoUI
local addon = select(2, ...)
local L = addon.L
local DF = _G["DetailsFramework"]
local LWF = LibStub("LibWagoFramework")

local copyPrompt = L["copyInstruction"]

function addon:CreateCopyHelper()
  addon.copyHelper = CreateFrame("Frame", addonName.."CopyHelper", UIParent)
  LWF:ScaleFrameByUIParentScale(addon.copyHelper, 0.5333333333333)
  addon.copyHelper:SetFrameStrata("TOOLTIP")
  addon.copyHelper:SetFrameLevel(200)
  addon.copyHelper:SetHeight(100)
  addon.copyHelper:SetWidth(300)
  addon.copyHelper.tex = addon.copyHelper:CreateTexture(nil, "BACKGROUND", nil, 0)
  addon.copyHelper.tex:SetAllPoints()
  addon.copyHelper.tex:SetColorTexture(unpack({ 0.058823399245739, 0.058823399245739, 0.058823399245739, 0.9 }))
  addon.copyHelper.text = addon.copyHelper:CreateFontString(addonName.."copyHelperText")
  addon.copyHelper.text:SetFontObject("GameFontNormalMed3")
  addon.copyHelper.text:SetJustifyH("CENTER")
  addon.copyHelper.text:SetText(copyPrompt)
  addon.copyHelper.text:ClearAllPoints()
  addon.copyHelper.text:SetPoint("CENTER", addon.copyHelper, "CENTER")
  addon.copyHelper.text:Show()
  addon.copyHelper.text:SetFont(addon.copyHelper.text:GetFont() or "", 20, "")
  addon.copyHelper.text:SetTextColor(1, 1, 0)

  addon.copyHelper.fadeOutFrame = CreateFrame("Frame", nil, UIParent)
  LWF:ScaleFrameByUIParentScale(addon.copyHelper.fadeOutFrame, 0.5333333333333)
  addon.copyHelper.fadeOutFrame:SetFrameStrata("TOOLTIP")
  addon.copyHelper.fadeOutFrame:SetFrameLevel(200)
  addon.copyHelper.fadeOutFrame:SetHeight(100)
  addon.copyHelper.fadeOutFrame:SetWidth(300)
  addon.copyHelper.fadeOutFrame.tex = addon.copyHelper.fadeOutFrame:CreateTexture(nil, "BACKGROUND", nil, 0)
  addon.copyHelper.fadeOutFrame.tex:SetAllPoints()
  addon.copyHelper.fadeOutFrame.tex:SetColorTexture(
    unpack({ 0.058823399245739, 0.058823399245739, 0.058823399245739, 0.9 })
  )
  addon.copyHelper.fadeOutFrame.text = addon.copyHelper.fadeOutFrame:CreateFontString(addonName.."copyHelperFadeoutText")
  addon.copyHelper.fadeOutFrame.text:SetFontObject("GameFontNormalMed3")
  addon.copyHelper.fadeOutFrame.text:SetJustifyH("CENTER")
  addon.copyHelper.fadeOutFrame.text:SetText(copyPrompt)
  addon.copyHelper.fadeOutFrame.text:ClearAllPoints()
  addon.copyHelper.fadeOutFrame.text:SetPoint("CENTER", addon.copyHelper.fadeOutFrame, "CENTER")
  addon.copyHelper.fadeOutFrame.text:Show()
  addon.copyHelper.fadeOutFrame.text:SetFont(addon.copyHelper.fadeOutFrame.text:GetFont() or "", 20, "")
  addon.copyHelper.fadeOutFrame.text:SetTextColor(1, 1, 0)

  -- parent frame to give the statusbar a background
  local statusBar = CreateFrame("Frame", addonName.."StatusBar", UIParent, "BackdropTemplate")
  ---@diagnostic disable-next-line: param-type-mismatch
  LWF:ScaleFrameByUIParentScale(statusBar, 0.5333333333333)

  --set a grey backdrop
  ---@diagnostic disable-next-line: missing-fields,param-type-mismatch
  statusBar:SetBackdrop(
    {
      bgFile = "Interface\\Buttons\\WHITE8x8",
      edgeFile = "Interface\\Buttons\\WHITE8x8",
      tile = false,
      tileSize = 0,
      edgeSize = 1,
      insets = {
        left = 0,
        right = 0,
        top = 0,
        bottom = 0
      }
    }
  )
  statusBar:SetBackdropColor(0.4, 0.4, 0.4, 1)
  statusBar:SetBackdropBorderColor(0, 0, 0, 0)
  statusBar:SetSize(280, 20)
  statusBar:SetFrameStrata("TOOLTIP")
  statusBar:SetFrameLevel(201)
  statusBar:SetPoint("BOTTOM", addon.copyHelper, "BOTTOM", 0, 6)
  statusBar:Hide()
  DF:CreateBorder(statusBar, 1, 0, 0)

  -- actual status bar, child of parent above
  statusBar.bar = CreateFrame("StatusBar", nil, statusBar)
  statusBar.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
  statusBar.bar:SetStatusBarColor(addon.colorRGB[1], addon.colorRGB[2], addon.colorRGB[3])
  statusBar.bar:SetPoint("TOPLEFT", 0, 0)
  statusBar.bar:SetPoint("BOTTOMRIGHT", 0, 0)

  statusBar.bar.text = statusBar.bar:CreateFontString()
  statusBar.bar.text:SetPoint("CENTER", statusBar, "CENTER")
  statusBar.bar.text:SetFontObject("GameFontNormalMed3")
  statusBar.bar.text:SetTextColor(1, 1, 1, 1)
  statusBar.bar.text:SetJustifyH("CENTER")
  statusBar.bar.text:SetHeight(20)
  statusBar.bar.text:SetFont(statusBar.bar.text:GetFont() or "", 14, "OUTLINE")

  -- copying mixins to statusbar
  Mixin(statusBar.bar, SmoothStatusBarMixin)

  -- using mixin methods
  statusBar.bar:SetMinMaxSmoothedValue(0, 0)

  local maxProgress = 0
  local currentProgress = 0
  function addon:StartCopyHelperProgressBar(max)
    maxProgress = max
    currentProgress = 0
    statusBar.bar:SetMinMaxSmoothedValue(0, max)
    statusBar:Show()
    statusBar:SetAlpha(1)
  end

  function addon:UpdateCopyHelperProgressBar(progress)
    if progress then
      currentProgress = progress
    else
      currentProgress = currentProgress + 1
    end
    statusBar.bar:SetSmoothedValue(currentProgress)
    local text = currentProgress.."/"..maxProgress
    if currentProgress == maxProgress then
      ---@diagnostic disable-next-line: param-type-mismatch
      UIFrameFadeOut(statusBar, 1, 1, 0)
    end
    statusBar.bar.text:SetText(text)
  end

  function addon.copyHelper:SmartFadeOut(seconds, text, anchorFrame, x, y)
    seconds = seconds or 0.3
    anchorFrame = anchorFrame or addon.frames.mainFrame
    x = x or 0
    y = y or 50

    addon.copyHelper:Hide()
    addon.copyHelper:SetScript("OnUpdate", nil)
    addon.copyHelper.fadeOutFrame:SetPoint("CENTER", anchorFrame, "CENTER", x, y)
    addon.copyHelper.fadeOutFrame.isFading = true
    addon.copyHelper.fadeOutFrame:SetAlpha(1)
    addon.copyHelper.fadeOutFrame:Show()
    UIFrameFadeOut(addon.copyHelper.fadeOutFrame, seconds, 1, 0)
    addon.copyHelper.fadeOutFrame.text:SetText(text)
    addon.copyHelper.fadeOutFrame.text:SetTextColor(1, 1, 1)
    if addon.copyHelper.hideTimer then
      addon.copyHelper.hideTimer:Cancel()
    end
    addon.copyHelper.hideTimer =
        C_Timer.NewTimer(
          seconds,
          function()
            addon.copyHelper.fadeOutFrame.text:SetText(copyPrompt)
            addon.copyHelper.fadeOutFrame.text:SetTextColor(1, 1, 0)
            addon.copyHelper.fadeOutFrame:Hide()
            addon.copyHelper.fadeOutFrame.isFading = false
          end
        )
  end

  function addon.copyHelper:SmartShow(anchorFrame, x, y, text)
    addon.copyHelper.fadeOutFrame:Hide()
    addon.copyHelper:ClearAllPoints()
    addon.copyHelper:SetPoint("CENTER", anchorFrame, "CENTER", x, y)
    addon.copyHelper:SetAlpha(1)
    addon.copyHelper:Show()
    addon.copyHelper:SetScript(
      "OnUpdate",
      function()
        if IsControlKeyDown() then
          addon.lastCtrlDown = GetTime()
        end
      end
    )
    if text then
      addon.copyHelper.text:SetText(text)
      addon.copyHelper.text:SetTextColor(1, 1, 0)
    else
      addon.copyHelper.text:SetText(copyPrompt)
      addon.copyHelper.text:SetTextColor(0, 1, 0)
    end
  end

  function addon.copyHelper:SmartHide()
    addon.copyHelper:Hide()
  end

  --ctrl+c works when ctrl was released up to 0.5s before the c key
  function addon.copyHelper:WasControlKeyDown()
    if IsControlKeyDown() then
      return true
    end
    if not addon.lastCtrlDown then
      return false
    end
    return (GetTime() - addon.lastCtrlDown) < 0.5
  end
end
