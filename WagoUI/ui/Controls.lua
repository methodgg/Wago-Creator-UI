-- WagoUI's own controls. Each one is a plain frame; the colors and sizes keep the look WagoUI has always had.
local addon = select(2, ...)

local Controls = {}
addon.Controls = Controls

local WHITE = [[Interface\Buttons\WHITE8X8]]
local FIELD = { bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], edgeFile = WHITE, edgeSize = 1, tileSize = 64, tile = true }
local FLAT = { bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 }
local PANEL = { .1215, .1176, .1294, .76 }

-- The window surface: a tinted backdrop under a fill of the same color, whose alpha sets the panel's opacity.
function Controls.Backdrop(frame)
  frame:SetBackdrop(FIELD)
  frame:SetBackdropColor(unpack(PANEL))
  frame:SetBackdropBorderColor(0, 0, 0, .95)
  frame.surface = frame:CreateTexture(nil, "BORDER", nil, -6)
  frame.surface:SetColorTexture(PANEL[1], PANEL[2], PANEL[3])
  frame.surface:SetAllPoints()
  frame.surface:SetAlpha(PANEL[4])
end

-- A black line just outside the frame.
function Controls.Border(frame)
  local sides = {
    { "TOPLEFT", -1, 1, "BOTTOMLEFT", -1, -1 },
    { "TOPLEFT", 0, 1, "TOPRIGHT", 1, 1 },
    { "TOPRIGHT", 1, 0, "BOTTOMRIGHT", 1, -1 },
    { "BOTTOMLEFT", 0, -1, "BOTTOMRIGHT", 0, -1 },
  }
  for _, side in ipairs(sides) do
    local line = frame:CreateTexture(nil, "BACKGROUND")
    PixelUtil.SetPoint(line, side[1], frame, side[1], side[2], side[3])
    PixelUtil.SetPoint(line, side[4], frame, side[4], side[5], side[6])
    line:SetColorTexture(0, 0, 0, 1)
  end
end

-- Windows keep the same size on screen whatever the UI scale.
function Controls.ScaleToScreen(frame)
  frame:SetScale(0.5333333333333 / UIParent:GetEffectiveScale())
end

-- Keeps native dragging, wheel scrolling and overflow detection; replaces only the skin.
function Controls.SkinScrollbar(bar, arrows)
  local thumb = bar:GetThumbTexture()
  for _, region in ipairs({ bar:GetRegions() }) do
    if region ~= thumb then region:Hide() end
  end
  for _, arrow in ipairs(arrows) do
    arrow:Hide()
    arrow:HookScript("OnShow", function(self) self:Hide() end)
  end
  bar:SetWidth(12)
  local track = bar:CreateTexture(nil, "BACKGROUND")
  track:SetPoint("TOP", bar, "TOP", 0, 0)
  track:SetPoint("BOTTOM", bar, "BOTTOM", 0, 0)
  track:SetWidth(8)
  track:SetColorTexture(.09, .09, .09, 1)
  thumb:SetColorTexture(.76, .15, .18, 1)
  thumb:SetTexCoord(0, 1, 0, 1)
  thumb:SetSize(8, 40)
  bar:HookScript("OnEnter", function() thumb:SetColorTexture(.95, .24, .28, 1) end)
  bar:HookScript("OnLeave", function() thumb:SetColorTexture(.76, .15, .18, 1) end)
end

-- Drops trailing characters, whole UTF-8 characters at a time, until the text fits. The region shows the text in
-- fontString: a button and its label, or a font string itself.
local function fitText(region, fontString, text, maxWidth)
  region:SetText(text)
  while fontString:GetStringWidth() > maxWidth and #text > 1 do
    text = text:gsub("[%z\1-\127\194-\244][\128-\191]*$", "")
    region:SetText(text)
  end
end

local Tooltip = {}
function Tooltip:SetTooltip(text) self.tooltip = text end
function Tooltip:GetTooltip() return self.tooltip end
function Tooltip:ShowTooltip() addon.ShowWidgetTooltip(self) end
function Tooltip:HideTooltip() addon.HideWidgetTooltip(self) end

-- WoW Forever lets only Blizzard's code reload the UI, so a control whose onClick is a Reload gets covered by one
-- secure button that runs /reload. prepare runs first and cancels the reload by returning false.
local Reload = {}
function Controls.Reload(prepare) return setmetatable({ prepare = prepare }, Reload) end
function Controls.IsReload(value) return getmetatable(value) == Reload end

-- The cover lives outside WagoUI's frames: a secure child would keep WagoUI from hiding in combat. It takes clicks
-- but not mouse motion, so the control beneath keeps its hover look and tooltip.
local cover
local function uncover()
  if cover and not cover.clicking and not InCombatLockdown() then
    cover:Hide()
    cover.target = nil
  end
end

local function newCover()
  local f = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
  f:SetFrameStrata("TOOLTIP")
  f:RegisterForClicks("LeftButtonUp")
  f:SetMouseMotionEnabled(false)
  f:SetAttribute("useOnKeyDown", false)
  f:SetAttribute("type", "macro")
  f:SetAttribute("macrotext", "/reload")
  f:SetScript("PreClick", function(self)
    self.clicking = true
    local action = self.target and self.target.onClick
    local ok, result = false, false
    if Controls.IsReload(action) then ok, result = xpcall(action.prepare or nop, geterrorhandler()) end
    if not ok or result == false then self:SetAttribute("type", nil) end
  end)
  f:SetScript("PostClick", function(self)
    self.clicking = nil
    self:SetAttribute("type", "macro")
    if not (self.target and self.target:IsVisible()) then uncover() end
  end)
  f:RegisterEvent("PLAYER_REGEN_DISABLED")
  f:SetScript("OnEvent", uncover)
  f:Hide()
  return f
end

local function coverIfReload(self)
  if InCombatLockdown() or not Controls.IsReload(self.onClick) or not self:IsEnabled() then return end
  cover = cover or newCover()
  local scale = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
  cover:ClearAllPoints()
  cover:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", self:GetLeft() * scale, self:GetBottom() * scale)
  cover:SetSize(self:GetWidth() * scale, self:GetHeight() * scale)
  cover.target = self
  cover:Show()
end

function Controls.ArmReload(f)
  f:HookScript("OnEnter", coverIfReload)
  f:HookScript("OnLeave", uncover)
  f:HookScript("OnHide", uncover)
end

-- Buttons answer left and right clicks through onClick and onRightClick.
local function click(self, mouseButton)
  local callback = mouseButton == "RightButton" and self.onRightClick or self.onClick
  if type(callback) == "function" then callback(self, mouseButton) end
end

-- Disabled buttons dim under a dark overlay.
local function dimWhenDisabled(f)
  f.disabledOverlay = f:CreateTexture(nil, "OVERLAY")
  f.disabledOverlay:SetAllPoints()
  f.disabledOverlay:SetTexture([[Interface\Tooltips\UI-Tooltip-Background]])
  f.disabledOverlay:SetVertexColor(.1, .1, .1)
  f.disabledOverlay:SetAlpha(.834)
  f.disabledOverlay:Hide()
  f:SetScript("OnDisable", function(self) self.disabledOverlay:Show() end)
  f:SetScript("OnEnable", function(self) self.disabledOverlay:Hide() end)
end

local function newButton(parent, width, height, template)
  local f = CreateFrame("Button", nil, parent, template)
  Mixin(f, Tooltip)
  f:SetSize(width, height)
  f:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  f:SetScript("OnClick", click)
  dimWhenDisabled(f)
  return f
end

local TextButton = {}
function TextButton:SetTextTruncated(text, maxWidth) fitText(self, self.Text, text, maxWidth) end

-- A grey rectangle with text.
function Controls.Button(parent, width, height, text, fontSize)
  local f = newButton(parent, width, height, "BackdropTemplate")
  Mixin(f, TextButton)
  f:SetBackdrop(FIELD)
  f:SetBackdropColor(1, 1, 1, .7)
  f:SetBackdropBorderColor(0, 0, 0, 1)
  f.Text = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  f.Text:SetPoint("CENTER")
  f.Text:SetFont(addon.FONT, fontSize, "")
  f:SetFontString(f.Text)
  f:SetPushedTextOffset(1, -1)
  f:SetText(text)
  f:SetScript("OnEnter", function(self)
    self:SetBackdropBorderColor(1, 1, 1, 1)
    self:ShowTooltip()
  end)
  f:SetScript("OnLeave", function(self)
    self:SetBackdropBorderColor(0, 0, 0, 1)
    self:HideTooltip()
  end)
  Controls.ArmReload(f)
  return f
end

local IconButton = {}
-- A texture path or file ID covers every state, highlighted additively; an atlas is used as is.
function IconButton:SetIcon(texture)
  if type(texture) == "string" and texture ~= "" and C_Texture.GetAtlasInfo(texture) then
    for _, state in ipairs({ "Normal", "Pushed", "Disabled", "Highlight" }) do
      self["Set" .. state .. "Texture"](self, "")
      self["Get" .. state .. "Texture"](self):SetAtlas(texture)
    end
    return
  end
  self:SetNormalTexture(texture)
  self:SetPushedTexture(texture)
  self:SetDisabledTexture(texture)
  self:SetHighlightTexture(texture, "ADD")
end

function IconButton:IconRegions()
  return self:GetNormalTexture(), self:GetPushedTexture(), self:GetHighlightTexture(), self:GetDisabledTexture()
end

function Controls.IconButton(parent, size, texture)
  local f = newButton(parent, size, size)
  Mixin(f, IconButton)
  if texture then f:SetIcon(texture) end
  f:SetScript("OnEnter", f.ShowTooltip)
  f:SetScript("OnLeave", f.HideTooltip)
  Controls.ArmReload(f)
  return f
end

local Checkbox = {}
function Checkbox:SetChecked(checked)
  self.checked = not not checked
  self:Paint()
end
function Checkbox:GetChecked() return self.checked end
-- Checked boxes fill Wago red; a disabled box fades and hides its mark.
function Checkbox:Paint()
  local enabled = self:IsEnabled()
  self:SetBackdropColor(unpack(self.checked and { .76, .15, .18, 1 } or { .09, .09, .09, 1 }))
  self.Check:SetShown(self.checked and enabled)
  self:SetAlpha(enabled and 1 or .4)
end

-- A square that toggles and reports the new state to onToggle.
function Controls.Checkbox(parent, size)
  local f = CreateFrame("Button", nil, parent, "BackdropTemplate")
  Mixin(f, Checkbox)
  f:SetSize(size, size)
  f:SetBackdrop(FIELD)
  f:SetBackdropBorderColor(.3, .3, .3, 1)
  f.Check = f:CreateTexture(nil, "OVERLAY")
  f.Check:SetTexture([[Interface\Buttons\UI-CheckBox-Check]])
  f.Check:SetDesaturated(true)
  f.Check:SetSize(size, size)
  f.Check:SetPoint("CENTER", f, "CENTER", -1, -1)
  f:SetScript("OnClick", function(self)
    self:SetChecked(not self.checked)
    if self.onToggle then self.onToggle(self.checked) end
  end)
  f:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(1, 1, 1, 1) end)
  f:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(.3, .3, .3, 1) end)
  f:SetScript("OnEnable", f.Paint)
  f:SetScript("OnDisable", f.Paint)
  f:SetChecked(false)
  return f
end

-- The open selector's option list. One list serves every selector, so opening one closes any other.
local ROW_HEIGHT, VISIBLE_ROWS, SCROLLBAR_SPACE = 30, 12, 18
local menu

local function closeMenu()
  if not menu or not menu.owner then return end
  menu.owner = nil
  menu:Hide()
end

local function paintRow(row)
  local hovered = row:IsMouseOver()
  for _, action in ipairs(row.actions) do
    hovered = hovered or (action:IsShown() and action:IsMouseOver())
  end
  for _, action in ipairs(row.actions) do action:SetShown(row.entry.rename ~= nil and hovered) end
  row.highlight:SetShown(hovered)
end

local function rowAction(row, texture, tooltip, offset, desaturate)
  local action = Controls.IconButton(row, 22, texture)
  action:SetPoint("RIGHT", row, "RIGHT", offset, 0)
  for _, region in ipairs({ action:IconRegions() }) do region:SetDesaturated(desaturate) end
  action:SetTooltip(tooltip)
  action:HookScript("OnEnter", function() paintRow(row) end)
  action:HookScript("OnLeave", function() paintRow(row) end)
  return action
end

local function pick(row)
  local owner, entry = menu.owner, row.entry
  closeMenu()
  if not entry.action then owner:ShowEntry(entry) end
  if entry.onclick then entry.onclick() end
end

local function menuRow(index)
  local row = menu.rows[index]
  if row then return row end
  row = CreateFrame("Button", nil, menu.content)
  row:SetHeight(ROW_HEIGHT)
  row.selected = row:CreateTexture(nil, "BACKGROUND")
  row.selected:SetTexture([[Interface\RAIDFRAME\Raid-Bar-Hp-Fill]])
  row.selected:SetVertexColor(1, 1, 0, .5)
  row.selected:SetTexCoord(0, 29 / 32, 5 / 32, 27 / 32)
  row.selected:SetHeight(24)
  row.selected:SetPoint("LEFT")
  row.highlight = row:CreateTexture(nil, "ARTWORK")
  row.highlight:SetTexture([[Interface\Buttons\UI-Listbox-Highlight]])
  row.highlight:SetBlendMode("ADD")
  row.highlight:SetHeight(22)
  row.highlight:SetPoint("LEFT")
  -- The template gives option text the drop shadow it always had.
  row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.label:SetPoint("LEFT", row, "LEFT", 4, 0)
  row.label:SetJustifyH("LEFT")
  row.label:SetWordWrap(false)
  row.label:SetTextColor(1, 1, 1, 1)
  row.actions = {
    rowAction(row, [[Interface\Buttons\UI-OptionsButton]], "Rename UI pack", -30, true),
    rowAction(row, [[Interface\Buttons\UI-GroupLoot-Pass-Up]], "Delete UI pack", -3, false),
  }
  row.actions[1].onClick = function(self) self:HideTooltip(); local entry = row.entry; closeMenu(); entry.rename() end
  row.actions[2].onClick = function(self) self:HideTooltip(); local entry = row.entry; closeMenu(); entry.delete() end
  row:SetScript("OnEnter", paintRow)
  row:SetScript("OnLeave", paintRow)
  row:SetScript("OnMouseDown", pick)
  menu.rows[index] = row
  return row
end

local function buildMenu()
  menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
  menu:SetFrameStrata("FULLSCREEN")
  menu:EnableMouse(true)
  menu:SetBackdrop(FLAT)
  menu:SetBackdropColor(PANEL[1] * PANEL[4], PANEL[2] * PANEL[4], PANEL[3] * PANEL[4], 1)
  menu:SetBackdropBorderColor(.2, .2, .2, .8)
  menu.list = CreateFrame("ScrollFrame", nil, menu, "UIPanelScrollFrameTemplate")
  menu.list:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, -1)
  local bar = menu.list.ScrollBar
  Controls.SkinScrollbar(bar, { bar.ScrollUpButton, bar.ScrollDownButton })
  bar:ClearAllPoints()
  bar:SetPoint("TOPLEFT", menu.list, "TOPRIGHT", 3, 0)
  bar:SetPoint("BOTTOMLEFT", menu.list, "BOTTOMRIGHT", 3, 0)
  menu.content = CreateFrame("Frame", nil, menu.list)
  menu.list:SetScrollChild(menu.content)
  menu.rows = {}
  -- Hiding the window hides the list too; it must not come back with the window.
  menu:SetScript("OnHide", function(self)
    self.owner = nil
    if self:IsShown() then self:Hide() end
  end)
  menu:Hide()
end

local function openMenu(owner)
  local entries = owner.entriesOnOpen and owner.entriesOnOpen() or owner.entries
  if #entries == 0 then return end
  if not menu then buildMenu() end
  closeMenu()
  menu.owner = owner
  menu:SetParent(addon.frames.mainFrame)
  menu:SetFrameStrata("FULLSCREEN")
  local width = owner:GetWidth()
  local scrolling = #entries > VISIBLE_ROWS
  local listWidth = width - (scrolling and SCROLLBAR_SPACE or 0)
  local height = math.min(#entries, VISIBLE_ROWS) * ROW_HEIGHT
  menu:ClearAllPoints()
  menu:SetPoint("TOPLEFT", owner, "BOTTOMLEFT")
  menu:SetSize(width, height + 2)
  menu.list:SetSize(listWidth, height)
  menu.content:SetSize(listWidth, #entries * ROW_HEIGHT)
  menu.list.ScrollBar:SetShown(scrolling)
  local selectedIndex
  for index, entry in ipairs(entries) do
    local row = menuRow(index)
    row.entry = entry
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", menu.content, "TOPLEFT", 1, -(index - 1) * ROW_HEIGHT)
    row:SetWidth(listWidth - 2)
    row.label:SetFont(addon.FONT, owner.menuFontSize, "")
    row.label:SetWidth(width - (entry.rename and 93 or 42))
    row.label:SetText(entry.label)
    -- The selection and hover marks stop short of the rename and delete icons.
    local markWidth = listWidth - 2 - (entry.rename and 58 or 27)
    row.selected:SetWidth(markWidth)
    row.highlight:SetWidth(markWidth)
    local selected = not selectedIndex and not entry.action and entry.label == owner.shownLabel
    row.selected:SetShown(selected)
    if selected then selectedIndex = index end
    for _, action in ipairs(row.actions) do action:SetEnabled(not addon.state.busy) end
    row:Show()
    paintRow(row)
  end
  for index = #entries + 1, #menu.rows do menu.rows[index]:Hide() end
  -- A long list opens with the current choice in view, once the scroll range knows the new length.
  menu.list:UpdateScrollChildRect()
  menu.list:SetVerticalScroll(scrolling and selectedIndex and math.max(0, selectedIndex * ROW_HEIGHT - 4 * ROW_HEIGHT) or 0)
  menu:Show()
end

function Controls.MenuShown()
  return menu ~= nil and menu:IsShown()
end

local Dropdown = {}
function Dropdown:SetEntries(entries) self.entries = entries end
function Dropdown:GetValue() return self.value end
-- Shows the entry with this value, or the placeholder in faded text when none matches.
function Dropdown:SetValue(value, placeholder)
  for _, entry in ipairs(self.entries) do
    if entry.value == value and value ~= nil then self:ShowEntry(entry); return end
  end
  self.value, self.shownLabel = nil, nil
  self.icon:SetShown(not self.flat)
  self.label:SetPoint("LEFT", self, "LEFT", 24, 0)
  self.label:SetTextColor(1, 1, 1, .4)
  self.label:SetText(placeholder)
end
function Dropdown:ShowEntry(entry)
  self.value, self.shownLabel = entry.value, entry.label
  self.icon:Hide()
  self.label:SetPoint("LEFT", self, "LEFT", 4, 0)
  self.label:SetTextColor(1, 1, 1, 1)
  fitText(self.label, self.label, entry.label, self:GetWidth() - 30)
end
-- A locked selector fades and does not open, but still explains itself on hover.
function Dropdown:SetEnabled(enabled)
  self.locked = not enabled
  self:SetAlpha(enabled and 1 or .4)
  if self.locked and menu and menu.owner == self then closeMenu() end
end
function Dropdown:Enable() self:SetEnabled(true) end
function Dropdown:Disable() self:SetEnabled(false) end
function Dropdown:IsEnabled() return not self.locked end
function Dropdown:Close()
  if menu and menu.owner == self then closeMenu() end
end

-- A selector over a list of entries: { value, label, onclick }. An action entry runs onclick without becoming the
-- value, and an entry with rename and delete callbacks offers both on hover. entriesOnOpen, when set, supplies
-- the entries each time the list opens. Flat selectors match the header around them.
function Controls.Dropdown(parent, width, height, flat)
  local f = CreateFrame("Button", nil, parent, "BackdropTemplate")
  Mixin(f, Tooltip, Dropdown)
  f.flat, f.entries, f.menuFontSize = flat, {}, 16
  f:SetSize(width, height)
  f:SetBackdrop(flat and FLAT or FIELD)
  local border = flat and { .23, .23, .23, 1 } or { 0, 0, 0, 1 }
  local hoverBorder = flat and { .45, .45, .45, 1 } or { 1, 1, 1, 1 }
  f:SetBackdropColor(unpack(flat and { .086, .086, .086, 1 } or { 1, 1, 1, .7 }))
  f:SetBackdropBorderColor(unpack(border))
  f.icon = f:CreateTexture(nil, "ARTWORK")
  f.icon:SetPoint("LEFT", f, "LEFT", 2, 0)
  f.icon:SetSize(20, 20)
  f.icon:SetTexture([[Interface\COMMON\UI-ModelControlPanel]])
  f.icon:SetTexCoord(0.625, 0.78125, 0.328125, 0.390625)
  f.icon:SetVertexColor(1, 1, 1, .4)
  f.label = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  f.label:SetFont(addon.FONT, 16, "")
  f.label:SetJustifyH("LEFT")
  f.label:SetWordWrap(false)
  f.arrow = f:CreateTexture(nil, "OVERLAY")
  if flat then
    -- The arrow texture points up, so its coordinates flip it into a down chevron.
    f.arrow:SetTexture([[Interface\AddOns\WagoUI\media\calloutArrow]])
    f.arrow:SetTexCoord(0, 1, 1, 0)
    f.arrow:SetVertexColor(.7, .7, .7, 1)
    f.arrow:SetSize(12, 6)
    f.arrow:SetPoint("RIGHT", f, "RIGHT", -10, 0)
  else
    f.arrow:SetTexture([[Interface\BUTTONS\arrow-Down-Down]])
    f.arrow:SetSize(16, 16)
    f.arrow:SetPoint("RIGHT", f, "RIGHT", -2, -3)
  end
  f:SetScript("OnEnter", function(self)
    self:SetBackdropBorderColor(unpack(hoverBorder))
    self:ShowTooltip()
  end)
  f:SetScript("OnLeave", function(self)
    self:SetBackdropBorderColor(unpack(border))
    self:HideTooltip()
  end)
  f:SetScript("OnMouseDown", function(self)
    if menu and menu.owner == self then closeMenu()
    elseif not self.locked then openMenu(self) end
  end)
  f:SetScript("OnHide", function(self) self:Close() end)
  return f
end
