---@class WagoUI
local addon = select(2, ...)
local L = addon.L

addon.color = "FFC1272D"
addon.FONT = [[Interface\AddOns\WagoUI\media\fonts\ArchivoNarrow-Bold.ttf]]

-- One field treatment for WagoUI's native, framework and scrollable editors.
function addon:StyleEditBox(box, surface)
  surface = surface or box
  DetailsFramework:ApplyStandardBackdrop(surface, true)
  if surface.__background then surface.__background:Hide() end
  for _, suffix in ipairs({ "Left", "Middle", "Mid", "Right" }) do
    local texture = box[suffix] or (box.GetName and box:GetName() and _G[box:GetName() .. suffix])
    if texture then texture:Hide() end
  end
  surface:SetBackdropColor(.055, .055, .055, 1)
  box:SetAutoFocus(false)
  box:SetFont(self.FONT, 14, "")
  box:SetTextColor(.95, .95, .95, 1)
  box:SetHighlightColor(.76, .15, .18, .45)
  local padding = surface == box and 10 or 0
  box:SetTextInsets(padding, padding, 0, 0)
  -- Focus events pass their state: HasFocus() can still report true while focus moves to another field.
  local function border(focused)
    if focused == nil then focused = box:HasFocus() end
    if focused then surface:SetBackdropBorderColor(.76, .15, .18, 1)
    elseif box:IsMouseOver() or surface:IsMouseOver() then surface:SetBackdropBorderColor(.65, .65, .65, 1)
    else surface:SetBackdropBorderColor(.45, .45, .45, 1) end
  end
  -- Script handlers pass the frame first, which border() would read as focused.
  local function hover() border() end
  box:HookScript("OnEnter", hover)
  box:HookScript("OnLeave", hover)
  box:HookScript("OnEditFocusGained", function() border(true) end)
  box:HookScript("OnEditFocusLost", function() border(false) end)
  box:HookScript("OnHide", function() box:ClearFocus() end)
  if surface ~= box then
    surface:EnableMouse(true)
    surface:HookScript("OnEnter", hover)
    surface:HookScript("OnLeave", hover)
    surface:HookScript("OnMouseDown", function() box:SetFocus() end)
  end
  border()
end

local tooltip
function addon.HideWidgetTooltip(widget)
  if tooltip and tooltip.owner == (widget.widget or widget.button or widget) then
    tooltip.owner = nil
    tooltip:Hide()
  end
end

function addon.ShowWidgetTooltip(widget, text)
  text = text or (widget.GetTooltip and widget:GetTooltip())
  if type(text) ~= "string" or text == "" then addon.HideWidgetTooltip(widget); return end
  if not tooltip then
    tooltip = CreateFrame("Frame", "WagoUITooltip", UIParent, "BackdropTemplate")
    tooltip:SetFrameStrata("TOOLTIP")
    tooltip:SetClampedToScreen(true)
    tooltip:EnableMouse(false)
    tooltip:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8X8]], edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1 })
    tooltip:SetBackdropColor(.055, .055, .055, .98)
    tooltip:SetBackdropBorderColor(.4, .4, .4, 1)
    tooltip.text = tooltip:CreateFontString(nil, "OVERLAY")
    tooltip.text:SetFont(addon.FONT, 12, "")
    tooltip.text:SetTextColor(.9, .9, .9, 1)
    tooltip.text:SetJustifyH("LEFT")
    tooltip.text:SetWordWrap(true)
    tooltip.text:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 10, -8)
    tooltip:SetScript("OnUpdate", function(self)
      if not self.owner or not self.owner:IsShown() or not self.owner:IsMouseOver() then
        self.owner = nil
        self:Hide()
      end
    end)
  end
  tooltip.text:SetWidth(0)
  tooltip.text:SetText(text)
  local width = math.min(320, math.max(40, tooltip.text:GetStringWidth()))
  tooltip.text:SetWidth(width)
  tooltip:SetSize(width + 20, tooltip.text:GetStringHeight() + 16)
  tooltip.owner = widget.widget or widget.button or widget
  tooltip:ClearAllPoints()
  tooltip:SetPoint("TOPLEFT", tooltip.owner, "BOTTOMLEFT", 0, -4)
  tooltip:Show()
end

function addon:UseWidgetTooltip(widget)
  widget.ShowTooltip = self.ShowWidgetTooltip
  widget.HideTooltip = self.HideWidgetTooltip
end

-- Only visit WagoUI-owned frames; never change shared/global font objects.
function addon:ApplyFont(frame)
  if frame.GetFont and frame.SetFont then
    local _, size, flags = frame:GetFont()
    frame:SetFont(self.FONT, size or 14, flags or "")
  end
  if frame.GetRegions then
    for _, region in ipairs({ frame:GetRegions() }) do self:ApplyFont(region) end
  end
  if frame.GetChildren then
    for _, child in ipairs({ frame:GetChildren() }) do self:ApplyFont(child) end
  end
end

addon.colorRGB = {
  193 / 255,
  39 / 255,
  45 / 255
}
addon.dbKey = "WagoUIDB"
addon.dbCKey = "WagoUICDB"
addon.slashPrefixes = {
  "/wago",
  "/wui",
  "/wagoui"
}
addon.ADDON_WIDTH = 1000
addon.ADDON_HEIGHT = 700
addon.dbDefaults = {
  workspaceMode = "install",
  debug = false,
  autoStart = false,
  anchorTo = "CENTER",
  anchorFrom = "CENTER",
  xoffset = 0,
  yoffset = 0,
  config = {},
  introEnabled = true,
  minimap = {
    hide = false,
    compartmentHide = false
  },
  latestSeenReleasenotes = {}
}

addon.state = {}

addon.externalLinks = {
  {
    name = "GitHub",
    tooltip = L["Open an issue on GitHub"],
    url = "https://github.com/methodgg/Wago-Creator-UI"
  }
}
