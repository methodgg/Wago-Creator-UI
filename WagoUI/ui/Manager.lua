-- Two-list managers (Cooldown Manager, WeakAuras): rows move between the lists by click or drag.
local addon = select(2, ...)
local UI = addon.UI
local ui = UI.view
local label, reset, scroll, widget = UI.label, UI.reset, UI.scroll, UI.widget

local WHITE = [[Interface\Buttons\WHITE8X8]]

-- Follows the cursor while a row is dragged between the lists.
local function dragGhost(lists)
  if not ui.managerGhost then
    local ghost = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    ghost:SetFrameStrata("TOOLTIP")
    ghost:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    ghost:SetBackdropColor(.12, .12, .12, .9)
    ghost:SetBackdropBorderColor(.55, .55, .55, 1)
    ghost:EnableMouse(false)
    ghost.text = ghost:CreateFontString(nil, "OVERLAY")
    ghost.text:SetFont(addon.FONT, 13, "")
    ghost.text:SetPoint("LEFT", ghost, "LEFT", 12, -1)
    ghost:SetScript("OnUpdate", function(self)
      local x, y = GetCursorPosition()
      local scale = UIParent:GetEffectiveScale()
      self:ClearAllPoints()
      self:SetPoint("LEFT", UIParent, "BOTTOMLEFT", x / scale + 8, y / scale)
      for _, list in ipairs(self.lists or {}) do
        list:SetBackdropBorderColor(unpack(list:IsMouseOver() and { .76, .15, .18, 1 } or { .22, .22, .22, 1 }))
      end
    end)
    ghost:Hide()
    ui.managerGhost = ghost
  end
  ui.managerGhost.lists = lists
end

local function managerList(f, kind, x, y, width, height)
  local list = widget(f, kind, function()
    local panel = CreateFrame("Frame", nil, f, "BackdropTemplate")
    panel:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    panel:SetBackdropColor(.05, .05, .05, 1)
    panel.scroll, panel.content = scroll(panel, 4, 4, width - 26, height - 8)
    return panel
  end)
  list:SetPoint("TOPLEFT", f, "TOPLEFT", x, -y)
  list:SetSize(width, height)
  list:SetFrameLevel(f:GetFrameLevel() + 1)
  list:SetBackdropBorderColor(.22, .22, .22, 1)
  list.scroll:SetFrameLevel(list:GetFrameLevel() + 1)
  reset(list.content)
  return list
end

-- A row: clicking it (or dropping it on dropTarget) runs onActivate. The hover icon on the right shows what that
-- does; an optional second icon left of it runs its own action.
local function managerRow(list, y, row)
  local f = widget(list.content, "managerRow", function()
    local b = CreateFrame("Button", nil, list.content, "BackdropTemplate")
    b:SetBackdrop({ bgFile = WHITE })
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(22, 22)
    b.icon:SetTexCoord(1 / 12, 11 / 12, 1 / 12, 11 / 12)
    b.text = b:CreateFontString(nil, "OVERLAY")
    b.text:SetFont(addon.FONT, 13, "")
    b.text:SetJustifyH("LEFT")
    b.text:SetWordWrap(false)
    b.action = b:CreateTexture(nil, "OVERLAY")
    b.action:SetSize(16, 16)
    b.action:SetPoint("RIGHT", b, "RIGHT", -10, 0)
    b.second = CreateFrame("Button", nil, b)
    b.second:SetSize(18, 18)
    b.second:SetPoint("RIGHT", b, "RIGHT", -34, 0)
    b.second.texture = b.second:CreateTexture(nil, "OVERLAY")
    b.second.texture:SetAllPoints(b.second)
    b.paint = function(self)
      local hovered = self:IsMouseOver() and not addon.state.busy
      self:SetBackdropColor(.8, .8, .8, hovered and .12 or self.shade)
      self.action:SetShown(hovered)
      self.second:SetShown(hovered and self.secondAction ~= nil)
      self.second.texture:SetAlpha(self.second:IsMouseOver() and 1 or .7)
    end
    b:SetScript("OnEnter", function(self) self:paint(); addon.ShowWidgetTooltip(self, self.tooltip) end)
    b:SetScript("OnLeave", function(self) self:paint(); addon.HideWidgetTooltip(self) end)
    b:SetScript("OnClick", function(self) if not addon.state.busy then self.onActivate() end end)
    b.second:SetScript("OnEnter", function(self) b:paint(); addon.ShowWidgetTooltip(self, b.secondTooltip) end)
    b.second:SetScript("OnLeave", function(self) b:paint(); addon.HideWidgetTooltip(self) end)
    b.second:SetScript("OnClick", function() if not addon.state.busy and b.secondAction then b.secondAction() end end)
    b:RegisterForDrag("LeftButton")
    b:SetScript("OnDragStart", function(self)
      if addon.state.busy then return end
      local ghost = ui.managerGhost
      ghost.text:SetText(self.text:GetText())
      ghost:SetSize(self:GetWidth(), self:GetHeight())
      ghost:Show()
      self.dragging = true
    end)
    b:SetScript("OnDragStop", function(self)
      if not self.dragging then return end
      self.dragging = nil
      ui.managerGhost:Hide()
      self.dropTarget:SetBackdropBorderColor(.22, .22, .22, 1)
      if self.dropTarget:IsMouseOver() then self.onActivate() end
    end)
    return b
  end)
  local indent = row.indent or 0
  f:SetPoint("TOPLEFT", list.content, "TOPLEFT", 0, -y)
  f:SetSize(list.content:GetWidth(), 32)
  f.shade = (y / 32) % 2 == 1 and .04 or 0
  f.icon:ClearAllPoints()
  f.icon:SetPoint("LEFT", f, "LEFT", 8 + indent, 0)
  f.icon:SetTexture(row.icon or 134400)
  f.text:ClearAllPoints()
  f.text:SetPoint("LEFT", f, "LEFT", 38 + indent, -1)
  f.text:SetWidth(f:GetWidth() - 70 - indent - (row.secondAction and 24 or 0))
  f.text:SetText(row.text)
  f.text:SetTextColor(unpack(row.color or { 1, 1, 1 }))
  f.action:SetTexture(row.actionTexture)
  f.tooltip = row.tooltip
  f.second.texture:SetTexture(row.secondTexture)
  f.secondAction, f.secondTooltip = row.secondAction, row.secondTooltip
  f.onActivate, f.dropTarget = row.onActivate, row.dropTarget
  f:SetEnabled(not addon.state.busy)
  f:paint()
  return f
end

-- A grey line centered in an empty list.
local function emptyList(list, text)
  label(list.content, text, 0, 20, list.content:GetWidth(), 13, { .5, .5, .5 }):SetJustifyH("CENTER")
end

UI.dragGhost = dragGhost
UI.emptyList = emptyList
UI.managerList = managerList
UI.managerRow = managerRow
