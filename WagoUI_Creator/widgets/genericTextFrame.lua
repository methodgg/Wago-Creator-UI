---@class WagoUICreator
local addon = select(2, ...)
local DF = _G["DetailsFramework"]
local LWF = LibStub("LibWagoFramework")

---@param width number
---@param height number
---@param title string
---@param preventEscapeClose boolean | nil
---@return table
function addon:CreateGenericTextFrame(width, height, title, preventEscapeClose)
  local panelOptions = {
    DontRightClickClose = true,
    NoTUISpecialFrame = preventEscapeClose or false,
    NoCloseButton = false
  }
  local f = DF:CreateSimplePanel(addon.frames.mainFrame, width, height, title, nil, panelOptions)
  LWF:ScaleFrameByUIParentScale(f, 0.5333333333333)
  f:Hide()
  addon.frames.mainFrame:HookScript(
    "OnHide",
    function()
      f.Close:Click()
    end
  )
  f.frameHeight = height
  f.frameWidth = width
  DF:ApplyStandardBackdrop(f)
  DF:CreateBorder(f)
  f:ClearAllPoints()
  f:SetFrameStrata("FULLSCREEN")
  f:SetFrameLevel(100)
  f.__background:SetAlpha(1)
  --capture clicks but dont do anything with them, fixes clicking elements under the frame
  f:SetMouseClickEnabled(true)
  f.StartMoving = function()
  end
  local scrollframe = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate,BackdropTemplate")
  f.scrollframe = scrollframe
  DF:ReskinSlider(scrollframe)
  scrollframe.ScrollBar.ScrollUpButton.Highlight:ClearAllPoints(false)
  scrollframe.ScrollBar.ScrollDownButton.Highlight:ClearAllPoints(false)
  scrollframe:SetBackdrop({ bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]], tileSize = 64, tile = true })
  scrollframe:SetPoint("TOPLEFT", f, "TOPLEFT", 5, -25)
  scrollframe:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -23, 20)
  local editbox = CreateFrame("EditBox", nil, scrollframe)
  f.editbox = editbox
  editbox:SetWidth(width)
  editbox:SetHeight(height)
  editbox:SetFontObject(GameFontNormal)
  editbox:SetMultiLine(true)
  editbox:SetJustifyH("LEFT")
  editbox:SetJustifyV("TOP")
  editbox:EnableMouse(true)
  editbox:EnableKeyboard(true)
  editbox:SetMaxBytes(1024 * 1024 * 1024 - 1)
  editbox:SetTextColor(1, 1, 1, 1)
  editbox:Show()
  scrollframe:SetScrollChild(editbox)

  ---@diagnostic disable-next-line: undefined-field
  local bottomLabel = DF:CreateLabel(f, "", 12, "red")
  bottomLabel:SetJustifyH("left")
  bottomLabel:SetPoint("bottomleft", f, "bottomleft", 8, 5)
  bottomLabel:Hide()
  f.bottomLabel = bottomLabel

  return f
end
