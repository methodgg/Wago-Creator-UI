local addon = select(2, ...)
local DF = DetailsFramework
local LWF = LibStub("LibWagoFramework")
local LAP = LibStub("LibAddonProfiles")
local Packs = addon.Packs
local ui = {}
local render, profileEditor

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
    compact and 325 or 476, compact and 16 or 18, color)
  if status then
    label(parent, status, compact and 56 or 62, y + (compact and 27 or 31), compact and 325 or 560,
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

local function variationChip(parent, name, id, x, y, width, onClick, onRemove, fontSize)
  local chip = button(parent, name, x, y, width or 132, onClick, nil, 26, fontSize, "variationChip")
  chip.variationID = id
  local frame = chip.widget or chip.button or chip
  chip.text_overlay:SetText(name)
  width = width or math.min(132, math.max(64, chip.text_overlay:GetStringWidth() + 40))
  chip:SetWidth(width)
  chip:SetTextTruncated(name, width - 40)
  chip.text_overlay:SetWidth(width - 40)
  chip.text_overlay:ClearAllPoints()
  chip.text_overlay:SetPoint("CENTER", frame, "CENTER", -12, -2)
  if not chip.removeButton then
    local remove = CreateFrame("Button", nil, frame)
    chip.removeButton = remove
    remove:SetSize(24, 24)
    remove:SetPoint("RIGHT", frame, "RIGHT", -1, 0)
    remove:SetHighlightTexture([[Interface\Buttons\WHITE8X8]])
    remove:GetHighlightTexture():SetColorTexture(1, 1, 1, .12)
    local cross = remove:CreateFontString(nil, "OVERLAY")
    cross:SetFont(addon.FONT, 20, "")
    cross:SetPoint("CENTER", remove, "CENTER", 0, -1)
    cross:SetText("×")
    remove.cross = cross
    -- Native hooks run after the framework's pressed/released text offsets.
    local function alignText()
      chip.text_overlay:ClearAllPoints()
      chip.text_overlay:SetPoint("CENTER", frame, "CENTER", -12, -2)
    end
    frame:HookScript("OnMouseDown", alignText)
    frame:HookScript("OnMouseUp", alignText)
  end
  local remove, style = chip.removeButton, variationStyle(id)
  remove:SetScript("OnClick", function() onRemove() end)
  remove:SetEnabled(not addon.state.busy)
  remove.cross:SetTextColor(unpack(style.text))
  remove:Hide()
  chip:SetBackdropColor(unpack(style.background))
  chip:SetBackdropBorderColor(unpack(style.border))
  chip.text_overlay:SetTextColor(unpack(style.text))
  chip:SetScript("OnEnter", nil)
  chip:SetScript("OnLeave", nil)
  chip:SetScript("OnUpdate", function()
    local scroller = parent == ui.content and ui.scroll or ui.modal.scroll
    local hovered = scroller:IsMouseOver() and (chip:IsMouseOver() or remove:IsShown() and remove:IsMouseOver())
      and not addon.state.busy and (parent ~= ui.content or not ui.modal:IsShown())
    remove:SetShown(onRemove ~= nil and hovered)
    chip:SetBackdropColor(unpack(hovered and style.hover or style.background))
  end)
  return chip, width
end

profileEditor = function(pack, row, after, selectedID)
  local p = row.profileID and pack.profiles[row.profileID]
  local draft = CopyTable(pack)
  local tags = CopyTable(p and p.variations or row.variations or {})
  for id in pairs(tags) do if not draft.variations[id] then tags[id] = nil end end
  local selected = selectedID or "default"
  local edits, created, pendingDelete = {}, {}, nil
  local title, width, height, description, any, includeDefault
  local show
  local function readFields()
    if not title then return end
    edits[selected] = { name = title:GetText(), width = width:GetText(), height = height:GetText(),
      description = description:GetText(), any = any, includeDefault = includeDefault }
  end
  local function fields(id)
    if edits[id] then return edits[id] end
    local v = draft.variations[id]
    return { name = v.name, description = v.description or "", any = not v.resolution,
      width = v.resolution and tostring(v.resolution.width) or "",
      height = v.resolution and tostring(v.resolution.height) or "" }
  end
  local function save()
    safely(function()
      readFields()
      assert(p or next(tags), "Choose at least one variation.")
      local captured = CopyTable(draft)
      for _, id in ipairs(captured.variationOrder) do
        local values = fields(id)
        captured.variations[id] = { name = values.name:match("^%s*(.-)%s*$"), description = values.description,
          resolution = not values.any and { width = tonumber(values.width), height = tonumber(values.height) } or nil }
        if created[id] and values.includeDefault then
          for _, profile in pairs(captured.profiles) do
            if profile.variations.default then profile.variations[id] = true end
          end
        end
      end
      if p then Packs.SetMembership(captured, p.id, tags) end
      local valid, problem = Packs.Validate(captured)
      assert(valid, problem)
      pack.variations, pack.variationOrder, pack.nextID = captured.variations, captured.variationOrder, captured.nextID
      pack.revision = pack.revision + 1
      for id, profile in pairs(pack.profiles) do profile.variations = captured.profiles[id].variations end
      for _, rows in pairs(addon.db.creator.profileRows and addon.db.creator.profileRows[pack.id] or {}) do
        for _, otherRow in ipairs(rows) do
          for id in pairs(otherRow.variations or {}) do if not pack.variations[id] then otherRow.variations[id] = nil end end
        end
      end
      if not p then row.variations = CopyTable(tags) end
      if after then after() end
      closeModal(); render()
    end)
  end
  show = function(focusName)
    title = nil
    local f = modal("Profile Variations", 680, 420)
    f.scroll:ClearAllPoints()
    f.scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -82)
    f.scroll:SetWidth(254); f.content:SetWidth(254)
    local content = modalList(f, 250)
    for index, id in ipairs(draft.variationOrder) do
      local values, y = fields(id), (index - 1) * 52
      if selected == id then rowBackground(content, y, 51, .1) end
      check(content, "", tags[id], 4, y + 8, function(value) readFields(); tags[id] = value or nil; show() end)
      variationChip(content, values.name, id, 36, y + 9, 210, function()
        readFields(); selected, pendingDelete = id, nil; show()
      end, tags[id] and function() readFields(); tags[id] = nil; show() end or nil, 16)
      label(content, values.any and "Any resolution" or (values.width .. " × " .. values.height),
        36, y + 37, 210, 12, { .6, .6, .6 })
    end
    button(content, "+ Add variation", 36, #draft.variationOrder * 52 + 9, 210, function()
      readFields()
      local name, suffix = "New variation", 1
      local function exists(value)
        for _, id in ipairs(draft.variationOrder) do
          if fields(id).name:lower() == value:lower() or draft.variations[id].name:lower() == value:lower() then return true end
        end
      end
      while exists(name) do suffix = suffix + 1; name = "New variation " .. suffix end
      selected = Packs.SaveVariation(draft, nil, name, nil, "")
      created[selected], tags[selected], pendingDelete = true, true, nil
      show(true)
    end, nil, 26, 16)
    content:SetHeight((#draft.variationOrder + 1) * 52)
    local divider = widget(f, "variationDivider", function() return f:CreateTexture(nil, "ARTWORK") end)
    divider:SetColorTexture(.25, .25, .25, 1)
    divider:SetSize(1, 250); divider:SetPoint("TOPLEFT", f, "TOPLEFT", 308, -82)
    if pendingDelete then
      label(f, "Delete " .. fields(selected).name .. "?", 328, 88, 328, 20)
      local warning = label(f, #Packs.Profiles(draft, selected) .. " profiles use this variation.\nTheir profiles will be kept.",
        328, 130, 328, 14, { .7, .7, .7 })
      warning:SetWordWrap(true)
      button(f, "Keep variation", 328, 206, 152, function() pendingDelete = nil; show() end)
      button(f, "Delete", 496, 206, 160, function()
        Packs.RemoveVariation(draft, selected)
        tags[selected], edits[selected], created[selected] = nil, nil, nil
        selected, pendingDelete = "default", nil
        show()
      end)
    else
      local values = fields(selected)
      label(f, "Name", 328, 84, 260, 14)
      title = input(f, values.name, 328, 110, selected == "default" and 328 or 286)
      title:SetMaxLetters(120)
      if selected ~= "default" then
        local delete = widget(f, "variationDelete", function() return LWF:CreateIconButton(f, 28, [[Interface\Buttons\UI-GroupLoot-Pass-Up]]) end)
        delete:SetPoint("TOPLEFT", f, "TOPLEFT", 628, -113)
        delete:SetBackdrop(nil); delete.disabled_overlay:SetTexture(nil)
        delete:SetTooltip("Delete variation"); addon:UseWidgetTooltip(delete)
        delete:SetClickFunction(function() readFields(); pendingDelete = selected; show() end)
      end
      any, includeDefault = values.any, values.includeDefault
      width = input(f, values.width, 328, 202, 120)
      local separator = label(f, "×", 466, 209, 20, 14)
      height = input(f, values.height, 496, 202, 120)
      check(f, "Any resolution", any, 328, 164, function(value)
        any = value; width:SetShown(not value); height:SetShown(not value); separator:SetShown(not value)
      end)
      width:SetShown(not any); height:SetShown(not any); separator:SetShown(not any)
      label(f, "Description (optional)", 328, 252, 328, 14)
      description = input(f, values.description, 328, 276, 328)
      description:SetMaxLetters(2000)
      if created[selected] then
        check(f, "Include Default profiles", includeDefault, 328, 316, function(value) includeDefault = value end)
      end
      if focusName then title:SetFocus(); title:HighlightText() end
    end
    button(f, "Cancel", 440, 364, 96, closeModal)
    button(f, "Save", 552, 364, 104, save):SetEnabled(not pendingDelete and not addon.state.busy)
  end
  show()
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

local function additionalAddons(pack)
  local f = modal("Additional addons")
  local content = modalList(f)
  local selected, entries = CopyTable(pack.additionalAddons), {}
  for index = 1, C_AddOns.GetNumAddOns() do
    local id = C_AddOns.GetAddOnMetadata(index, "X-Wago-ID")
    local name = C_AddOns.GetAddOnInfo(index)
    if id and name ~= "WagoUI" and name ~= "WagoUI_Creator" then entries[id] = name end
  end
  for id, name in pairs(selected) do entries[id] = name end
  local ordered = {}
  for id, name in pairs(entries) do table.insert(ordered, { id = id, name = name }) end
  table.sort(ordered, function(a, b) return a.name < b.name end)
  for index, item in ipairs(ordered) do
    check(content, item.name, selected[item.id], 0, (index - 1) * 34, function(value) selected[item.id] = value and item.name or nil end)
  end
  content:SetHeight(math.max(1, #ordered * 34))
  button(f, "Save", 424, 476, 150, function()
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
  stored[pack.id] = stored[pack.id] or {}
  local rows = stored[pack.id][moduleName] or { { variations = { default = true } } }
  stored[pack.id][moduleName] = rows
  local seen = {}
  for index = #rows, 1, -1 do
    local row = rows[index]
    if row.profileID and not pack.profiles[row.profileID] then
      if index == 1 then row.profileID = nil else table.remove(rows, index) end
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
  button(ui.footer, "Save All Profiles", (ui.footer:GetWidth() - 300) / 2, -14, 300,
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
  label(ui.columns, "Options", 4, 3, 48, 13, { .65, .65, .65 })
  label(ui.columns, "AddOn", 56, 3, 325, 13, { .65, .65, .65 })
  label(ui.columns, "Profile", 389, 3, 210, 13, { .65, .65, .65 })
  label(ui.columns, "Variations", 613, 3, 213, 13, { .65, .65, .65 })

  local infos = addon:CreatorAddons()
  local saved = addon.db.creator.saved[pack.id]
  local y = 0
  local query = (ui.searchText or ""):lower()
  local hasNotInstalled = false
  if ("additional addons"):find(query, 1, true) then
    local count = 0
    for _ in pairs(pack.additionalAddons) do count = count + 1 end
    rowBackground(body, y, 43, .18)
    local icon = addonRow(body, "Additional Addons", y, { .95, .95, .95 }, nil, nil, true)
    icon:SetEnabled(not addon.state.busy)
    icon:SetTooltip("Choose additional addons to include")
    icon:SetClickFunction(function() additionalAddons(pack) end)
    button(body, count > 0 and ("Manage (" .. count .. ")") or "Manage", 389, y + 6, 210,
      function() additionalAddons(pack) end, "Choose additional addons to include", 32)
    y = y + 44
  end
  for _, info in ipairs(infos) do
    if info.status == "Not installed" then hasNotInstalled = true end
    local moduleName, ready = info.name, info.status == "Ready"
    local rows = creatorRows(pack, moduleName)
    local matches = moduleName:lower():find(query, 1, true)
    for _, row in ipairs(rows) do
      local p = row.profileID and pack.profiles[row.profileID]
      matches = matches or p and p.name:lower():find(query, 1, true)
    end
    if matches and (info.status ~= "Not installed" or ui.showNotInstalled or query ~= "") then
      local lap = LAP:GetModule(moduleName)
      local groupStart, lastBranch = y, nil
      for index, row in ipairs(rows) do
        row.moduleName = moduleName
        local p = row.profileID and pack.profiles[row.profileID]
        local tags = p and p.variations or row.variations or {}
        local chipX, chipY = 613, y + 9
        for _, id in ipairs(pack.variationOrder) do
          if tags[id] then
            local chip, width = variationChip(body, pack.variations[id].name, id, chipX, chipY, nil,
              function() profileEditor(pack, row, nil, id) end, function()
                safely(function()
                  local remaining = CopyTable(tags)
                  remaining[id] = nil
                  if p then Packs.SetMembership(pack, p.id, remaining) else row.variations = remaining end
                  render()
                end)
              end, 13)
            local edge = chipY == y + 9 and 774 or 826
            if chipX + width > edge then chipX, chipY = 613, chipY + 30 end
            chip:ClearAllPoints(); chip:SetPoint("TOPLEFT", body, "TOPLEFT", chipX, -chipY)
            chipX = chipX + width + 4
          end
        end
        local height = math.max(44, chipY - y + 35)
        local addVariation = button(body, "Add", 778, y + 9, 48,
          function() profileEditor(pack, row) end, nil, 26, 13, "variationAdd")
        addVariation:Hide()
        local variationHover = widget(body, "variationHover", function()
          local cell = CreateFrame("Frame", nil, body)
          cell:EnableMouse(false)
          cell:SetScript("OnUpdate", function(self)
            local hovered = self:IsMouseOver() or self.action:IsShown() and self.action:IsMouseOver()
            self.action:SetShown(hovered and ui.scroll:IsMouseOver() and not addon.state.busy and not ui.modal:IsShown())
          end)
          return cell
        end)
        variationHover:SetPoint("TOPLEFT", body, "TOPLEFT", 613, -y)
        variationHover:SetSize(213, height)
        variationHover.action = addVariation
        if index == 1 then
          local status = info.status ~= "Ready" and info.status or nil
          if info.status == "Addon disabled" then status = "AddOn disabled - click to enable" end
          addonRow(body, moduleName, y, lap:isLoaded() and { .95, .95, .95 } or { .5, .5, .5 }, status, nil, true)
          if info.status == "Addon disabled" or info.status == "Enabled after reload" or info.status == "Needs setup" then
            -- Keep the old row click action without rendering a styled status button.
            local hit = widget(body, "statusAction", function() return CreateFrame("Button", nil, body) end)
            hit:SetPoint("TOPLEFT", body, "TOPLEFT", 4, -y)
            hit:SetSize(377, height)
            hit:SetEnabled(not addon.state.busy)
            hit:SetScript("OnClick", function()
              if info.status == "Addon disabled" then addon:EnableCreatorAddon(moduleName)
              elseif info.status == "Enabled after reload" then ReloadUI()
              else addon:EnsureIntegration(moduleName); render() end
            end)
          end
        else
          lastBranch = y + 22
          profileConnector(body, 397, lastBranch, 8, 1)
        end

        local function clear()
          if row.profileID then Packs.RemoveProfile(pack, row.profileID) end
          if index == 1 then row.profileID, row.cleared = nil, true; row.variations = { default = true }
          else table.remove(rows, index) end
          render()
        end
        local current = ready and lap.getCurrentProfileKey and lap:getCurrentProfileKey()
        local entries = {}
        if p then entries[1] = { value = p.id, label = current == p.sourceKey and ("|cff009ECC" .. p.name .. "|r (active)") or p.name } end
        -- DF needs an initial option to open; enumerate profiles only when opened.
        entries[#entries + 1] = { value = "none", label = "Not selected", onclick = clear }
        local indent = index == 1 and 0 or 16
        local selector = dropdown(body, p and p.id or "none", entries, 389 + indent, y + 6, 210 - indent)
        selector.moduleName, selector.profileRow = moduleName, row
        local prior = p and p.data and saved and saved.profiles[p.id]
        if prior and (prior.sourceKey ~= p.sourceKey or prior.sourceCharacter ~= p.sourceCharacter) then prior = nil end
        local timestamp = prior and (prior.lastSavedAt or prior.lastUpdatedAt)
        local savedText = timestamp and ("Last save: " .. date("%b %d, %H:%M", timestamp)) or "Not saved yet"
        selector:SetTooltip(p and (index == 1 and savedText or (moduleName .. "\n" .. savedText)) or nil)
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
                else row.profileID = Packs.AddProfile(pack, moduleName, source.key, source.key,
                  row.variations or { default = true }, source.kind, source.character, source.classAndSpecTag) end
                addon.state.notice = nil
              end)
              render()
            end }
          end
        end
        if not ready or addon.state.busy then selector:Disable() end
        local add = rowAction(body, nil, 838, y, "Add alternate profile", function()
          local draft = { variations = {}, moduleName = moduleName }
          profileEditor(pack, draft, function() table.insert(rows, draft) end)
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
        y = y + height
      end
      -- One shared addon cell/background; branches connect its indented profiles.
      rowBackground(body, groupStart, y - groupStart - 1, ready and .18 or .06)
      if lastBranch then profileConnector(body, 397, groupStart + 38, 1, lastBranch - groupStart - 38 + 1) end
      if lap.exportOptions or moduleName == "WeakAuras" then
        local icon = body.pools.addonIcon[body.used.addonIcon]
        icon:SetTooltip("Left-click: addon settings\nRight-click: export options")
        icon:SetEnabled(ready and not addon.state.busy)
        icon:SetClickFunction(function() exportOptions(pack, moduleName) end, nil, nil, "RightButton")
      end
    end
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
  reset(ui.header); reset(ui.content); reset(ui.footer); reset(ui.columns)
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
    dropdown(ui.header, selected, entries, 0, 0, 320, "UI pack")
  end
  ui.search:SetShown(creating and selected ~= nil)
  local tableVisible = creating and selected ~= nil
  ui.columns:SetShown(tableVisible)
  ui.scroll:ClearAllPoints()
  ui.scroll:SetPoint("TOPLEFT", addon.frames.mainFrame, "TOPLEFT", 24, tableVisible and -158 or -130)
  ui.scroll:SetHeight(tableVisible and 460 or 488)
  ui.searchHint:SetShown(creating and selected ~= nil and (not ui.searchText or ui.searchText == ""))
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
  ui.columns = CreateFrame("Frame", nil, frame)
  ui.columns:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -130)
  ui.columns:SetSize(918, 24)
  ui.footer = CreateFrame("Frame", nil, frame)
  ui.footer:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -648)
  ui.footer:SetSize(952, 36)
  ui.notice = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ui.notice:SetFont(addon.FONT, 14, "")
  ui.notice:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 26, 60)
  ui.notice:SetWidth(910)
  ui.notice:SetJustifyH("LEFT")
  ui.search = input(frame, "", 28, 92, 510, function(text)
    ui.searchText = text
    ui.scroll:SetVerticalScroll(0)
    render()
  end)
  ui.search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  ui.search:SetMaxLetters(120)
  ui.searchHint = ui.search:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  ui.searchHint:SetFont(addon.FONT, 14, "")
  ui.searchHint:SetTextColor(0.65, 0.65, 0.65, 1)
  ui.searchHint:SetPoint("LEFT", ui.search, "LEFT", 8, 0)
  ui.searchHint:SetText("Search")
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
  ui.modal:HookScript("OnHide", function() ui.modal.scroll:ClearAllPoints(); ui.modal.scroll:SetPoint("TOPLEFT", ui.modal, "TOPLEFT", 24, -78) end)
  frame:HookScript("OnShow", render)
  render()
end
