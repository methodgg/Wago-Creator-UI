local addon = select(2, ...)
local DF = DetailsFramework
local LWF = LibStub("LibWagoFramework")
local LAP = LibStub("LibAddonProfiles")
local Packs = addon.Packs
local ui = {}
local render, variationEditor
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

local function notice(text)
  addon.state.notice = text
  render()
end

local function safely(callback)
  local ok, problem = pcall(callback)
  if not ok then
    local target = ui.modal:IsShown() and ui.modal.error or ui.notice
    local message = tostring(problem):gsub("^.-:%d+: ", "")
    if target == ui.notice then addon.state.notice = message end
    target:SetText(message)
  end
  return ok
end

local function closeModal()
  ui.modal:Hide()
  ui.modalShade:Hide()
end

local function modal(title, width, height)
  width, height = width or 600, height or 524
  local f = ui.modal
  reset(f)
  reset(f.content)
  f:ClearAllPoints()
  f:SetSize(width, height)
  f:SetPoint("CENTER")
  f.scroll:SetWidth(width - 74)
  f.content:SetWidth(width - 74)
  f.scroll:ClearAllPoints()
  f.scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -78)
  f.scroll:Hide()
  f.error = label(f, "", 24, height - 78, width - 48, 14, { 1, 0.4, 0.3 })
  label(f, title, 24, 22, width - 110, 22)
  local close = widget(f, "closeButton", function()
    local control = CreateFrame("Button", nil, f)
    control:SetSize(16, 16)
    for _, state in ipairs({ "Normal", "Highlight", "Pushed" }) do
      control["Set" .. state .. "Texture"](control, [[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
      control["Get" .. state .. "Texture"](control):SetDesaturated(true)
    end
    control:SetAlpha(.7)
    control:SetScript("OnClick", closeModal)
    return control
  end)
  close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -10)
  f:Show()
  ui.modalShade:SetBackdropColor(0, 0, 0, 0.65)
  ui.modalShade:SetScript("OnMouseDown", nil)
  ui.modalShade:Show()
  return f
end

local function modalList(f, height)
  f.scroll:SetHeight(height or 340)
  f.scroll:SetVerticalScroll(0)
  f.scroll:Show()
  return f.content
end

local function textDialog(title, value, action, callback)
  local f = modal(title, 440, 224)
  label(f, "Enter a name for your UI Pack.", 24, 66, 392, 14, { 0.7, 0.7, 0.7 })
  local entry = input(f, value, 24, 92, 392)
  entry:SetMaxLetters(120)
  local function submit()
    if safely(function() callback(entry:GetText()) end) then closeModal(); render() end
  end
  button(f, "Cancel", 184, 170, 100, closeModal)
  button(f, action, 296, 170, 120, submit)
  entry:SetScript("OnEnterPressed", submit)
  entry:SetScript("OnEscapePressed", closeModal)
  entry:SetFocus()
  entry:HighlightText()
end

local function resolutionText(variation)
  local size = variation.resolution
  return size and (size.width .. " × " .. size.height) or "Any resolution"
end

-- Radix dark scales: background 3, hover 4, border 7, high-contrast text 12.
-- https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale
local variationStyles = {
  { background = 0x0d2847, hover = 0x003362, border = 0x205d9e, text = 0xc2e6ff }, -- blue
  { background = 0x0d2d2a, hover = 0x023b37, border = 0x1c6961, text = 0xadf0dd }, -- teal
  { background = 0x291f43, hover = 0x33255b, border = 0x56468b, text = 0xe2ddfe }, -- violet
  { background = 0x302008, hover = 0x3f2700, border = 0x714f19, text = 0xffe7b3 }, -- amber
  { background = 0x37172f, hover = 0x4b143d, border = 0x833869, text = 0xfdd1ea }, -- pink
  { background = 0x132d21, hover = 0x113b29, border = 0x28684a, text = 0xb1f1cb }, -- green
}
for _, style in ipairs(variationStyles) do
  for key, hex in pairs(style) do
    style[key] = { math.floor(hex / 65536) / 255, math.floor(hex / 256) % 256 / 255, hex % 256 / 255, 1 }
  end
end
local function variationStyle(id)
  if id == "default" then return variationStyles[1] end
  -- Stable across renames/deletions. Names remain the identifier when colors repeat.
  local index = tonumber(id:match("%d+$")) or 1
  return variationStyles[2 + (index - 1) % (#variationStyles - 1)]
end

local unassignedChip = { background = { .07, .07, .07, 1 }, border = { .24, .24, .24, 1 }, text = { .6, .6, .6, 1 } }

-- Every variation is a toggle: filled when the row is in it, outlined when not.
local function variationToggle(parent, name, id, assigned, onClick, locked)
  local chip = button(parent, name, 0, 0, 132, onClick, nil, 26, 13, "variationChip")
  chip.variationID, chip.assigned = id, assigned
  local frame = chip.widget or chip.button or chip
  chip.text_overlay:SetText(name)
  local width = math.min(132, math.max(56, chip.text_overlay:GetStringWidth() + 24))
  chip:SetWidth(width)
  chip:SetTextTruncated(name, width - 16)
  chip.text_overlay:SetWidth(width - 16)
  if not chip.alignText then
    -- Native hooks run after the framework's pressed/released text offsets.
    chip.alignText = function()
      chip.text_overlay:ClearAllPoints()
      chip.text_overlay:SetPoint("CENTER", frame, "CENTER", 0, -2)
    end
    frame:HookScript("OnMouseDown", chip.alignText)
    frame:HookScript("OnMouseUp", chip.alignText)
  end
  chip.alignText()
  local style = variationStyle(id)
  chip:SetScript("OnEnter", nil)
  chip:SetScript("OnLeave", nil)
  local function paint()
    local hovered = not locked and ui.scroll:IsMouseOver() and chip:IsMouseOver() and not addon.state.busy and not ui.modal:IsShown()
    local colors = (assigned or hovered) and style or unassignedChip
    chip:SetBackdropColor(unpack(assigned and hovered and style.hover or colors.background))
    chip:SetBackdropBorderColor(unpack(colors.border))
    chip.text_overlay:SetTextColor(unpack(colors.text))
    -- Unassigned toggles recede until hovered.
    frame:SetAlpha((assigned or hovered) and 1 or .5)
  end
  -- Locked chips only show membership; they ignore the mouse entirely.
  frame:EnableMouse(not locked)
  chip:SetScript("OnUpdate", paint)
  paint()
  return chip, width
end

local function removeVariation(pack, id)
  Packs.RemoveVariation(pack, id)
  for _, rows in pairs(addon.db.creator.profileRows and addon.db.creator.profileRows[pack.id] or {}) do
    for _, row in ipairs(rows) do
      if row.variations then row.variations[id] = nil end
    end
  end
end

local function dangerButton(parent, text, x, y, width, onClick)
  local f = button(parent, text, x, y, width, onClick, nil, nil, nil, "dangerButton")
  f:SetBackdropColor(.55, .1, .12, 1)
  return f
end

local function confirmVariationDelete(pack, id, back)
  local v = pack.variations[id]
  local users, orphans = 0, 0
  for _, p in ipairs(Packs.Profiles(pack, id)) do
    users = users + 1
    local elsewhere = false
    for other in pairs(p.variations) do elsewhere = elsewhere or other ~= id end
    if not elsewhere then orphans = orphans + 1 end
  end
  local f = modal("Delete variation", 460, 250)
  label(f, "Delete " .. v.name .. "?", 24, 66, 412, 18)
  local details = (users == 1 and "1 profile uses" or (users .. " profiles use")) .. " this variation. Profiles are kept."
  if orphans > 0 then
    details = details .. "\n" .. (orphans == 1 and "1 profile is" or (orphans .. " profiles are"))
      .. " only in " .. v.name .. " and must be assigned to another variation before saving."
  end
  label(f, details, 24, 98, 412, 14, { .7, .7, .7 }):SetWordWrap(true)
  button(f, back and "Back" or "Cancel", 176, 194, 120, back or closeModal)
  dangerButton(f, "Delete", 308, 194, 128, function()
    if safely(function() removeVariation(pack, id) end) then closeModal(); render() end
  end)
end

-- Manages one variation's details; assignments happen on the profile rows.
variationEditor = function(pack, id)
  local v = id and pack.variations[id]
  -- New variations explain the concept first; the fields move down to make room.
  local top = v and 0 or 56
  local f = modal(v and "Edit variation" or "New variation", 460, 400 + top)
  local any, includeDefault = not (v and v.resolution), false
  if not v then
    label(f, "Variations let you offer different versions of your UI, such as a healer layout or a different "
      .. "resolution. Each one bundles the profiles that make up that version, and users can install from any of them.",
      24, 58, 412, 13, { .7, .7, .7 }):SetWordWrap(true)
  end
  label(f, "Name", 24, top + 68, 412, 14)
  local title = input(f, v and v.name or "", 24, top + 92, 412)
  title:SetMaxLetters(120)
  label(f, "Resolution", 24, top + 142, 412, 14)
  -- Prefill the creator's own screen; it is usually the resolution they designed for.
  local screenWidth, screenHeight = GetPhysicalScreenSize()
  local width = input(f, tostring(v and v.resolution and v.resolution.width or screenWidth), 200, top + 164, 96)
  local times = label(f, "×", 304, top + 172, 20, 14)
  local height = input(f, tostring(v and v.resolution and v.resolution.height or screenHeight), 324, top + 164, 96)
  local function sync()
    width:SetShown(not any); height:SetShown(not any); times:SetShown(not any)
  end
  check(f, "Any resolution", any, 24, top + 166, function(value) any = value; sync() end)
  sync()
  label(f, "Description (optional)", 24, top + 214, 412, 14)
  local description = input(f, v and v.description or "", 24, top + 238, 412)
  description:SetMaxLetters(2000)
  if not v then
    check(f, "Start with the profiles from " .. pack.variations.default.name, false, 24, top + 286,
      function(value) includeDefault = value end)
  end
  local function save()
    local savedID
    local ok = safely(function()
      local size = not any and { width = tonumber(width:GetText()), height = tonumber(height:GetText()) } or nil
      savedID = Packs.SaveVariation(pack, id, title:GetText(), size, description:GetText(), includeDefault)
    end)
    if not ok then return end
    -- A new variation is usually followed by assigning profiles to it.
    if not id then ui.variationTabs[pack.id] = savedID end
    closeModal(); render()
  end
  if v and id ~= "default" then
    dangerButton(f, "Delete", 24, top + 344, 110, function()
      confirmVariationDelete(pack, id, function() variationEditor(pack, id) end)
    end)
  end
  button(f, "Cancel", 216, top + 344, 100, closeModal)
  button(f, v and "Save" or "Create", 328, top + 344, 108, save)
  title:SetScript("OnEnterPressed", save)
  title:SetScript("OnEscapePressed", closeModal)
  title:SetFocus()
  title:HighlightText()
end

local function saveCapture(pack, changes, issues)
  local generated, changed = addon:BuildReleaseNotes(pack)
  if not changed and #issues == 0 then notice("No Changes detected"); return end
  local extra = #issues > 0 and 96 or 0
  local f = modal("Release Notes", 600, 560 + extra)
  local editor = widget(f, "notesEditor", function()
    local panel = CreateFrame("Frame", nil, f, "BackdropTemplate")
    panel.scroll = scroll(panel, 10, 10, 504, 205)
    local box = CreateFrame("EditBox", nil, panel.scroll)
    box:SetMultiLine(true)
    addon:StyleEditBox(box, panel)
    box:SetJustifyH("LEFT")
    box:SetJustifyV("TOP")
    box:SetSize(504, 205)
    box:SetScript("OnEscapePressed", closeModal)
    box:SetScript("OnCursorChanged", function(_, _, y, _, height)
      local offset = panel.scroll:GetVerticalScroll()
      y = -y
      if y < offset then panel.scroll:SetVerticalScroll(y)
      elseif y + height > offset + panel.scroll:GetHeight() then
        panel.scroll:SetVerticalScroll(y + height - panel.scroll:GetHeight())
      end
    end)
    panel.scroll:SetScrollChild(box)
    panel.editbox = box
    return panel
  end)
  editor:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -98)
  editor:SetSize(552, 225)
  local notes = editor.editbox
  notes:SetText(generated)
  notes:SetCursorPosition(0)
  editor.scroll:SetVerticalScroll(0)
  label(f, "Edit your release notes below (Markdown).\nUsers see these notes when they install or update your UI Pack.",
    24, 60, 552, 13, { .8, .8, .8 }):SetWordWrap(true)
  notes:SetFocus()
  if #issues > 0 then
    f.scroll:ClearAllPoints()
    f.scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -346)
    local content = modalList(f, 80)
    local y = 0
    for _, issue in ipairs(issues) do
      local warning = label(content, issue, 0, y, 526, 13, { 1, .65, .3 })
      warning:SetWordWrap(true)
      y = y + warning:GetStringHeight() + 8
    end
    content:SetHeight(math.max(1, y))
  end
  local logo = widget(f, "saveLogo", function() return f:CreateTexture(nil, "ARTWORK") end)
  logo:SetTexture([[Interface\AddOns\WagoUI\media\wagoLogo512]])
  logo:SetSize(128, 128)
  logo:SetPoint("TOP", f, "TOP", 0, -(336 + extra))
  label(f, "Continue the upload through the Wago App after the reload!", 58, 476 + extra, 484, 16):SetJustifyH("CENTER")
  for _, x in ipairs({ 24, 546 }) do
    local warning = widget(f, "saveWarning", function() return f:CreateTexture(nil, "OVERLAY") end)
    warning:SetTexture([[Interface\DialogFrame\UI-Dialog-Icon-AlertNew]])
    warning:SetSize(30, 30)
    warning:SetPoint("TOPLEFT", f, "TOPLEFT", x, -(468 + extra))
  end
  f.error:ClearAllPoints()
  f.error:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -46)
  local function save()
    if addon.state.busy then return end
    if safely(function() addon:SaveCapturedPack(pack, notes:GetText()) end) then
      closeModal()
      notice("Saved")
      ReloadUI()
    end
  end
  button(f, "Save and Reload", 200, 504 + extra, 200, save, "Write SavedVariables for the Wago App", 40, 16, "saveReload")
    :SetBackdropColor(0, .8, 0, 1)
end

-- Installed AddOns that can be shipped as extras, keyed by their Wago ID.
local function wagoAddons()
  local found = {}
  for index = 1, C_AddOns.GetNumAddOns() do
    local id = C_AddOns.GetAddOnMetadata(index, "X-Wago-ID")
    local name = C_AddOns.GetAddOnInfo(index)
    if id and name ~= "WagoUI" and name ~= "WagoUI_Creator" then
      found[id] = { name = name, icon = C_AddOns.GetAddOnMetadata(index, "IconTexture") }
    end
  end
  return found
end

local function additionalAddons(pack)
  local f = modal("Additional AddOns", 600, 600)
  local explainer = label(f, "Include AddOns that need no configuration to be exported, such as an AddOn that only "
    .. "contains your custom media. Users can download them automatically while installing your UI Pack.\n\n"
    .. "Only AddOns that are publicly available on Wago AddOns and set the X-Wago-ID field in their TOC file are listed.",
    24, 62, 552, 13, { .7, .7, .7 })
  explainer:SetWordWrap(true)
  local top = 62 + explainer:GetStringHeight() + 16
  local height = 600 - top - 96
  -- A framed, padded box makes the scrollable region obvious.
  local panel = widget(f, "addonListPanel", function()
    local frame = CreateFrame("Frame", nil, f, "BackdropTemplate")
    frame:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8X8]], edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1 })
    frame:SetBackdropColor(.05, .05, .05, 1)
    frame:SetBackdropBorderColor(.22, .22, .22, 1)
    return frame
  end)
  panel:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -top)
  panel:SetSize(552, height)
  panel:SetFrameLevel(f:GetFrameLevel() + 1)
  f.scroll:ClearAllPoints()
  f.scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
  f.scroll:SetFrameLevel(panel:GetFrameLevel() + 1)
  local content = modalList(f, height - 8)
  local selected, entries = CopyTable(pack.additionalAddons), wagoAddons()
  for id, name in pairs(selected) do entries[id] = entries[id] or { name = name } end
  local ordered = {}
  for id, entry in pairs(entries) do table.insert(ordered, { id = id, name = entry.name, icon = entry.icon }) end
  table.sort(ordered, function(a, b) return a.name:lower() < b.name:lower() end)
  for index, item in ipairs(ordered) do
    local y = (index - 1) * 36
    if index % 2 == 0 then rowBackground(content, y, 36, .04) end
    check(content, "", selected[item.id], 10, y + 4, function(value) selected[item.id] = value and item.name or nil end)
    local icon = widget(content, "addonListIcon", function() return content:CreateTexture(nil, "ARTWORK") end)
    icon:SetPoint("TOPLEFT", content, "TOPLEFT", 44, -(y + 6))
    icon:SetSize(24, 24)
    icon:SetTexture(tonumber(item.icon) or item.icon or 134400)
    icon:SetTexCoord(1 / 12, 11 / 12, 1 / 12, 11 / 12)
    label(content, item.name, 78, y + 10, content:GetWidth() - 90, 14)
  end
  if #ordered == 0 then
    label(content, "No AddOns with an X-Wago-ID are installed.", 12, 14, content:GetWidth() - 24, 14, { .6, .6, .6 })
  end
  content:SetHeight(math.max(1, #ordered * 36))
  button(f, "Save", 426, 552, 150, function()
    pack.additionalAddons = selected
    pack.revision = pack.revision + 1
    closeModal(); render()
  end)
end

local function exportOptions(pack, moduleName)
  local lap = LAP:GetModule(moduleName)
  local f = modal(moduleName)
  local options = CopyTable(pack.exportOptions and pack.exportOptions[moduleName] or lap.exportOptions or {})
  local content = modalList(f)
  local y = 0
  for key, value in pairs(lap.exportOptions or {}) do
    if type(value) == "boolean" then
      check(content, key == "purgeWago" and "Remove Wago links" or key, options[key], 0, y,
        function(enabled) options[key] = enabled end)
      y = y + 36
    end
  end
  local blocked = CopyTable(pack.blockedAuras or {})
  if moduleName == "WeakAuras" then
    label(content, "Excluded auras", 0, y + 8, 480)
    y = y + 40
    local keys = {}
    for key in pairs(WeakAurasSaved and WeakAurasSaved.displays or {}) do table.insert(keys, key) end
    table.sort(keys)
    for _, key in ipairs(keys) do
      check(content, key, blocked[key], 0, y, function(value) blocked[key] = value or nil end)
      y = y + 34
    end
  end
  content:SetHeight(math.max(1, y))
  button(f, "Save", 424, 476, 150, function()
    pack.exportOptions = pack.exportOptions or {}
    pack.exportOptions[moduleName] = options
    if moduleName == "WeakAuras" then pack.blockedAuras = blocked end
    pack.revision = pack.revision + 1
    closeModal(); render()
  end)
end

local function startSetup()
  local function continue()
    textDialog("New UI pack", "", "Create", function(value) addon:NewPack(value) end)
  end
  if next(addon.db.creator.packs) then continue(); return end
  addon:ShowPrompt(
    "Creator tools are for people who want to share their UI and AddOn profiles publicly\nwith other users through the Wago App and Wago Website.\n\nWould you like to continue?",
    continue,
    function()
      closeModal()
      addon.db.workspaceMode = "install"
      ui.scroll:SetVerticalScroll(0)
      render()
    end,
    "Continue", "Back to UI Packs"
  )
end

-- Empty row slots are creator state, never installable profiles in published packs.
local function creatorRows(pack, moduleName)
  addon.db.creator.profileRows = addon.db.creator.profileRows or {}
  local stored = addon.db.creator.profileRows
  if not addon.db.creator.emptyRowsUnseeded then
    -- Unused main rows used to be pre-seeded with Default, which now reads as a half-done row.
    for _, modules in pairs(stored) do
      for _, rows in pairs(modules) do
        if rows[1] and not rows[1].profileID then rows[1].variations = {} end
      end
    end
    addon.db.creator.emptyRowsUnseeded = true
  end
  stored[pack.id] = stored[pack.id] or {}
  local rows = stored[pack.id][moduleName] or { { variations = {} } }
  stored[pack.id][moduleName] = rows
  local seen = {}
  for index = #rows, 1, -1 do
    local row = rows[index]
    if row.profileID and not pack.profiles[row.profileID] then
      if index == 1 then row.profileID, row.variations = nil, {}
      else table.remove(rows, index) end
    elseif row.profileID then seen[row.profileID] = true end
  end
  for _, p in ipairs(Packs.Profiles(pack)) do
    if p.moduleName == moduleName and not seen[p.id] then
      if not rows[1].profileID and not rows[1].cleared then rows[1].profileID = p.id
      else table.insert(rows, { profileID = p.id }) end
    end
  end
  return rows
end

local function rowAction(parent, texture, x, y, tooltip, callback)
  local icon = widget(parent, "rowAction", function() return LWF:CreateIconButton(parent, 28, "") end)
  icon:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -(y + 8))
  icon:SetBackdrop(nil)
  icon.disabled_overlay:SetTexture(nil)
  icon:SetTexture(texture or "", true, true, true)
  if not texture then
    for _, region in ipairs({ icon:GetNormalTexture(), icon:GetPushedTexture(), icon:GetHighlightTexture(), icon:GetDisabledTexture() }) do
      region:SetAtlas("communities-icon-addgroupplus")
    end
  end
  icon:GetDisabledTexture():SetDesaturated(true)
  icon:SetTooltip(tooltip)
  addon:UseWidgetTooltip(icon)
  icon:SetEnabled(not addon.state.busy)
  icon:SetClickFunction(callback)
  return icon
end

local allTabStyle = { background = { .2, .2, .2, 1 }, border = { .55, .55, .55, 1 }, text = { .95, .95, .95, 1 } }

local function paintTab(tab)
  local style = tab.style
  if tab.ghost then
    -- An action, not a variation: no fill or border until hovered.
    local hovered = tab:IsMouseOver()
    tab:SetBackdropColor(.14, .14, .14, hovered and 1 or 0)
    tab:SetBackdropBorderColor(.35, .35, .35, hovered and 1 or 0)
    local text = hovered and 1 or .75
    tab.label:SetTextColor(text, text, text, 1)
  elseif tab.active then
    tab:SetBackdropColor(unpack(style.background))
    tab:SetBackdropBorderColor(unpack(style.border))
    tab.label:SetTextColor(unpack(style.text))
  else
    local shade = tab:IsMouseOver() and .14 or .09
    tab:SetBackdropColor(shade, shade, shade, 1)
    tab:SetBackdropBorderColor(.22, .22, .22, 1)
    local text = tab:IsMouseOver() and .95 or .65
    tab.label:SetTextColor(text, text, text, 1)
  end
  tab.count:SetTextColor(.55, .55, .55, 1)
end

local function variationTab(parent, entry, active)
  local tab = widget(parent, "variationTab", function()
    local f = CreateFrame("Button", nil, parent, "BackdropTemplate")
    f:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8X8]], edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1 })
    f.swatch = f:CreateTexture(nil, "ARTWORK")
    f.swatch:SetSize(8, 8)
    f.swatch:SetPoint("LEFT", f, "LEFT", 11, 0)
    f.label = f:CreateFontString(nil, "OVERLAY")
    f.label:SetFont(addon.FONT, 14, "")
    f.label:SetJustifyH("LEFT")
    f.label:SetWordWrap(false)
    f.count = f:CreateFontString(nil, "OVERLAY")
    f.count:SetFont(addon.FONT, 12, "")
    -- Actions always reserve their space and only appear while the tab is hovered.
    f.updateActions = function()
      local hovered = f:IsMouseOver() and not addon.state.busy
      f.edit:SetShown(hovered and f.onEdit ~= nil)
      f.delete:SetShown(hovered and f.onDelete ~= nil)
    end
    local function action(texture, tooltip, offset, desaturate, callback)
      local icon = LWF:CreateIconButton(f, 16, texture)
      addon:UseWidgetTooltip(icon)
      icon:SetTooltip(tooltip)
      icon:SetPoint("RIGHT", f, "RIGHT", offset, 0)
      icon:SetTexture(texture, true, true, true)
      for _, region in ipairs({ icon:GetNormalTexture(), icon:GetPushedTexture(), icon:GetHighlightTexture(), icon:GetDisabledTexture() }) do
        region:SetDesaturated(desaturate)
      end
      icon:HookScript("OnEnter", f.updateActions)
      icon:HookScript("OnLeave", f.updateActions)
      icon:SetClickFunction(function() icon:HideTooltip(); callback() end)
      return icon
    end
    f.edit = action([[Interface\Buttons\UI-OptionsButton]], "Edit variation", -26, true, function() f.onEdit() end)
    f.delete = action([[Interface\Buttons\UI-GroupLoot-Pass-Up]], "Delete variation", -6, false, function() f.onDelete() end)
    f:SetScript("OnEnter", function(self) paintTab(self); self.updateActions(); addon.ShowWidgetTooltip(self, self.tooltip) end)
    f:SetScript("OnLeave", function(self) paintTab(self); self.updateActions(); addon.HideWidgetTooltip(self) end)
    f:SetScript("OnClick", function(self) self.onClick() end)
    return f
  end)
  tab.style, tab.active, tab.tooltip, tab.ghost = entry.style, active, entry.tooltip, entry.ghost
  tab.onClick, tab.onEdit, tab.onDelete = entry.onClick, entry.onEdit, entry.onDelete
  -- The cogwheel sits in the reserved slot beside delete, or at the edge when delete is unavailable.
  tab.edit:ClearAllPoints()
  tab.edit:SetPoint("RIGHT", tab, "RIGHT", entry.onDelete and -26 or -6, 0)
  tab.swatch:SetShown(entry.id ~= nil)
  tab.swatch:SetColorTexture(unpack(entry.style.border))
  tab.label:SetWidth(0)
  tab.label:SetText(entry.name)
  tab.count:SetText(entry.count and tostring(entry.count) or "")
  tab:SetEnabled(not addon.state.busy)
  paintTab(tab)
  tab.updateActions()
  return tab
end

-- "All", one tab per variation, then the entry point for creating variations.
local function variationTabs(pack, filter)
  local function open(id)
    ui.variationTabs[pack.id] = id
    ui.scroll:SetVerticalScroll(0)
    render()
  end
  local tabs = { { name = "All", count = #pack.profileOrder, style = allTabStyle, active = not filter, width = 120,
    tooltip = "Profiles from every variation", onClick = function() open(nil) end } }
  for _, id in ipairs(pack.variationOrder) do
    local v = pack.variations[id]
    local tooltip = v.name .. "\n" .. resolutionText(v)
    if v.description and v.description ~= "" then tooltip = tooltip .. "\n" .. v.description end
    table.insert(tabs, { id = id, name = v.name, count = #Packs.Profiles(pack, id), style = variationStyle(id),
      active = id == filter, tooltip = tooltip, onClick = function() open(id) end,
      onEdit = function() variationEditor(pack, id) end,
      onDelete = id ~= "default" and function() confirmVariationDelete(pack, id) end or nil })
  end
  table.insert(tabs, { name = "+ Add variation", style = allTabStyle, ghost = true, onClick = function() variationEditor(pack) end })
  -- Tabs keep their natural width and wrap onto extra lines, pushing the list down.
  local right, gap, x, y = ui.tabs:GetWidth() - 4, 4, 4, 0
  for _, entry in ipairs(tabs) do
    local tab = variationTab(ui.tabs, entry, entry.active)
    local lead, trail = entry.id and 26 or 12, entry.onDelete and 46 or entry.onEdit and 26 or 12
    local counter = entry.count and 6 + tab.count:GetStringWidth() or 0
    local width = entry.width or math.min(right - 4, lead + tab.label:GetStringWidth() + counter + trail)
    if x + width > right and x > 4 then x, y = 4, y + 30 + gap end
    tab:SetPoint("TOPLEFT", ui.tabs, "TOPLEFT", x, -y)
    tab:SetSize(width, 30)
    tab.label:SetPoint("LEFT", tab, "LEFT", lead, -1)
    tab.label:SetWidth(math.max(1, width - lead - counter - trail))
    tab.count:SetPoint("LEFT", tab.label, "RIGHT", 6, 0)
    x = x + width + gap
  end
  local top = 134 + y + 30 + 8
  if filter then
    local v = pack.variations[filter]
    local style = variationStyle(filter)
    local banner = widget(ui.tabs, "lockBanner", function()
      local f = CreateFrame("Frame", nil, ui.tabs, "BackdropTemplate")
      f:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8X8]], edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1 })
      f.icon = f:CreateTexture(nil, "OVERLAY")
      f.icon:SetTexture([[Interface\PetBattles\PetBattle-LockIcon]])
      f.icon:SetSize(16, 16)
      f.icon:SetPoint("LEFT", f, "LEFT", 10, 0)
      f.text = f:CreateFontString(nil, "OVERLAY")
      f.text:SetFont(addon.FONT, 13, "")
      f.text:SetJustifyH("LEFT")
      f.text:SetWordWrap(false)
      f.text:SetPoint("LEFT", f, "LEFT", 34, -1)
      return f
    end)
    banner:SetPoint("TOPLEFT", ui.tabs, "TOPLEFT", 4, -(top - 134 - 2))
    banner:SetSize(ui.tabs:GetWidth() - 8, 32)
    banner:SetFrameLevel(ui.tabs:GetFrameLevel())
    banner:SetBackdropColor(unpack(style.background))
    banner:SetBackdropBorderColor(unpack(style.border))
    banner.text:SetTextColor(unpack(style.text))
    banner.text:SetWidth(banner:GetWidth() - 170)
    banner.text:SetText("Viewing what " .. v.name .. " installs. Profiles and variations can only be changed in All.")
    button(ui.tabs, "Edit in All", banner:GetWidth() - 116, top - 134 + 2, 116, function() open(nil) end, nil, 24, 13)
    top = top + 32 + 6
  end
  ui.tabs:SetHeight(top - 134 - 8)
  ui.scroll:ClearAllPoints()
  ui.scroll:SetPoint("TOPLEFT", addon.frames.mainFrame, "TOPLEFT", 24, -top)
  ui.scroll:SetHeight(618 - top)
end

-- Rows without a variation are never installed; flag them until the creator assigns one.
-- Explains why a row is incomplete; an untouched main row is simply unused.
local function rowWarning(index, p, tags)
  if p and not next(tags) then return "No variation assigned.\nClick a variation to include this profile in it." end
  if not p and next(tags) then return "No profile selected.\nChoose a profile for the assigned variations." end
  if not p and index > 1 then return "Empty alternate profile.\nChoose a profile and a variation, or remove this row." end
end

local function emptyRow(parent, y, height)
  local shade = widget(parent, "emptyShade", function() return parent:CreateTexture(nil, "BACKGROUND", nil, 2) end)
  shade:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -y)
  shade:SetSize(parent:GetWidth() - 8, height)
  shade:SetColorTexture(0, 0, 0, .3)
end

local function unassignedRow(parent, y, height, tooltip)
  local tint = widget(parent, "unassignedTint", function() return parent:CreateTexture(nil, "BACKGROUND", nil, 2) end)
  tint:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -y)
  tint:SetSize(parent:GetWidth() - 8, height)
  tint:SetColorTexture(.95, .6, .1, .12)
  local stripe = widget(parent, "unassignedStripe", function() return parent:CreateTexture(nil, "BORDER") end)
  stripe:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -y)
  stripe:SetSize(3, height)
  stripe:SetColorTexture(.95, .62, .15, 1)
  local icon = widget(parent, "unassignedIcon", function()
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(22, 22)
    f:EnableMouse(true)
    f.texture = f:CreateTexture(nil, "OVERLAY")
    f.texture:SetAllPoints(f)
    f.texture:SetTexture([[Interface\DialogFrame\UI-Dialog-Icon-AlertNew]])
    f:SetScript("OnEnter", function(self) addon.ShowWidgetTooltip(self, self.tooltip) end)
    f:SetScript("OnLeave", function(self) addon.HideWidgetTooltip(self) end)
    return f
  end)
  icon:SetPoint("TOPLEFT", parent, "TOPLEFT", PROFILE_X - 26, -(y + 11))
  icon:SetFrameLevel(parent:GetFrameLevel() + 5)
  icon.tooltip = tooltip
end

local function creator(pack)
  local body = ui.content
  if not pack then
    label(body, "Want to share a UI Pack?", 0, 100, body:GetWidth(), 24):SetJustifyH("CENTER")
    label(body, "Build and share your setup through the Wago App.", 0, 142, body:GetWidth(), 14,
      { 0.65, 0.65, 0.65 }):SetJustifyH("CENTER")
    button(body, "Start Setup", (body:GetWidth() - 230) / 2, 194, 230, startSetup, nil, 44)
    body:SetHeight(300)
    return
  end
  ui.variationTabs = ui.variationTabs or {}
  local filter = ui.variationTabs[pack.id]
  if filter and not pack.variations[filter] then filter, ui.variationTabs[pack.id] = nil, nil end
  -- Variation tabs are a read-only view of what installs; every edit happens in "All".
  local locked = filter ~= nil
  variationTabs(pack, filter)

  local infos = addon:CreatorAddons()
  local saved = addon.db.creator.saved[pack.id]
  local y = 0
  local query = (ui.searchText or ""):lower()
  local function found(text) return text:lower():find(query, 1, true) end
  local function variationFound(tags)
    for id in pairs(tags) do
      if pack.variations[id] and found(pack.variations[id].name) then return true end
    end
  end
  local hasNotInstalled, listed, unassigned, profilesListed = false, false, {}, false
  -- Pack-wide extras are not tied to a variation, so previews leave them out.
  local extrasPending = not filter and found("Additional Addons")
  local function additionalRow()
    extrasPending = false
    listed = true
    local known, extras = wagoAddons(), {}
    for id, name in pairs(pack.additionalAddons) do
      table.insert(extras, { name = name, icon = known[id] and known[id].icon })
    end
    table.sort(extras, function(a, b) return a.name:lower() < b.name:lower() end)
    local groupStart = y
    local icon = addonRow(body, "Additional Addons", y, { .95, .95, .95 }, nil, nil, true)
    icon:SetEnabled(not addon.state.busy)
    icon:SetTooltip("Choose additional addons to include")
    icon:SetClickFunction(function() additionalAddons(pack) end)
    button(body, #extras > 0 and ("Manage (" .. #extras .. ")") or "Manage", PROFILE_X, y + 6, PROFILE_WIDTH,
      function() additionalAddons(pack) end, "Choose additional addons to include", 32)
    y = y + 44
    if #extras > 0 then
      -- Branch the included addons below Manage, like an alternate profile, wrapping as needed.
      local left = PROFILE_X + 16
      local x, lineY = left, y
      for _, item in ipairs(extras) do
        local name = label(body, item.name, 0, 0, 400, 14)
        local width = math.min(VARIATIONS_RIGHT - left - 26, name:GetStringWidth() + 2)
        if x + 26 + width > VARIATIONS_RIGHT and x > left then x, lineY = left, lineY + 26 end
        local texture = widget(body, "extraAddonIcon", function() return body:CreateTexture(nil, "ARTWORK") end)
        texture:SetPoint("TOPLEFT", body, "TOPLEFT", x, -(lineY + 12))
        texture:SetSize(20, 20)
        texture:SetTexture(tonumber(item.icon) or item.icon or 134400)
        texture:SetTexCoord(1 / 12, 11 / 12, 1 / 12, 11 / 12)
        name:SetPoint("TOPLEFT", body, "TOPLEFT", x + 26, -(lineY + 15))
        name:SetWidth(width)
        x = x + 26 + width + 18
      end
      profileConnector(body, PROFILE_X + 8, groupStart + 38, 1, y + 22 - groupStart - 38 + 1)
      profileConnector(body, PROFILE_X + 8, y + 22, 6, 1)
      y = lineY + 44
    end
    rowBackground(body, groupStart, y - groupStart - 1, .18)
  end
  for _, info in ipairs(infos) do
    -- Sits below the last loaded addon, ahead of disabled and missing ones.
    if extrasPending and info.group ~= 1 then additionalRow() end
    if info.status == "Not installed" then hasNotInstalled = true end
    local moduleName, ready = info.name, info.status == "Ready"
    local rows = creatorRows(pack, moduleName)
    local addonFound, shown = found(moduleName), {}
    for index, row in ipairs(rows) do
      local p = row.profileID and pack.profiles[row.profileID]
      local tags = p and p.variations or row.variations or {}
      if rowWarning(index, p, tags) then unassigned[moduleName] = true end
      if (not filter or tags[filter]) and (addonFound or p and found(p.name) or variationFound(tags)) then
        table.insert(shown, index)
      end
    end
    if #shown > 0 and (info.status ~= "Not installed" or ui.showNotInstalled or query ~= "") then
      listed, profilesListed = true, true
      local lap = LAP:GetModule(moduleName)
      local groupStart, lastBranch = y, nil
      for position, index in ipairs(shown) do
        local row = rows[index]
        row.moduleName = moduleName
        local p = row.profileID and pack.profiles[row.profileID]
        local tags = p and p.variations or row.variations or {}
        local function toggle(id)
          safely(function()
            local changed = CopyTable(tags)
            changed[id] = not tags[id] or nil
            if p then Packs.SetMembership(pack, p.id, changed) else row.variations = changed end
          end)
          render()
        end
        local chipX, chipY = VARIATIONS_X, y + 9
        for _, id in ipairs(pack.variationOrder) do
          -- A variation tab shows only what is assigned; "All" offers every toggle.
          if tags[id] or not filter then
            local chip, width = variationToggle(body, pack.variations[id].name, id, tags[id],
              not locked and function() toggle(id) end or nil, locked)
            if chipX + width > VARIATIONS_RIGHT and chipX > VARIATIONS_X then chipX, chipY = VARIATIONS_X, chipY + 30 end
            chip:SetPoint("TOPLEFT", body, "TOPLEFT", chipX, -chipY)
            chipX = chipX + width + 4
          end
        end
        local height = math.max(44, chipY - y + 35)
        local warning, rowHeight = rowWarning(index, p, tags), position == #shown and height - 1 or height
        if warning then unassignedRow(body, y, rowHeight, warning)
        elseif not p then emptyRow(body, y, rowHeight) end
        if position == 1 then
          local status = info.status ~= "Ready" and info.status or nil
          if info.status == "Addon disabled" then status = "AddOn disabled - click to enable" end
          addonRow(body, moduleName, y, lap:isLoaded() and { .95, .95, .95 } or { .5, .5, .5 }, status, nil, true)
          if info.status == "Addon disabled" or info.status == "Enabled after reload" or info.status == "Needs setup" then
            -- Keep the old row click action without rendering a styled status button.
            local hit = widget(body, "statusAction", function() return CreateFrame("Button", nil, body) end)
            hit:SetPoint("TOPLEFT", body, "TOPLEFT", 4, -y)
            hit:SetSize(PROFILE_X - 12, height)
            hit:SetEnabled(not addon.state.busy)
            hit:SetScript("OnClick", function()
              if info.status == "Addon disabled" then addon:EnableCreatorAddon(moduleName)
              elseif info.status == "Enabled after reload" then ReloadUI()
              else addon:EnsureIntegration(moduleName); render() end
            end)
          end
        else
          lastBranch = y + 22
          profileConnector(body, PROFILE_X + 8, lastBranch, 8, 1)
        end

        local function clear()
          if row.profileID then Packs.RemoveProfile(pack, row.profileID) end
          -- The main row keeps its variations so the next profile picked inherits them.
          if index == 1 then row.profileID, row.cleared = nil, true; row.variations = CopyTable(tags)
          else table.remove(rows, index) end
          render()
        end
        local current = ready and lap.getCurrentProfileKey and lap:getCurrentProfileKey()
        local entries = {}
        if p then entries[1] = { value = p.id, label = current == p.sourceKey and ("|cff009ECC" .. p.name .. "|r (active)") or p.name } end
        -- DF needs an initial option to open; enumerate profiles only when opened.
        entries[#entries + 1] = { value = "none", label = "Not selected", onclick = clear }
        local indent = position == 1 and 0 or 16
        local selector = dropdown(body, p and p.id or "none", entries, PROFILE_X + indent, y + 6, PROFILE_WIDTH - indent)
        selector.moduleName, selector.profileRow = moduleName, row
        local prior = p and p.data and saved and saved.profiles[p.id]
        if prior and (prior.sourceKey ~= p.sourceKey or prior.sourceCharacter ~= p.sourceCharacter) then prior = nil end
        local timestamp = prior and (prior.lastSavedAt or prior.lastUpdatedAt)
        local savedText = timestamp and ("Last save: " .. date("%b %d, %H:%M", timestamp)) or "Not saved yet"
        selector:SetTooltip(p and (position == 1 and savedText or (moduleName .. "\n" .. savedText)) or nil)
        addon:UseWidgetTooltip(selector)
        selector.OnMouseDownHook = function(_, _, options)
          for i = #options, 1, -1 do options[i] = nil end
          options[1] = { value = "none", label = "Not selected", font = addon.FONT, onclick = clear }
          local sources = addon:ProfileSources(moduleName)
          for sourceIndex, source in ipairs(sources) do
            options[#options + 1] = { value = sourceIndex, label = source.active and ("|cff009ECC" .. source.key .. "|r (active)") or source.label,
              font = addon.FONT, onclick = function()
              safely(function()
                if row.profileID then Packs.SetSource(pack, row.profileID, source)
                else
                  -- Chips picked beforehand win; otherwise an addon's first profile joins Default.
                  local tags = row.variations and next(row.variations) and row.variations or (index == 1 and { default = true } or {})
                  row.profileID = Packs.AddProfile(pack, moduleName, source.key, source.key,
                    tags, source.kind, source.character, source.classAndSpecTag)
                end
                addon.state.notice = nil
              end)
              render()
            end }
          end
        end
        if locked or not ready or addon.state.busy then selector:Disable() end
        if not locked then
          local add = rowAction(body, nil, 838, y, "Add alternate profile", function()
            -- New alternates start unassigned until a variation chip is chosen.
            table.insert(rows, { variations = {}, moduleName = moduleName })
            render()
          end)
          add:SetEnabled(ready and not addon.state.busy)
          local remove = rowAction(body, [[Interface\Buttons\UI-GroupLoot-Pass-Up]], 870, y,
            index == 1 and "Clear selected profile" or "Remove alternate profile", clear)
          local hover = widget(body, "profileHover", function()
            local frame = CreateFrame("Frame", nil, body)
            frame:EnableMouse(false)
            frame:SetScript("OnUpdate", function(self)
              -- Test row bounds so hovering its dropdown, chips or icons also counts.
              local shown = self.addonLoaded and not addon.state.busy and not ui.modal:IsShown()
                and ui.scroll:IsMouseOver() and self:IsMouseOver()
              for _, action in ipairs(self.actions) do action:SetShown(shown) end
            end)
            return frame
          end)
          hover:SetPoint("TOPLEFT", body, "TOPLEFT", 4, -y)
          hover:SetSize(body:GetWidth() - 8, height)
          hover.actions = { add, remove }
          hover.addonLoaded = lap:isLoaded()
          add:Hide(); remove:Hide()
        end
        y = y + height
      end
      -- One shared addon cell/background; branches connect its indented profiles.
      rowBackground(body, groupStart, y - groupStart - 1, ready and .18 or .06)
      if lastBranch then profileConnector(body, PROFILE_X + 8, groupStart + 38, 1, lastBranch - groupStart - 38 + 1) end
      if lap.exportOptions or moduleName == "WeakAuras" then
        local icon = body.pools.addonIcon[body.used.addonIcon]
        icon:SetTooltip("Left-click: addon settings\nRight-click: export options")
        icon:SetEnabled(ready and not addon.state.busy)
        icon:SetClickFunction(function() exportOptions(pack, moduleName) end, nil, nil, "RightButton")
      end
    end
  end
  if extrasPending then additionalRow() end
  local saveAll = button(ui.footer, "Save All Profiles", (ui.footer:GetWidth() - 300) / 2, -14, 300,
    function()
      if #pack.profileOrder == 0 and not next(pack.additionalAddons) and not addon.db.creator.saved[pack.id] then
        notice("No profiles to export!"); return
      end
      addon:CapturePack(pack, nil, saveCapture, function(current, total)
        if current == 0 then
          ui.captureProgress.fade = 0; ui.captureProgress:SetAlpha(1)
          ui.captureBar:SetMinMaxSmoothedValue(0, math.max(1, total))
        end
        ui.captureBar:SetSmoothedValue(current)
        ui.captureCounter:SetText(current .. "/" .. total)
        ui.captureText:SetText("Saving all profiles...")
        ui.captureProgress:Show()
        ui.capturePopup:Show()
      end)
    end, nil, 50, 20)
  local blocked = {}
  for _, p in ipairs(Packs.Profiles(pack)) do
    if not next(p.variations) then unassigned[p.moduleName] = true end
  end
  for moduleName in pairs(unassigned) do table.insert(blocked, moduleName) end
  table.sort(blocked)
  saveAll:SetEnabled(not addon.state.busy and #blocked == 0)
  -- Disabled buttons do not reliably report hover; explain the block from a frame above it.
  local blocker = widget(ui.footer, "saveBlocker", function()
    local f = CreateFrame("Frame", nil, ui.footer)
    f:EnableMouse(true)
    f:SetScript("OnEnter", function(self) addon.ShowWidgetTooltip(self, self.tooltip) end)
    f:SetScript("OnLeave", function(self) addon.HideWidgetTooltip(self) end)
    return f
  end)
  local saveFrame = saveAll.widget or saveAll.button or saveAll
  blocker:SetAllPoints(saveFrame)
  blocker:SetFrameLevel(saveFrame:GetFrameLevel() + 5)
  blocker.tooltip = "Fix the rows marked with a warning before saving.\nIncomplete: " .. table.concat(blocked, ", ")
  blocker:SetShown(#blocked > 0)
  if filter and query == "" and not profilesListed then
    label(body, "No profiles are assigned to " .. pack.variations[filter].name .. " yet.", 0, y + 40, body:GetWidth(), 16,
      { .65, .65, .65 }):SetJustifyH("CENTER")
    y = y + 90
  elseif not listed then
    label(body, "Nothing matches \"" .. ui.searchText .. "\"", 0, 40, body:GetWidth(), 16, { .65, .65, .65 }):SetJustifyH("CENTER")
    y = 100
  end
  if hasNotInstalled and query == "" then
    local row = widget(body, "missingAddonsRow", function()
      local f = CreateFrame("Button", nil, body)
      f.line = f:CreateTexture(nil, "BACKGROUND")
      f.line:SetPoint("CENTER")
      f.line:SetHeight(1)
      f.line:SetColorTexture(.25, .25, .25, 1)
      f.plate = CreateFrame("Frame", nil, f, "BackdropTemplate")
      f.plate:EnableMouse(false)
      f.plate:SetPoint("CENTER")
      f.plate:SetHeight(28)
      f.plate:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8x8]], edgeFile = [[Interface\Buttons\WHITE8x8]], edgeSize = 1 })
      f.plate:SetBackdropColor(.1, .1, .1, 1)
      f.plate:SetBackdropBorderColor(.25, .25, .25, 1)
      f.label = f.plate:CreateFontString(nil, "OVERLAY")
      f.label:SetFont(addon.FONT, 14, "")
      f.label:SetPoint("CENTER")
      f.label:SetTextColor(.85, .85, .85, 1)
      f:SetScript("OnEnter", function(self)
        self.plate:SetBackdropColor(.18, .18, .18, 1)
        self.plate:SetBackdropBorderColor(.45, .45, .45, 1)
        self.label:SetTextColor(1, 1, 1, 1)
      end)
      f:SetScript("OnLeave", function(self)
        self.plate:SetBackdropColor(.1, .1, .1, 1)
        self.plate:SetBackdropBorderColor(.25, .25, .25, 1)
        self.label:SetTextColor(.85, .85, .85, 1)
      end)
      return f
    end)
    row:SetPoint("TOPLEFT", body, "TOPLEFT", 4, -y)
    row:SetSize(body:GetWidth() - 8, 44)
    row.line:SetWidth(row:GetWidth())
    row.label:SetText(ui.showNotInstalled and "-  Hide AddOns that are not installed" or "+  Show AddOns that are not installed")
    row.plate:SetWidth(row.label:GetStringWidth() + 28)
    row:SetEnabled(not addon.state.busy)
    row:SetScript("OnClick", function()
      ui.showNotInstalled = not ui.showNotInstalled
      render()
    end)
    y = y + 44
  end
  body:SetHeight(math.max(1, y))
end

local function installResult(imported, failed)
  addon.dbC.selection.step = #failed == 0 and "done" or "profiles"
  notice(#failed > 0 and ("Not imported: " .. table.concat(failed, ", ")) or (imported .. " imported"))
end

local function install(pack)
  local body = ui.content
  if not pack then
    label(body, "No installed UI Packs found.", 0, 120, body:GetWidth(), 24):SetJustifyH("CENTER")
    label(body, "Install a UI Pack through the Wago App.", 0, 162, body:GetWidth(), 14,
      { 0.65, 0.65, 0.65 }):SetJustifyH("CENTER")
    body:SetHeight(300)
    return
  end
  local s = addon.dbC.selection
  s.variationID = pack.variations[s.variationID] and s.variationID or "default"
  local expert = s.expert
  local entries = {}
  for _, id in ipairs(pack.variationOrder) do
    table.insert(entries, { value = id, label = pack.variations[id].name, onclick = function() s.variationID = id; render() end })
  end
  dropdown(ui.header, s.variationID, entries, 380, 0, 220)
  button(ui.header, expert and "Wizard" or "Expert", 614, 0, 100, function() s.expert = not expert; render() end)
  button(ui.header, "Alt setup", 728, 0, 100, function()
    local f = modal("Alt setup")
    local characters, options, selected = addon:AltCharacters(), {}, addon.dbC.pendingAlt
    for _, character in ipairs(characters) do
      table.insert(options, { value = character, label = character, onclick = function() selected = character end })
    end
    dropdown(f, selected, options, 28, 80, 535, "Choose character…")
    button(f, "Apply", 424, 476, 150, function()
      if not selected then f.error:SetText("Choose a character."); return end
      closeModal()
      addon:ApplyAlt(selected, function(failed) notice(#failed > 0 and table.concat(failed, ", ") or "Profiles applied") end)
    end)
  end)
  local step = s.step or "variations"
  if not expert and step == "done" then
    label(body, "Done", 360, 120, 300, 30)
    if addon.state.needReload then button(body, "Reload UI", 330, 180, 230, ReloadUI, nil, 44) end
    button(ui.footer, "Back", 0, 0, 100, function() s.step = "profiles"; render() end)
    body:SetHeight(300)
    return
  end
  if not expert and step == "variations" then
    local y = 0
    for _, id in ipairs(pack.variationOrder) do
      local v = pack.variations[id]
      button(body, (id == s.variationID and "|TInterface\\Buttons\\UI-CheckBox-Check:20:20|t " or "") .. v.name,
        12, y + 8, 310, function() s.variationID = id; render() end, nil, 44)
      label(body, resolutionText(v), 350, y + 14, 500, 15)
      if v.description and v.description ~= "" then label(body, v.description, 350, y + 40, 500, 13) end
      y = y + 100
    end
    body:SetHeight(math.max(1, y))
    button(ui.footer, "Next", 664, 0, 120, function()
      local size = pack.variations[s.variationID].resolution
      local function nextStep() s.step = "profiles"; render() end
      local w, h = GetPhysicalScreenSize()
      if size and (size.width ~= w or size.height ~= h) then
        addon:ShowPrompt("Designed for " .. resolutionText(pack.variations[s.variationID]) .. ". Continue?", nextStep, nil, "Continue")
      else nextStep() end
    end)
    return
  end
  local choices = addon:InstallChoices(pack, s.variationID)
  local profiles = Packs.Profiles(pack, s.variationID)
  table.sort(profiles, function(a, b)
    if a.moduleName == b.moduleName then return a.name < b.name end
    return a.moduleName < b.moduleName
  end)
  local y, current = 0, nil
  for _, p in ipairs(profiles) do
    local status = addon:ProfileStatus(p)
    if current ~= p.moduleName then
      current = p.moduleName
      addonRow(body, current, y)
      if not expert and p.kind ~= "group" then
        local options, eligible = { { value = "skip", label = "Skip", onclick = function() choices[p.moduleName] = false; render() end } }, {}
        for _, other in ipairs(profiles) do
          local otherStatus = addon:ProfileStatus(other)
          if other.moduleName == p.moduleName and (otherStatus == "Ready" or otherStatus == "Enable addon") then
            table.insert(eligible, other)
            table.insert(options, { value = other.id, label = other.name, onclick = function() choices[p.moduleName] = other.id; render() end })
          end
        end
        local chosen = choices[p.moduleName]
        if chosen == nil and #eligible == 1 then chosen = eligible[1].id end
        dropdown(body, chosen == false and "skip" or chosen, options, 554, y + 10, 348, "Choose profile…")
      end
      y = y + 56
    end
    rowBackground(body, y, 38, 0.06)
    if not expert and p.kind == "group" then
      check(body, p.name, choices[p.id] ~= false, 18, y, function(value) choices[p.id] = value; render() end)
    else label(body, p.name, 28, y + 8, 500, 15) end
    local history = addon:GetProfileHistory(pack.id, p.id)
    local action = not history and "Import" or (history.lastUpdatedAt or 0) < (p.lastUpdatedAt or 0) and "Update" or "Re-import"
    label(body, status == "Ready" and (history and "Imported" or "") or status, 550, y + 8, 175, 13)
    if expert then
      local b = button(body, status == "Enable addon" and "Enable" or action, 740, y, 124, function()
        addon:ImportProfiles(pack, { p }, function(count, failed)
          notice(#failed > 0 and table.concat(failed, ", ") or "Imported")
        end)
      end)
      b:SetEnabled(not addon.state.busy and (status == "Ready" or status == "Enable addon"))
    end
    y = y + 40
  end
  if #profiles == 0 then label(body, "No profiles", 24, 28, 600, 18) end
  body:SetHeight(math.max(1, y))
  if not expert then
    button(ui.footer, "Back", 0, 0, 100, function() s.step = "variations"; render() end)
    local plan, problem = addon:BuildInstallPlan(pack, s.variationID)
    label(ui.footer, problem or "", 120, 8, 520, 14)
    local b = button(ui.footer, "Install", 664, 0, 120, function() addon:ImportProfiles(pack, plan, installResult) end)
    b:SetEnabled(not addon.state.busy and plan and #plan > 0)
  end
end

render = function()
  if not ui.header then return end
  reset(ui.header); reset(ui.content); reset(ui.footer); reset(ui.tabs)
  ui.notice:SetText(addon.state.busy and "Working…" or addon.state.packError or addon.state.notice or "")
  local creating = addon.db.workspaceMode == "create"
  local switch = button(ui.footer, creating and "UI packs" or "Creator tools", 808, 0, 144, function()
    addon.db.workspaceMode = creating and "install" or "create"
    ui.scroll:SetVerticalScroll(0)
    render()
  end, nil, 26)
  switch:SetBackdropColor(0.12, 0.12, 0.12, 0.8)
  local selected = creating and addon.db.creator.selected or addon.dbC.selection.packID
  local entries, available = {}, addon:GetPacks(creating)
  for id, pack in pairs(available) do
    local entry = { value = id, label = tostring(type(pack) == "table" and (pack.name or pack.localName or id) or id), onclick = function()
      ui.scroll:SetVerticalScroll(0)
      if creating then addon.db.creator.selected = id; render()
      else addon:SetActivePack(id) end
    end }
    if creating then
      entry.rename = function()
        textDialog("Rename UI pack", pack.name, "Save", function(value) Packs.Rename(pack, value) end)
      end
      entry.delete = function()
        addon:ShowPrompt("Delete " .. pack.name .. " and its local captures?", function()
          addon.db.creator.packs[id], addon.db.creator.saved[id] = nil, nil
          if addon.db.creator.profileRows then addon.db.creator.profileRows[id] = nil end
          if addon.db.creator.selected == id then addon.db.creator.selected = nil end
          render()
        end, nil, "Delete")
      end
    end
    table.insert(entries, entry)
  end
  table.sort(entries, function(a, b) return a.label < b.label end)
  if not selected or not available[selected] then
    selected = entries[1] and entries[1].value
    if creating then addon.db.creator.selected = selected else addon.dbC.selection.packID = selected end
  end
  if #entries > 0 then
    if creating then table.insert(entries, { label = "+ Add UI Pack", action = true, onclick = startSetup }) end
    label(ui.header, "UI Pack", 0, 9, 64, 14, { .65, .65, .65 })
    dropdown(ui.header, selected, entries, 68, 0, 300, "UI pack")
  end
  local tableVisible = creating and selected ~= nil
  local searching = ui.searchText ~= nil and ui.searchText ~= ""
  ui.search:SetShown(tableVisible)
  ui.tabs:SetShown(tableVisible)
  ui.scroll:ClearAllPoints()
  ui.scroll:SetPoint("TOPLEFT", addon.frames.mainFrame, "TOPLEFT", 24, tableVisible and -172 or -130)
  ui.scroll:SetHeight(tableVisible and 446 or 488)
  ui.searchHint:SetShown(tableVisible and not searching)
  ui.searchClear:SetShown(tableVisible and searching)
  if creating then
    local pack = selected and available[selected]
    creator(pack)
  else
    local pack = addon:CurrentInstallPack()
    if selected and not pack then
      local _, problem = Packs.Validate(available[selected])
      addon.state.packError = problem or "Pack ID does not match its storage key."
      ui.notice:SetText(addon.state.packError)
    end
    install(pack)
  end
  ui.lock:SetShown(addon.state.busy or false)
  if not addon.state.busy then ui.capturePopup:Hide() end
end

function addon:RefreshWorkspace()
  render()
end

function addon:CreateWorkspace(frame)
  self.db.workspaceMode = self.db.workspaceMode == "create" and "create" or "install"
  ui.header = CreateFrame("Frame", nil, frame)
  ui.header:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -48)
  ui.header:SetSize(952, 40)
  ui.scroll, ui.content = scroll(frame, 24, 130, 918, 488)
  ui.tabs = CreateFrame("Frame", nil, frame)
  ui.tabs:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -134)
  ui.tabs:SetSize(918, 30)
  ui.footer = CreateFrame("Frame", nil, frame)
  ui.footer:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -648)
  ui.footer:SetSize(952, 36)
  ui.notice = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ui.notice:SetFont(addon.FONT, 14, "")
  ui.notice:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 26, 60)
  ui.notice:SetWidth(910)
  ui.notice:SetJustifyH("LEFT")
  local function search(text)
    ui.searchText = text
    ui.scroll:SetVerticalScroll(0)
    render()
  end
  ui.search = input(frame, "", 28, 90, 826, search)
  ui.search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  ui.search:SetMaxLetters(120)
  ui.search:SetTextInsets(32, 32, 0, 0)
  ui.searchIcon = ui.search:CreateTexture(nil, "OVERLAY")
  ui.searchIcon:SetTexture([[Interface\Common\UI-Searchbox-Icon]])
  ui.searchIcon:SetSize(14, 14)
  ui.searchIcon:SetPoint("LEFT", ui.search, "LEFT", 11, -1)
  ui.searchHint = ui.search:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  ui.searchHint:SetFont(addon.FONT, 14, "")
  ui.searchHint:SetTextColor(0.65, 0.65, 0.65, 1)
  ui.searchHint:SetPoint("LEFT", ui.search, "LEFT", 32, 0)
  ui.searchHint:SetText("Search AddOns, profiles or variations…")
  ui.searchClear = CreateFrame("Button", nil, ui.search)
  ui.searchClear:SetSize(26, 26)
  ui.searchClear:SetPoint("RIGHT", ui.search, "RIGHT", -4, 0)
  ui.searchClear.cross = ui.searchClear:CreateFontString(nil, "OVERLAY")
  ui.searchClear.cross:SetFont(addon.FONT, 20, "")
  ui.searchClear.cross:SetPoint("CENTER", ui.searchClear, "CENTER", 0, -1)
  ui.searchClear.cross:SetTextColor(.65, .65, .65, 1)
  ui.searchClear.cross:SetText("×")
  ui.searchClear:SetScript("OnEnter", function(self) self.cross:SetTextColor(1, 1, 1, 1) end)
  ui.searchClear:SetScript("OnLeave", function(self) self.cross:SetTextColor(.65, .65, .65, 1) end)
  ui.searchClear:SetScript("OnClick", function()
    ui.search:SetText("")
    ui.search:ClearFocus()
    search("")
  end)
  ui.lock = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  ui.lock:SetAllPoints(frame)
  ui.lock:SetFrameLevel(frame:GetFrameLevel() + 70)
  ui.lock:EnableMouse(true)
  ui.lock:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
  ui.lock:SetBackdropColor(0, 0, 0, 0.3)
  ui.lock:Hide()
  ui.capturePopup = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  ui.capturePopup:SetSize(300, 100)
  ui.capturePopup:SetPoint("CENTER", frame, "CENTER", 0, 50)
  ui.capturePopup:SetFrameStrata("TOOLTIP")
  ui.capturePopup:SetFrameLevel(200)
  ui.capturePopup:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8x8]] })
  ui.capturePopup:SetBackdropColor(.2, .2, .2, 1)
  ui.captureText = ui.capturePopup:CreateFontString(nil, "OVERLAY")
  ui.captureText:SetPoint("CENTER", ui.capturePopup, "CENTER")
  ui.captureText:SetFont(addon.FONT, 20, "")
  ui.captureText:SetTextColor(1, 1, 0)
  ui.captureText:SetJustifyH("CENTER")
  ui.capturePopup:Hide()
  ui.captureProgress = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  ui.captureProgress:SetFrameStrata("TOOLTIP")
  ui.captureProgress:SetFrameLevel(201)
  ui.captureProgress:SetSize(280, 20)
  ui.captureProgress:SetPoint("BOTTOM", ui.capturePopup, "BOTTOM", 0, 6)
  ui.captureProgress:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8x8]] })
  ui.captureProgress:SetBackdropColor(.4, .4, .4, 1)
  DF:CreateBorder(ui.captureProgress, 1, 0, 0)
  ui.captureBar = CreateFrame("StatusBar", nil, ui.captureProgress)
  ui.captureBar:SetAllPoints(ui.captureProgress)
  ui.captureBar:SetStatusBarTexture([[Interface\Buttons\WHITE8x8]])
  ui.captureBar:SetStatusBarColor(201 / 255, 180 / 255, 0)
  Mixin(ui.captureBar, SmoothStatusBarMixin)
  ui.captureBar:SetMinMaxSmoothedValue(0, 0)
  ui.captureCounter = ui.captureBar:CreateFontString(nil, "OVERLAY")
  ui.captureCounter:SetPoint("CENTER", ui.captureProgress, "CENTER")
  ui.captureCounter:SetHeight(20)
  ui.captureCounter:SetJustifyH("CENTER")
  ui.captureCounter:SetFont(addon.FONT, 14, "OUTLINE")
  ui.captureCounter:SetTextColor(1, 1, 1)
  ui.captureProgress:SetScript("OnUpdate", function(self, elapsed)
    if addon.state.busy then self.fade = 0; self:SetAlpha(1); return end
    self.fade = (self.fade or 0) + elapsed
    self:SetAlpha(math.max(0, 1 - self.fade))
    if self.fade >= 1 then self:Hide() end
  end)
  ui.captureProgress:Hide()
  ui.modalShade = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  ui.modalShade:SetAllPoints(frame)
  ui.modalShade:SetFrameLevel(frame:GetFrameLevel() + 79)
  ui.modalShade:EnableMouse(true)
  ui.modalShade:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
  ui.modalShade:SetBackdropColor(0, 0, 0, 0.65)
  ui.modalShade:Hide()
  ui.modal = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  ui.modal:SetSize(600, 524)
  ui.modal:SetPoint("CENTER")
  ui.modal:SetFrameLevel(frame:GetFrameLevel() + 80)
  ui.modal:EnableMouse(true)
  DF:ApplyStandardBackdrop(ui.modal)
  ui.modal:SetBackdropColor(0.08, 0.08, 0.08, 1)
  ui.modal.scroll, ui.modal.content = scroll(ui.modal, 24, 78, 526, 350)
  ui.modal:Hide()
  frame:HookScript("OnShow", render)
  render()
end
