-- Pooled widgets shared by every workspace view.
local addon = select(2, ...)
local LWF = LibStub("LibWagoFramework")
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
  local f = widget(parent, pool or "button", function() return LWF:CreateButton(parent, 80, 30, "", 14) end)
  f:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
  f:SetSize(width, height or 30)
  f.text_overlay:SetFont(addon.FONT, fontSize or 14, "")
  f:SetTextTruncated(text, width - 12)
  f:SetTooltip(tooltip)
  addon:UseWidgetTooltip(f)
  f:SetEnabled(not addon.state.busy)
  f:SetClickFunction(onClick)
  return f
end

-- "primary" is the filled Wago red, "outline" a quieter red entry point, "neutral" a plain way back.
local function ctaButton(parent, text, x, y, width, height, onClick, style, fontSize)
  local red = addon.colorRGB
  local f = button(parent, text, x, y, width, onClick, nil, height, fontSize or 18, "ctaButton")
  local frame = f.widget or f.button or f
  if not f.paintCta then
    f.paintCta = function()
      local hovered = frame:IsMouseOver() and not addon.state.busy
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
    -- Hooks run after the framework's own hover handlers, so the CTA colors win.
    frame:HookScript("OnEnter", f.paintCta)
    frame:HookScript("OnLeave", f.paintCta)
  end
  f.ctaStyle = style or "primary"
  f.text_overlay:SetTextColor(1, 1, 1, 1)
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
  local icon = widget(parent, "addonIcon", function() return LWF:CreateIconButton(parent, 36, 134400) end)
  icon:SetPoint("TOPLEFT", parent, "TOPLEFT", compact and 8 or 14, -(y + (compact and 4 or 8)))
  local texture = moduleName == "Additional Addons" and [[Interface\AddOns\WagoUI\media\wagoLogo512]] or lap and lap.icon
  if not texture or texture == "" then texture = 134400 end
  icon:SetTexture(texture, true, true, true)
  -- A 1.2x zoom keeps the central 1/1.2 of each texture, in every button state.
  for _, region in ipairs({ icon:GetNormalTexture(), icon:GetPushedTexture(), icon:GetHighlightTexture(), icon:GetDisabledTexture() }) do
    region:SetTexCoord(1 / 12, 11 / 12, 1 / 12, 11 / 12)
  end
  local canOpen = lap and lap.openConfig and lap:isLoaded()
  icon:SetEnabled(not addon.state.busy and not not canOpen)
  icon:SetTooltip(canOpen and ("Open " .. moduleName .. " settings") or moduleName)
  addon:UseWidgetTooltip(icon)
  icon:SetClickFunction(function() if canOpen then lap:openConfig() end end)
  icon:SetClickFunction(nil, nil, nil, "RightButton")
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
    local box = LWF:CreateTextEntry(parent, width, 34, nil, 14).editbox
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
  local f = widget(parent, "check", function()
    local box = LWF:CreateCheckbox(parent, 22, nil, false)
    box.backdrop_enabledcolor = { 0.76, 0.15, 0.18, 1 }
    box.backdrop_disabledcolor = { 0.09, 0.09, 0.09, 1 }
    box:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    box.checked_texture:SetDesaturated(true)
    return box
  end)
  f:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -(y + 3))
  f:SetValue(not not value)
  f:SetSwitchFunction(function(_, _, checked) callback(checked) end)
  if addon.state.busy then f:Disable() else f:Enable() end
  label(parent, text, x + 32, y + 6, parent:GetWidth() - x - 40, 14)
  return f
end

local function skinScrollbar(bar, arrows)
  local thumb = bar:GetThumbTexture()
  for _, region in ipairs({ bar:GetRegions() }) do
    if region ~= thumb then region:Hide() end
  end
  -- Keep native dragging, wheel scrolling and overflow detection; replace only the skin.
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

local function dropdown(parent, selected, entries, x, y, width, placeholder)
  for _, entry in ipairs(entries) do entry.font = addon.FONT end
  local f = widget(parent, "dropdown", function()
    local box = LWF:CreateDropdown(parent, width, 32, 16, 1.5, function() return {} end)
    addon:UseWidgetTooltip(box)
    box:SetScript("OnEnter", function()
      box:SetBackdropBorderColor(1, 1, 1, 1)
      box:ShowTooltip()
    end)
    box:SetScript("OnLeave", function()
      box:SetBackdropBorderColor(0, 0, 0, 1)
      box:HideTooltip()
    end)
    local menu, border = box.dropdown.dropdownframe, box.dropdown.dropdownborder
    skinScrollbar(menu.slider, { menu.cima, menu.baixo })
    border:SetScale(1.5)
    menu:HookScript("OnShow", function()
      -- DF measures menu text independently; keep long names and scrolling within the selector.
      local menuWidth = box:GetWidth() / 1.5
      local child = menu:GetScrollChild()
      menu:SetWidth(menuWidth)
      border:SetWidth(menuWidth)
      child:SetWidth(menuWidth)
      child.selected:SetWidth(menuWidth - 24)
      child.mouseover:SetWidth(menuWidth - 24)
      for _, row in ipairs(box.menus) do
        if row:IsShown() and row.packActionsEnabled and row.table.value == box:GetValue() then
          -- The cog starts 35px from the row's right edge; leave a 4px gap.
          child.selected:SetWidth(row:GetWidth() - 39)
          break
        end
      end
    end)
    box.OnUpdateOptionFrame = function(_, row, entry)
      reset(row)
      row.packActionsEnabled = entry.rename ~= nil
      if not row.updateActionHover then
        row.updateActionHover = function()
          local hovered = row:IsMouseOver()
          local actions = row.pools and row.pools.packAction or {}
          for _, action in ipairs(actions) do
            hovered = hovered or (action:IsShown() and action:IsMouseOver())
          end
          for _, action in ipairs(actions) do
            action:SetShown(row.packActionsEnabled and hovered)
          end
          if hovered then
            menu:GetScrollChild().mouseover:SetWidth(row:GetWidth() - (row.packActionsEnabled and 39 or 0))
          end
        end
        row:HookScript("OnEnter", row.updateActionHover)
        row:HookScript("OnLeave", row.updateActionHover)
      end
      row.label:SetFont(addon.FONT, 16 / 1.5, "")
      row.label:SetWidth(box:GetWidth() / 1.5 - (entry.rename and 62 or 28))
      row.label:SetWordWrap(false)
      if entry.rename then
        local function action(texture, tooltip, offset, callback, desaturate)
          local icon = widget(row, "packAction", function()
            local control = LWF:CreateIconButton(row, 15, texture)
            addon:UseWidgetTooltip(control)
            control:HookScript("OnEnter", row.updateActionHover)
            control:HookScript("OnLeave", row.updateActionHover)
            return control
          end)
          icon:SetPoint("RIGHT", row, "RIGHT", offset, 0)
          icon:SetTexture(texture, true, true, true)
          for _, region in ipairs({ icon:GetNormalTexture(), icon:GetPushedTexture(), icon:GetHighlightTexture(), icon:GetDisabledTexture() }) do
            region:SetDesaturated(desaturate)
          end
          icon:SetTooltip(tooltip)
          icon:SetEnabled(not addon.state.busy)
          icon:SetClickFunction(function() icon:HideTooltip(); box:Close(); callback() end)
        end
        action([[Interface\Buttons\UI-OptionsButton]], "Rename UI pack", -20, entry.rename, true)
        action([[Interface\Buttons\UI-GroupLoot-Pass-Up]], "Delete UI pack", -2, entry.delete, false)
      end
      row.updateActionHover()
      if entry.action then
        row:SetScript("OnMouseDown", function() box:Close(); entry.onclick() end)
      else
        row:SetScript("OnMouseDown", DetailsFrameworkDropDownOptionClick)
      end
    end
    return box
  end)
  f:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
  f:SetWidth(width)
  f.OnMouseDownHook = nil
  f:SetTooltip(nil)
  f.moduleName, f.profileRow = nil, nil
  f:SetMenuSize(width / 1.5, 240)
  f:SetFunction(function() return entries end)
  f:Refresh()
  f:Select(selected)
  if selected == nil then f:NoOptionSelected(); f.label:SetText(placeholder or "Choose…") end
  f.label:SetFont(addon.FONT, 16, "")
  if addon.state.busy then f:Disable() else f:Enable() end
  return f
end

local function scroll(parent, x, y, width, height)
  local f = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
  local bar = f.ScrollBar
  skinScrollbar(bar, { bar.ScrollUpButton, bar.ScrollDownButton })
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
UI.widget = widget
