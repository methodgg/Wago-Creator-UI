-- Variation colors, chips, tabs and the variation editor.
local addon = select(2, ...)
local LWF = LibStub("LibWagoFramework")
local Packs = addon.Packs
local UI = addon.UI
local ui = UI.view
local button, dropdown, input, label, widget = UI.button, UI.dropdown, UI.input, UI.label, UI.widget
local closeModal, dangerButton, modal, safely = UI.closeModal, UI.dangerButton, UI.modal, UI.safely
local function render() UI.render() end

local function resolutionText(variation)
  local parts = {}
  for _, size in ipairs(variation.resolutions or {}) do parts[#parts + 1] = size.width .. " × " .. size.height end
  return #parts > 0 and table.concat(parts, ", ") or "Any resolution"
end

-- Radix dark scales: background 3, border 7, high-contrast text 12.
-- https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale
local variationStyles = {
  { background = 0x0d2847, border = 0x205d9e, text = 0xc2e6ff }, -- blue
  { background = 0x0d2d2a, border = 0x1c6961, text = 0xadf0dd }, -- teal
  { background = 0x291f43, border = 0x56468b, text = 0xe2ddfe }, -- violet
  { background = 0x302008, border = 0x714f19, text = 0xffe7b3 }, -- amber
  { background = 0x37172f, border = 0x833869, text = 0xfdd1ea }, -- pink
  { background = 0x132d21, border = 0x28684a, text = 0xb1f1cb }, -- green
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
local previewChip = { .12, .12, .12, 1 }

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
    -- Selected chips are filled. Hovering an unselected one previews it as a colored outline on a neutral fill.
    if assigned then
      chip:SetBackdropColor(unpack(style.background))
      chip:SetBackdropBorderColor(unpack(hovered and style.text or style.border))
      chip.text_overlay:SetTextColor(unpack(style.text))
    else
      chip:SetBackdropColor(unpack(hovered and previewChip or unassignedChip.background))
      chip:SetBackdropBorderColor(unpack(hovered and style.border or unassignedChip.border))
      chip.text_overlay:SetTextColor(unpack(hovered and style.text or unassignedChip.text))
    end
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
local function variationEditor(pack, id)
  local v = id and pack.variations[id]
  -- Form state survives redraws when resolutions are added or removed.
  local state = { name = v and v.name or "", description = v and v.description or "", sizes = {} }
  for _, size in ipairs(v and v.resolutions or {}) do
    table.insert(state.sizes, { width = tostring(size.width), height = tostring(size.height) })
  end
  state.any = #state.sizes == 0
  local fields
  -- Copy typed text into the state before a redraw or save rebuilds the inputs.
  local function collect()
    if not fields then return end
    state.name, state.description = fields.title:GetText(), fields.description:GetText()
    for index, row in ipairs(fields.sizes) do
      state.sizes[index].width, state.sizes[index].height = row.width:GetText(), row.height:GetText()
    end
  end
  local function draw(focus)
    collect()
    fields = { sizes = {} }
    local top = 56
    -- Each resolution after the first adds a row; the add button needs one more line.
    local extra = state.any and 0 or (#state.sizes - 1) * 42 + (#state.sizes < Packs.MAX_RESOLUTIONS and 36 or 0)
    local f = modal(v and "Edit variation" or "New variation", 460, 342 + top + extra)
    label(f, "Variations let you offer different versions of your UI, such as a healer layout or a different "
      .. "resolution.\nAfter creating the variation, select which profiles should belong to it.",
      24, 58, 412, 13, { .7, .7, .7 }):SetWordWrap(true)
    label(f, "Name", 24, top + 68, 412, 14)
    local title = input(f, state.name, 24, top + 92, 412)
    fields.title = title
    title:SetMaxLetters(120)
    label(f, "Resolution", 24, top + 142, 412, 14)
    dropdown(f, state.any and "any" or "specific", {
      { value = "any", label = "Any resolution", onclick = function() state.any = true; draw() end },
      { value = "specific", label = "Specific resolution(s)", onclick = function()
        state.any = false
        -- Prefill the creator's own screen; it is usually the resolution they designed for.
        if #state.sizes == 0 then
          local screenWidth, screenHeight = GetPhysicalScreenSize()
          state.sizes[1] = { width = tostring(screenWidth), height = tostring(screenHeight) }
        end
        draw()
      end },
    }, 24, top + 165, 180)
    local newest
    if not state.any then
      for index, size in ipairs(state.sizes) do
        local y = top + 164 + (index - 1) * 42
        newest = input(f, size.width, 216, y, 84)
        label(f, "×", 306, y + 8, 14, 14)
        fields.sizes[index] = { width = newest, height = input(f, size.height, 324, y, 84) }
        if #state.sizes > 1 then
          local remove = widget(f, "resolutionRemove", function()
            local icon = LWF:CreateIconButton(f, 20, [[Interface\Buttons\UI-GroupLoot-Pass-Up]])
            addon:UseWidgetTooltip(icon)
            icon:SetTooltip("Remove resolution")
            return icon
          end)
          remove:SetPoint("TOPLEFT", f, "TOPLEFT", 416, -(y + 7))
          remove:SetClickFunction(function() remove:HideTooltip(); collect(); table.remove(state.sizes, index); fields = nil; draw() end)
        end
      end
      if #state.sizes < Packs.MAX_RESOLUTIONS then
        button(f, "+ Add resolution", 216, top + 164 + #state.sizes * 42, 192, function()
          table.insert(state.sizes, { width = "", height = "" })
          draw("newest")
        end, nil, 28, 13)
      end
    end
    label(f, "Description (optional)", 24, top + 214 + extra, 412, 14)
    local description = input(f, state.description, 24, top + 238 + extra, 412)
    fields.description = description
    description:SetMaxLetters(2000)
    local function save()
      collect()
      local sizes
      if not state.any then
        sizes = {}
        for _, size in ipairs(state.sizes) do
          table.insert(sizes, { width = tonumber(size.width), height = tonumber(size.height) })
        end
      end
      local ok = safely(function()
        Packs.SaveVariation(pack, id, state.name, sizes, state.description)
      end)
      if not ok then return end
      closeModal(); render()
    end
    if v and id ~= "default" then
      dangerButton(f, "Delete", 24, top + 286 + extra, 110, function()
        confirmVariationDelete(pack, id, function() variationEditor(pack, id) end)
      end)
    end
    button(f, "Cancel", 216, top + 286 + extra, 100, closeModal)
    button(f, v and "Save" or "Create", 328, top + 286 + extra, 108, save)
    title:SetScript("OnEnterPressed", save)
    title:SetScript("OnEscapePressed", closeModal)
    if focus == "newest" and newest then
      newest:SetFocus()
    elseif focus == "name" then
      title:SetFocus()
      title:HighlightText()
    end
  end
  draw("name")
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
  -- Locked tabs ignore the mouse entirely: no hover, tooltip, actions or clicks.
  tab:EnableMouse(not entry.locked)
  tab:SetAlpha(entry.locked and .5 or 1)
  paintTab(tab)
  tab.updateActions()
  return tab
end

-- "All", one tab per variation, then the entry point for creating variations.
local function variationTabs(pack, filter, locked)
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
    entry.locked = locked
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

UI.resolutionText = resolutionText
UI.variationTabs = variationTabs
UI.variationToggle = variationToggle
