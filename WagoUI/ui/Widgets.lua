-- Pooled widgets shared by every workspace view.
local addon = select(2, ...)
local Controls = addon.Controls
local LAP = LibStub("LibAddonProfiles")

-- Private namespace shared by the workspace files; ui/load.xml sets their load order.
local UI = {}
addon.UI = UI
-- Workspace frames plus session-only view state (search text, selected variation tab).
UI.view = {}

-- Creator columns: addon, profile selector, variation toggles, then row actions.
local PROFILE_X, PROFILE_WIDTH, VARIATIONS_X, VARIATIONS_RIGHT = 300, 210, 524, 826

-- Reuse widgets across redraws.
local function reset(parent)
  for _, pool in pairs(parent.pools or {}) do
    for _, widget in ipairs(pool) do widget:Hide() end
  end
  parent.used = {}
end

local function widget(parent, kind, create)
  parent.pools = parent.pools or {}
  parent.used = parent.used or {}
  parent.pools[kind] = parent.pools[kind] or {}
  local pool = parent.pools[kind]
  local index = (parent.used[kind] or 0) + 1
  parent.used[kind] = index
  if not pool[index] then pool[index] = create() end
  local result = pool[index]
  result:ClearAllPoints()
  result:Show()
  return result
end

local function label(parent, text, x, y, width, size, color)
  local f = widget(parent, "label", function() return parent:CreateFontString(nil, "OVERLAY", "GameFontNormal") end)
  f:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
  f:SetWidth(width)
  f:SetFont(addon.FONT, size or 16, "")
  f:SetJustifyH("LEFT")
  f:SetWordWrap(false)
  f:SetTextColor(unpack(color or { 0.9, 0.9, 0.9 }))
  f:SetText(text)
  return f
end

local function button(parent, text, x, y, width, onClick, tooltip, height, fontSize, pool)
  local f = widget(parent, pool or "button", function() return Controls.Button(parent, 80, 30, "", 14) end)
  f:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
  f:SetSize(width, height or 30)
  f.Text:SetFont(addon.FONT, fontSize or 14, "")
  f:SetTextTruncated(text, width - 12)
  f:SetTooltip(tooltip)
  f:SetEnabled(not addon.state.busy)
  f.onClick = onClick
  return f
end

-- "primary" is the filled Wago red, "outline" a quieter red entry point, "neutral" a plain way back.
local function ctaButton(parent, text, x, y, width, height, onClick, style, fontSize)
  local red = addon.colorRGB
  local f = button(parent, text, x, y, width, onClick, nil, height, fontSize or 18, "ctaButton")
  if not f.paintCta then
    f.paintCta = function()
      local hovered = f:IsMouseOver() and not addon.state.busy
      if f.ctaStyle == "neutral" then
        local shade = hovered and .2 or .13
        f:SetBackdropColor(shade, shade, shade, 1)
        f:SetBackdropBorderColor(.35, .35, .35, 1)
      elseif f.ctaStyle == "outline" then
        f:SetBackdropColor(red[1], red[2], red[3], hovered and .45 or .15)
        f:SetBackdropBorderColor(red[1], red[2], red[3], 1)
      else
        local lift = hovered and .12 or 0
        f:SetBackdropColor(red[1] + lift, red[2] + lift, red[3] + lift, 1)
        f:SetBackdropBorderColor(math.min(1, red[1] + .3), red[2] + .2, red[3] + .2, 1)
      end
    end
    -- Hooks run after the button's own hover handlers, so the CTA colors win.
    f:HookScript("OnEnter", f.paintCta)
    f:HookScript("OnLeave", f.paintCta)
  end
  f.ctaStyle = style or "primary"
  f.Text:SetTextColor(1, 1, 1, 1)
  f.paintCta()
  return f
end

local function rowBackground(parent, y, height, alpha)
  local texture = widget(parent, "rowBackground", function() return parent:CreateTexture(nil, "BACKGROUND") end)
  texture:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -y)
  texture:SetSize(parent:GetWidth() - 8, height)
  texture:SetColorTexture(0.8, 0.8, 0.8, alpha)
end

local function profileConnector(parent, x, y, width, height)
  local line = widget(parent, "profileConnector", function() return parent:CreateTexture(nil, "ARTWORK") end)
  line:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
  line:SetSize(width, height)
  line:SetColorTexture(.4, .43, .47, 1)
end

local function addonRow(parent, moduleName, y, color, status, shade, compact)
  local lap = LAP:GetModule(moduleName)
  if not compact then rowBackground(parent, y, 52, shade or 0.14) end
  local icon = widget(parent, "addonIcon", function() return Controls.IconButton(parent, 36) end)
  icon:SetPoint("TOPLEFT", parent, "TOPLEFT", compact and 8 or 14, -(y + (compact and 4 or 8)))
  local texture = moduleName == "Additional Addons" and [[Interface\AddOns\WagoUI\media\wagoLogo512]] or lap and lap.icon
  if not texture or texture == "" then texture = 134400 end
  icon:SetIcon(texture)
  -- A 1.2x zoom keeps the central 1/1.2 of each texture, in every button state.
  for _, region in ipairs({ icon:IconRegions() }) do
    region:SetTexCoord(1 / 12, 11 / 12, 1 / 12, 11 / 12)
  end
  local canOpen = lap and lap.openConfig and lap:isLoaded()
  icon:SetEnabled(not addon.state.busy and not not canOpen)
  icon:SetTooltip(canOpen and ("Open " .. moduleName .. " settings") or moduleName)
  icon.onClick = function() if canOpen then lap:openConfig() end end
  icon.onRightClick = nil
  label(parent, moduleName, compact and 56 or 62, y + (status and (compact and 7 or 8) or (compact and 13 or 17)),
    compact and PROFILE_X - 86 or 476, compact and 16 or 18, color)
  if status then
    label(parent, status, compact and 56 or 62, y + (compact and 27 or 31), compact and PROFILE_X - 86 or 560,
      compact and 10 or 13, compact and { .6, .6, .6 } or { .65, .65, .65 })
  end
  return icon
end

local function input(parent, text, x, y, width, changed)
  local f = widget(parent, "input", function()
    local box = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    addon:StyleEditBox(box)
    return box
  end)
  f:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
  f:SetSize(width, 34)
  f:SetEnabled(true)
  f:SetMaxLetters(0)
  f:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  f:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  -- Pooled inputs move between dialogs; drop any tab order a previous one set.
  f:SetScript("OnTabPressed", nil)
  f:SetScript("OnTextChanged", nil)
  f:SetText(text or "")
  f:SetCursorPosition(0)
  f:SetScript("OnTextChanged", function(self, user) if user and changed then changed(self:GetText()) end end)
  return f
end

local function check(parent, text, value, x, y, callback)
  local f = widget(parent, "check", function() return Controls.Checkbox(parent, 22) end)
  f:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -(y + 3))
  f:SetChecked(value)
  f.onToggle = callback
  f:SetEnabled(not addon.state.busy)
  label(parent, text, x + 32, y + 6, parent:GetWidth() - x - 40, 14)
  return f
end

-- menuFontSize shrinks the option text for a narrow selector whose labels would otherwise be cut off.
-- Flat selectors pool apart from the classic ones, so a reused frame never carries the other look.
local function dropdown(parent, selected, entries, x, y, width, placeholder, menuFontSize, flat)
  local f = widget(parent, flat and "flatDropdown" or "dropdown", function() return Controls.Dropdown(parent, width, 32, flat) end)
  f:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
  f:SetWidth(width)
  f.entriesOnOpen = nil
  f:SetTooltip(nil)
  f.moduleName, f.profileRow = nil, nil
  f.menuFontSize = menuFontSize or 16
  f:SetEntries(entries)
  f:SetValue(selected, placeholder or "Choose…")
  f:SetEnabled(not addon.state.busy)
  return f
end

-- Names a control the creator tour can point at. Pooled widgets move between rows, so every render registers
-- them again, and the first registration of a name wins. Clipped controls live in the scrolling list.
local function tourTarget(name, control, clipped)
  local targets = UI.view.tourTargets
  if targets[name] then return end
  targets[name] = { control = control, clipped = clipped }
end

local function scroll(parent, x, y, width, height)
  local f = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
  local bar = f.ScrollBar
  Controls.SkinScrollbar(bar, { bar.ScrollUpButton, bar.ScrollDownButton })
  bar:ClearAllPoints()
  bar:SetPoint("TOPLEFT", f, "TOPRIGHT", 6, 0)
  bar:SetPoint("BOTTOMLEFT", f, "BOTTOMRIGHT", 6, 0)
  f.scrollBarHideable = true
  bar:Hide()
  f:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
  f:SetSize(width, height)
  local content = CreateFrame("Frame", nil, f)
  content:SetSize(width, height)
  f:SetScrollChild(content)
  return f, content
end

UI.PROFILE_WIDTH = PROFILE_WIDTH
UI.PROFILE_X = PROFILE_X
UI.VARIATIONS_RIGHT = VARIATIONS_RIGHT
UI.VARIATIONS_X = VARIATIONS_X
UI.addonRow = addonRow
UI.button = button
UI.check = check
UI.ctaButton = ctaButton
UI.dropdown = dropdown
UI.input = input
UI.label = label
UI.profileConnector = profileConnector
UI.reset = reset
UI.rowBackground = rowBackground
UI.scroll = scroll
UI.tourTarget = tourTarget
UI.widget = widget
