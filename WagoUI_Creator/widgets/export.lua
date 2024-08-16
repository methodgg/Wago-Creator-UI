---@class WagoUICreator
local addon = select(2, ...)
local L = addon.L

local exportFrame

function addon:CreateTextExportFrame()
  exportFrame = addon:CreateGenericTextFrame(600, 400, "Text Export")
  exportFrame:SetFrameLevel(105)
  exportFrame.Close:SetScript(
    "OnClick",
    function()
      exportFrame:Hide()
      addon.copyHelper:Hide()
    end
  )
  local editbox = exportFrame.editbox
  editbox:SetScript(
    "OnKeyUp",
    function(_, key)
      if key == "ESCAPE" then
        exportFrame:Hide()
        addon.copyHelper:Hide()
      end
      if (addon.copyHelper:WasControlKeyDown() and key == "A") then
        return
      end
      if (addon.copyHelper:WasControlKeyDown() and key == "C") then
        exportFrame.editbox:ClearFocus()
        exportFrame:Hide()
        addon.copyHelper:SmartFadeOut(nil, L["copied!"])
        return
      end
    end
  )
  editbox:SetScript(
    "OnTextChanged",
    function()
      editbox:SetText(editbox.myText)
      editbox:HighlightText()
      editbox:SetFocus()
    end
  )
  editbox:HookScript(
    "OnEditFocusLost",
    function()
      editbox:HighlightText()
      editbox:SetFocus()
    end
  )
  editbox:HookScript(
    "OnCursorChanged",
    function()
      editbox:HighlightText()
      editbox:SetFocus()
    end
  )
  addon.exportFrame = exportFrame
end

--- @param str string
--- @param dontHighlight? boolean
function addon:TextExport(str, dontHighlight)
  if not exportFrame then
    addon:CreateTextExportFrame()
  end
  if not str then
    return
  end
  if addon.importFrame then
    addon.importFrame.Close:Click()
  end
  exportFrame:SetPoint("CENTER", addon.frames.mainFrame, "CENTER")
  exportFrame:Show()
  exportFrame.editbox.myText = str
  exportFrame.editbox:SetText(str)
  if (not dontHighlight) then
    exportFrame.editbox:HighlightText()
    exportFrame.editbox:SetFocus()
  end
  addon.copyHelper:SmartShow(addon.frames.mainFrame, 0, 50)
end
