---@diagnostic disable: inject-field
local addonName, addon = ...;
local L = addon.L

function addon:MakeCopyHelper()
  addon.copyHelper = CreateFrame("Frame", "addonCopyHelper", UIParent)
  addon.copyHelper:SetFrameStrata("TOOLTIP")
  addon.copyHelper:SetFrameLevel(200)
  addon.copyHelper:SetHeight(100)
  addon.copyHelper:SetWidth(300)
  addon.copyHelper.tex = addon.copyHelper:CreateTexture(nil, "BACKGROUND", nil, 0)
  addon.copyHelper.tex:SetAllPoints()
  addon.copyHelper.tex:SetColorTexture(unpack({ 0.058823399245739, 0.058823399245739, 0.058823399245739, 0.9 }))
  addon.copyHelper.text = addon.copyHelper:CreateFontString("addon name")
  addon.copyHelper.text:SetFontObject(GameFontNormalMed3)
  addon.copyHelper.text:SetJustifyH("CENTER")
  addon.copyHelper.text:SetJustifyV("MIDDLE")
  addon.copyHelper.text:SetText(L["copyInstruction"])
  addon.copyHelper.text:ClearAllPoints()
  addon.copyHelper.text:SetPoint("CENTER", addon.copyHelper, "CENTER")
  addon.copyHelper.text:Show()
  addon.copyHelper.text:SetFont(addon.copyHelper.text:GetFont() or '', 20, '')
  addon.copyHelper.text:SetTextColor(1, 1, 0)

  function addon.copyHelper:SmartFadeOut(seconds)
    seconds = seconds or 0.3
    addon.copyHelper.isFading = true
    addon.copyHelper:SetAlpha(1)
    addon.copyHelper:Show()
    UIFrameFadeOut(addon.copyHelper, seconds, 1, 0)
    addon.copyHelper.text:SetText(L["copiedToClipboard"])
    addon.copyHelper.text:SetTextColor(1, 1, 1)
    addon.copyHelper:SetScript("OnUpdate", nil)
    C_Timer.After(seconds, function()
      addon.copyHelper.text:SetText(L["copyInstruction"])
      addon.copyHelper.text:SetTextColor(1, 1, 0)
      addon.copyHelper:Hide()
      addon.copyHelper.isFading = false
    end)
  end

  function addon.copyHelper:SmartShow(anchorFrame, x, y)
    addon.copyHelper:ClearAllPoints()
    addon.copyHelper:SetPoint("CENTER", anchorFrame, "CENTER", x, y)
    addon.copyHelper:SetAlpha(1)
    addon.copyHelper:Show()
    addon.copyHelper:SetScript("OnUpdate", function()
      if IsControlKeyDown() then
        addon.lastCtrlDown = GetTime()
      end
    end)
  end

  function addon.copyHelper:SmartHide()
    if not addon.copyHelper.isFading then addon.copyHelper:Hide() end
  end

  --ctrl+c works when ctrl was released up to 0.5s before the c key
  function addon.copyHelper:WasControlKeyDown()
    if IsControlKeyDown() then return true end
    if not addon.lastCtrlDown then return false end
    return (GetTime() - addon.lastCtrlDown) < 0.5
  end
end
