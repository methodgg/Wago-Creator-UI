-- Blizzard Cooldown Manager: class-specific layouts picked from every character's cache.
local addon = select(2, ...)
local Packs = addon.Packs
local UI = addon.UI
local ui = UI.view
local button, check, input, label, reset = UI.button, UI.check, UI.input, UI.label, UI.reset
local scroll, widget = UI.scroll, UI.widget
local closeModal, modal, safely = UI.closeModal, UI.modal, UI.safely
local function render() UI.render() end

local CDM = "Blizzard Cooldown Manager"
local WHITE = [[Interface\Buttons\WHITE8X8]]

-- A classAndSpecTag such as 121 is class 12 (Demon Hunter), spec 1 (Havoc).
local function specIcon(tag)
  local info = C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo
  local icon = info and select(4, info(tag % 10, false, false, nil, nil, nil, math.floor(tag / 10)))
  return icon or 134400
end

local function classColored(text, tag)
  local class = C_CreatureInfo and C_CreatureInfo.GetClassInfo(math.floor(tag / 10))
  local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class.classFile]
  return color and color.colorStr and ("|c" .. color.colorStr .. text .. "|r") or text
end

-- Class-colored layout name, with its character when it is not the one logged in.
local function layoutName(key, tag, character)
  local text = classColored(key, tag)
  if character and character ~= addon:CharacterKey() then text = text .. " |cff808080(" .. character .. ")|r" end
  return text
end

local function includedLayouts(pack)
  local result = {}
  for _, p in ipairs(Packs.Profiles(pack)) do
    if p.moduleName == CDM then table.insert(result, p) end
  end
  return result
end

-- Shared by both lists: the same row can be clicked or dragged onto the other list.
local function layoutRow(list, y, entry, actionTexture, actionTooltip, onActivate, dropTarget)
  local row = widget(list.content, "layoutRow", function()
    local f = CreateFrame("Button", nil, list.content, "BackdropTemplate")
    f:SetBackdrop({ bgFile = WHITE })
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(22, 22)
    f.icon:SetPoint("LEFT", f, "LEFT", 8, 0)
    f.icon:SetTexCoord(1 / 12, 11 / 12, 1 / 12, 11 / 12)
    f.text = f:CreateFontString(nil, "OVERLAY")
    f.text:SetFont(addon.FONT, 13, "")
    f.text:SetPoint("LEFT", f, "LEFT", 38, -1)
    f.text:SetJustifyH("LEFT")
    f.text:SetWordWrap(false)
    f.action = f:CreateTexture(nil, "OVERLAY")
    f.action:SetSize(16, 16)
    f.action:SetPoint("RIGHT", f, "RIGHT", -10, 0)
    f.paint = function(self)
      local hovered = self:IsMouseOver() and not addon.state.busy
      self:SetBackdropColor(.8, .8, .8, hovered and .12 or self.shade)
      self.action:SetShown(hovered)
    end
    f:SetScript("OnEnter", function(self) self:paint(); addon.ShowWidgetTooltip(self, self.tooltip) end)
    f:SetScript("OnLeave", function(self) self:paint(); addon.HideWidgetTooltip(self) end)
    f:SetScript("OnClick", function(self) if not addon.state.busy then self.onActivate() end end)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
      if addon.state.busy then return end
      local ghost = ui.layoutGhost
      ghost.text:SetText(self.text:GetText())
      ghost:SetSize(self:GetWidth(), self:GetHeight())
      ghost:Show()
      self.dragging = true
    end)
    f:SetScript("OnDragStop", function(self)
      if not self.dragging then return end
      self.dragging = nil
      ui.layoutGhost:Hide()
      self.dropTarget:SetBackdropBorderColor(.22, .22, .22, 1)
      if self.dropTarget:IsMouseOver() then self.onActivate() end
    end)
    return f
  end)
  row:SetPoint("TOPLEFT", list.content, "TOPLEFT", 0, -y)
  row:SetSize(list.content:GetWidth(), 32)
  row.shade = (y / 32) % 2 == 1 and .04 or 0
  row.icon:SetTexture(specIcon(entry.classAndSpecTag))
  row.text:SetWidth(row:GetWidth() - 70)
  row.text:SetText(layoutName(entry.key, entry.classAndSpecTag, entry.character))
  row.action:SetTexture(actionTexture)
  row.tooltip = actionTooltip
  row.onActivate, row.dropTarget = onActivate, dropTarget
  row:SetEnabled(not addon.state.busy)
  row:paint()
  return row
end

local function layoutList(f, kind, x, y, width, height)
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

-- Picks which Cooldown Manager layouts the pack exports; each one ships with every variation.
local function cooldownManager(pack)
  local query = ""
  local f = modal(CDM, 760, 600)
  local notes = label(f, "Give every Cooldown Manager profile a unique name. If two profiles share a name, only one of them "
    .. "can be imported. A good name is \"<YourName> <Spec>\".", 24, 58, 712, 13, { .7, .7, .7 })
  notes:SetWordWrap(true)
  label(f, "Exported CDM profiles will be available in all of your UI Pack variations.", 24, 92, 712, 13, { .7, .7, .7 })
  label(f, "Profiles from other characters are only available after logging into those characters at least once.",
    24, 110, 712, 13, { 1, .65, .3 }):SetWordWrap(true)
  if not ui.layoutGhost then
    -- Follows the cursor while a row is dragged between the lists.
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
    ui.layoutGhost = ghost
  end
  label(f, "Your profiles", 24, 140, 344, 16)
  local includedHeading = label(f, "", 392, 140, 344, 16)
  local search = input(f, "", 24, 164, 344)
  label(f, "Click or drag a profile to move it between the lists.", 392, 174, 344, 12, { .55, .55, .55 })
  local available = layoutList(f, "availableLayouts", 24, 206, 344, 290)
  local included = layoutList(f, "includedLayouts", 392, 206, 344, 290)
  ui.layoutGhost.lists = { available, included }

  local draw
  local function include(source)
    -- Packs puts every layout into all variations.
    safely(function()
      Packs.AddProfile(pack, CDM, source.key, source.key, nil, "cdm", source.character, source.classAndSpecTag)
    end)
    render(); draw()
  end
  local function exclude(p)
    safely(function() Packs.RemoveProfile(pack, p.id) end)
    render(); draw()
  end
  draw = function()
    reset(available.content); reset(included.content)
    local chosen, taken = includedLayouts(pack), {}
    for _, p in ipairs(chosen) do taken[(p.sourceCharacter or "") .. "|" .. p.sourceKey] = true end
    local y = 0
    for _, source in ipairs(addon:ProfileSources(CDM)) do
      local text = (source.key .. " " .. (source.character or "")):lower()
      if not taken[(source.character or "") .. "|" .. source.key] and text:find(query, 1, true) then
        layoutRow(available, y, source, [[Interface\ChatFrame\ChatFrameExpandArrow]], "Include in this UI Pack",
          function() include(source) end, included)
        y = y + 32
      end
    end
    if y == 0 then
      label(available.content, query == "" and "No more profiles to include." or "No profiles match your search.",
        0, 20, available.content:GetWidth(), 13, { .5, .5, .5 }):SetJustifyH("CENTER")
    end
    available.content:SetHeight(math.max(1, y))
    y = 0
    for _, p in ipairs(chosen) do
      layoutRow(included, y, { key = p.sourceKey, classAndSpecTag = p.classAndSpecTag, character = p.sourceCharacter },
        [[Interface\Buttons\UI-GroupLoot-Pass-Up]], "Remove from this UI Pack", function() exclude(p) end, available)
      y = y + 32
    end
    if y == 0 then
      label(included.content, "Click a profile on the left to include it.", 0, 20, included.content:GetWidth(), 13,
        { .5, .5, .5 }):SetJustifyH("CENTER")
    end
    included.content:SetHeight(math.max(1, y))
    includedHeading:SetText("Included profiles (" .. #chosen .. ")")
  end
  search:SetScript("OnTextChanged", function(self) query = self:GetText():lower(); draw() end)
  search:SetFocus()
  -- Frozen layouts keep their last export, so tweaking a spec later does not change a published pack.
  check(f, "Update Cooldown Manager profiles when saving", not pack.cdmExportsFrozen, 24, 512,
    function(value) pack.cdmExportsFrozen = not value or nil end)
  button(f, "Done", 606, 552, 130, function() closeModal(); render() end)
  draw()
end

UI.CDM = CDM
UI.cooldownManager = cooldownManager
UI.includedLayouts = includedLayouts
UI.layoutName = layoutName
