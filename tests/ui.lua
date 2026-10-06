-- Headless widget-contract smoke test; does not substitute for in-game rendering.
local addon, modules = dofile("tests/check.lua")
addon.L = setmetatable({}, { __index = function(_, key) return key end })
assert(loadfile("WagoUI/utils/Constants.lua"))("WagoUI", addon)
local frames = {}
local methods = {}
local function new(kind, parent)
  local f = setmetatable({ kind = kind, parent = parent, visible = true, width = 1000, height = 700, scripts = {} }, { __index = methods })
  table.insert(frames, f)
  return f
end
for _, method in ipairs({
  "ClearAllPoints", "SetPoint", "SetFont", "SetJustifyH", "SetTextColor", "SetWordWrap", "SetTooltip",
  "SetAutoFocus", "SetCursorPosition", "ClearFocus", "SetFocus", "HighlightText", "SetMaxLetters",
  "SetAllPoints", "EnableMouse", "SetBackdrop", "SetBackdropColor",
  "SetTextInsets", "SetHighlightColor",
  "SetJustifyV", "SetStatusBarTexture", "SetStatusBarColor", "SetMinMaxValues", "SetValue",
}) do methods[method] = function() end end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetWidth(w) self.width = w end
function methods:SetHeight(h) self.height = h end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:GetFont() return "font", 14 end
function methods:SetFont(face, size, flags) self.fontFace, self.fontSize, self.fontFlags = face, size, flags end
function methods:GetStringWidth() return #(self.text or "") * 6 end
function methods:GetStringHeight() return 28 end
function methods:SetMultiLine(value) self.multiLine = value end
function methods:SetScale(value) self.scale = value end
function methods:SetFrameStrata(value) self.strata = value end
function methods:SetClampedToScreen(value) self.clamped = value end
function methods:SetTexCoord(...) self.texCoords = { ... } end
function methods:SetDesaturated(value) self.desaturated = value end
function methods:SetVertexColor(...) self.vertexColor = { ... } end
function methods:SetText(value) self.text = value end
function methods:GetText() return self.text end
function methods:SetScript(event, callback) self.scripts[event] = callback end
function methods:HookScript(event, callback)
  local old = self.scripts[event]
  self.scripts[event] = function(...) if old then old(...) end; callback(...) end
end
function methods:Show() self.visible = true; if self.scripts.OnShow then self.scripts.OnShow(self) end end
function methods:Hide() self.visible = false; if self.scripts.OnHide then self.scripts.OnHide(self) end end
function methods:IsShown() return self.visible and (not self.parent or self.parent:IsShown()) end
function methods:IsMouseOver() return self.mouseOver or false end
function methods:SetShown(value) if value then self:Show() else self:Hide() end end
function methods:SetEnabled(value) self.enabled = value end
function methods:Enable() self.enabled = true end
function methods:Disable() self.enabled = false end
function methods:SetChecked(value) self.checked = value end
function methods:GetChecked() return self.checked end
function methods:SetFrameLevel(value) self.level = value end
function methods:GetFrameLevel() return self.level or (self.parent and self.parent:GetFrameLevel() + 1) or 100 end
function methods:CreateFontString() return new("font", self) end
function methods:CreateTexture() return new("texture", self) end
function methods:SetColorTexture(...) self.color = { ... } end
function methods:SetTextInsets(...) self.textInsets = { ... } end
function methods:SetHighlightColor(...) self.highlightColor = { ... } end
function methods:SetTexture(value) self.texture = value end
function methods:SetAlpha(value) self.alpha = value end
function methods:SetValue(value) self.value = value end
function methods:SetStatusBarColor(...) self.barColor = { ... } end
for _, state in ipairs({ "Normal", "Highlight", "Pushed" }) do
  methods["Set" .. state .. "Texture"] = function(self, value)
    self[state] = self[state] or new("buttonTexture", self)
    self[state]:SetTexture(value)
  end
  methods["Get" .. state .. "Texture"] = function(self) return self[state] end
end
function methods:SetAtlas(value) self.atlas = value end
function methods:SetTooltip(value) self.tooltip = value end
function methods:GetTooltip() return self.tooltip end
function methods:HideTooltip() end
function methods:SetBackdropBorderColor(...) self.borderColor = { ... } end
function methods:SetTextColor(...) self.textColor = { ... } end
function methods:SetBackdropColor(...) self.backgroundColor = { ... } end
function methods:SetJustifyH(value) self.justifyH = value end
function methods:SetPoint(...) self.point = { ... } end
function methods:HasFocus() return self.focused end
function methods:SetFocus()
  self.focused = true
  if self.scripts.OnEditFocusGained then self.scripts.OnEditFocusGained(self) end
end
function methods:ClearFocus()
  self.focused = false
  if self.scripts.OnEditFocusLost then self.scripts.OnEditFocusLost(self) end
end
function methods:SetScrollChild(child) self.child = child end
function methods:GetScrollChild() return self.child end
function methods:SetVerticalScroll(value) self.scroll = value end
function methods:GetVerticalScroll() return self.scroll or 0 end
function methods:GetThumbTexture() return self.ThumbTexture end
function methods:GetRegions() return self.ThumbTexture end
function CreateFrame(kind, _, parent, template)
  local f = new(kind, parent)
  if template == "UIPanelScrollFrameTemplate" then
    f.ScrollBar = new("scrollbar", f)
    f.ScrollBar.ThumbTexture = new("scrollThumb", f.ScrollBar)
    f.ScrollBar.ScrollUpButton = new("scrollArrow", f.ScrollBar)
    f.ScrollBar.ScrollDownButton = new("scrollArrow", f.ScrollBar)
  end
  return f
end
local LWF = {}
function LWF:CreateTextEntry(parent) return { editbox = new("EditBox", parent) } end
function LWF:CreateButton(parent)
  local f = new("button", parent)
  f.text_overlay = new("font", f)
  -- Match the framework's native press/release offsets, before native hooks.
  f:SetScript("OnMouseDown", function() f.text_overlay:SetPoint("CENTER", f, "CENTER", 1, -1) end)
  f:SetScript("OnMouseUp", function() f.text_overlay:SetPoint("CENTER", f, "CENTER", 0, 0) end)
  function f:SetTextTruncated(value) self.text = value; self.text_overlay:SetText(value) end
  function f:SetClickFunction(callback, _, _, clickType)
    if clickType == "RightButton" then self.rightClick = callback else self.click = callback end
  end
  return f
end
function LWF:CreateIconButton(parent, size)
  local f = self:CreateButton(parent)
  f.disabled_overlay = new("disabledOverlay", f)
  f.disabled_overlay:SetTexture([[Interface\Tooltips\UI-Tooltip-Background]])
  f.kind = size == 36 and "addonIcon" or "iconAction"
  f:SetSize(size, size)
  for _, state in ipairs({ "Normal", "Pushed", "Highlight", "Disabled" }) do
    local texture = new("iconTexture", f)
    f["Get" .. state .. "Texture"] = function() return texture end
  end
  return f
end
function LWF:CreateCheckbox(parent, size)
  local f = new("checkbox", parent)
  f:SetSize(size, size)
  f.checked_texture = new("checkTexture", f)
  function f:SetValue(value, runCallback)
    self.checked = value
    if runCallback == "RUN_CALLBACK" then self.callback(self, nil, value) end
  end
  function f:SetSwitchFunction(callback) self.callback = callback end
  return f
end
function LWF:CreateDropdown(parent)
  local f = new("dropdown", parent)
  f.menus = {}
  function f:GetValue() return self.value end
  f.label = new("font", f)
  f.dropdown = { dropdownframe = new("menu", f), dropdownborder = new("border", f) }
  local menu = f.dropdown.dropdownframe
  menu.slider = new("menuSlider", menu)
  menu.slider.ThumbTexture = new("scrollThumb", menu.slider)
  menu.cima, menu.baixo = new("scrollArrow", menu), new("scrollArrow", menu)
  menu.child = new("menuContent", menu)
  menu.child.selected, menu.child.mouseover = new("highlight", menu.child), new("highlight", menu.child)
  menu:Hide(); f.dropdown.dropdownborder:Hide()
  function f:SetMenuSize(width, height) self.menuWidth, self.menuHeight = width, height end
  function f:Close() menu:Hide(); self.dropdown.dropdownborder:Hide() end
  function f:SetFunction(callback) self.options = callback end
  function f:Refresh() assert(type(self.options()) == "table") end
  function f:Select(value) self.value = value end
  function f:NoOptionSelected() self.value = nil end
  return f
end
local oldLibStub = LibStub
function LibStub(name) return name == "LibWagoFramework" and LWF or oldLibStub(name) end
DetailsFramework = { ApplyStandardBackdrop = function() end, CreateBorder = function(_, parent) parent.blackBorder = true end }
SmoothStatusBarMixin = {
  SetMinMaxSmoothedValue = function(self, low, high) self.minimum, self.maximum = low, high end,
  SetSmoothedValue = function(self, value) self.value, self.smoothed = value, true end,
}
function Mixin(target, mixin) for key, value in pairs(mixin) do target[key] = value end end
-- Stock field chrome and framework overlays must not cover the shared fill.
local stockParent = new("Frame")
stockParent:Hide()
local stockField = new("EditBox", stockParent)
stockField:Hide()
stockField.Left, stockField.Middle, stockField.Right = new("texture", stockField), new("texture", stockField), new("texture", stockField)
stockField.__background = new("texture", stockField)
addon:StyleEditBox(stockField)
assert(not stockField.Left.visible and not stockField.Middle.visible and not stockField.Right.visible
  and not stockField.__background.visible, "Stock field textures obscure the shared edit-box style")
assert(stockField.textInsets[1] == 10 and stockField.backgroundColor[1] == .055)
function GetPhysicalScreenSize() return 1920, 1080 end
local reloads = 0
function ReloadUI() reloads = reloads + 1 end
date = os.date
C_AddOns.GetNumAddOns = function() return 0 end
addon.db, addon.dbC, addon.state = {}, {}, {}
addon:InitializePacks()
local function button(text)
  local found
  for i = #frames, 1, -1 do
    local f = frames[i]
    if f.kind == "button" and f:IsShown() and f.text == text then
      if not found or f:GetFrameLevel() > found:GetFrameLevel() then found = f end
    end
  end
  if found then assert(found.enabled ~= false, "Disabled button: " .. text); return found end
  error("Missing button: " .. text)
end
local function click(text) button(text).click() end
local function closeDialog()
  for _, f in ipairs(frames) do
    if f:IsShown() and f.parent and f.parent.pools and f.parent.pools.closeButton
      and f.parent.pools.closeButton[1] == f then
      assert(f:GetWidth() == 16 and f:GetHeight() == 16 and f.alpha == .7)
      for _, state in ipairs({ "Normal", "Highlight", "Pushed" }) do
        local texture = f["Get" .. state .. "Texture"](f)
        assert(texture.texture == [[Interface\GLUES\LOGIN\Glues-CheckBox-Check]] and texture.desaturated,
          "Dialog close button does not match the main window")
      end
      f.scripts.OnClick(f)
      assert(not f.parent:IsShown(), "Close button did not dismiss the dialog")
      return
    end
  end
  error("Missing dialog close button")
end
local function visible(kind)
  local out = {}
  for _, f in ipairs(frames) do if f.kind == kind and f:IsShown() then table.insert(out, f) end end
  return out
end
local function hasText(text)
  for _, f in ipairs(visible("font")) do if f.text == text then return true end end
  return false
end
local function packSelector()
  for _, selector in ipairs(visible("dropdown")) do
    for _, entry in ipairs(selector.options()) do
      if entry.action then return selector end
    end
  end
  error("Missing creator pack selector")
end
local function newPack()
  local selector = packSelector()
  for _, entry in ipairs(selector.options()) do
    if entry.action then
      assert(entry.label == "+ Add UI Pack")
      local row = new("option", selector.dropdown.dropdownframe)
      row.label = new("font", row)
      selector.OnUpdateOptionFrame(selector, row, entry)
      row.scripts.OnMouseDown()
      return
    end
  end
end
-- Load the workspace files in ui/load.xml order, as the client does.
local function loadWorkspace()
  local xml = assert(io.open("WagoUI/ui/load.xml")):read("*a")
  for file in xml:gmatch('<Script file="([^"]+)"') do assert(loadfile("WagoUI/ui/" .. file))("WagoUI", addon) end
end
local openedSettings = 0
modules.Test.icon = 123456
modules.Test.openConfig = function() openedSettings = openedSettings + 1 end
loadWorkspace()
addon.frames.mainFrame = new("root")
addon:CreateWorkspace(addon.frames.mainFrame)
assert(#visible("dropdown") == 0, "Empty pack selector is visible")
for _, f in ipairs(frames) do
  if f.kind == "scrollbar" then
    assert(f.parent.scrollBarHideable and not f.visible, "Empty scrollbar does not auto-hide")
    assert(f:GetWidth() == 12 and f.ThumbTexture:GetWidth() == 8 and f.ThumbTexture.color[1] == .76)
    f.ScrollUpButton:Show(); f.ScrollDownButton:Show()
    assert(not f.ScrollUpButton.visible and not f.ScrollDownButton.visible, "Stock scrollbar arrows returned")
    f.scripts.OnEnter(f)
    assert(f.ThumbTexture.color[1] == .95, "Scrollbar has no hover feedback")
    f.scripts.OnLeave(f)
  end
end
for _, f in ipairs(visible("button")) do
  assert(f.text ~= "Create" and f.text ~= "+ Create" and f.text ~= "+ UI pack" and f.text ~= "Import string",
    "Creator/import controls surfaced on the installer landing page")
end
click("Create a UI Pack")
for _, f in ipairs(visible("dropdown")) do assert(not f.enabled, "Empty creator leaves the pack selector unlocked") end
for _, f in ipairs(visible("EditBox")) do assert(not f.enabled, "Empty creator leaves search unlocked") end
local createCount = 0
for _, f in ipairs(visible("button")) do if f.text == "Create your UI Pack" then createCount = createCount + 1 end end
assert(createCount == 1, "Creator empty state needs one action")
click("Create your UI Pack")
local nameEntry = visible("EditBox")[#visible("EditBox")]
assert(nameEntry.parent:GetWidth() == 440 and nameEntry.parent:GetHeight() == 224, "Naming dialog is not compact")
assert(nameEntry:HasFocus() and nameEntry.borderColor[1] == 0.76, "Name field is not focused/styled")
nameEntry.scripts.OnEnterPressed(nameEntry)
assert(not next(addon.db.creator.packs) and nameEntry:IsShown(), "Enter accepted an empty name")
closeDialog()
for _, f in ipairs(visible("button")) do assert(f.text ~= "Import string", "Raw string import is still exposed") end
click("Create your UI Pack")
local fields = visible("EditBox")
fields[#fields]:SetText("Smoke UI")
fields[#fields].scripts.OnEnterPressed(fields[#fields])
local pack = addon.db.creator.packs[addon.db.creator.selected]
assert(pack and pack.name == "Smoke UI")
newPack()
assert(#visible("EditBox") == 2, "Adding another pack did not open naming")
closeDialog()
assert(#visible("dropdown") > 0 and #visible("EditBox") > 0, "Pack controls did not return after creation")
for _, f in ipairs(visible("button")) do
  assert(f.text ~= "+ UI pack" and f.tooltip ~= "Pack actions", "Separate pack management buttons remain")
end
local selector = packSelector()
assert(selector.label.fontSize == 16 and selector.menuWidth == selector:GetWidth() / 1.5)
selector.dropdown.dropdownframe:Show()
assert(selector.dropdown.dropdownframe:GetWidth() * 1.5 == selector:GetWidth(), "Menu does not match selector width")
local option = selector.options()[1]
local row = new("option", selector.dropdown.dropdownframe)
row.label = new("font", row)
row.table = option
row:SetWidth(200)
selector.menus = { row }
selector.OnUpdateOptionFrame(selector, row, option)
selector.dropdown.dropdownframe:Show()
assert(selector.dropdown.dropdownframe.child.selected:GetWidth() == 161,
  "Selection highlight overlaps the cogwheel")
assert(row.label.fontFace == addon.FONT and row.label.fontSize * 1.5 == 16)
local rename, delete = unpack(row.pools.packAction)
assert(not rename:IsShown() and not delete:IsShown(), "Pack icons appear without hovering")
row.mouseOver = true
row.scripts.OnEnter(row)
assert(selector.dropdown.dropdownframe.child.mouseover:GetWidth() == 161,
  "Hover highlight overlaps the cogwheel")
assert(rename:IsShown() and delete:IsShown(), "Hover did not reveal pack icons")
assert(rename.texture == [[Interface\Buttons\UI-OptionsButton]] and rename.tooltip == "Rename UI pack")
assert(delete.texture == [[Interface\Buttons\UI-GroupLoot-Pass-Up]] and delete.tooltip == "Delete UI pack")
assert(rename:GetNormalTexture().desaturated and not delete:GetNormalTexture().desaturated)
row.mouseOver, rename.mouseOver = false, true
row.scripts.OnLeave(row)
assert(rename:IsShown() and delete:IsShown(), "Moving onto an icon hid the actions")
rename.mouseOver = false
rename.scripts.OnLeave(rename)
assert(not rename:IsShown() and not delete:IsShown(), "Leaving the entry did not hide its actions")
row.mouseOver = true
row.scripts.OnEnter(row)
rename.click()
assert(not selector.dropdown.dropdownframe:IsShown(), "Rename left the dropdown open")
fields = visible("EditBox")
fields[#fields]:SetText("Renamed UI")
fields[#fields].scripts.OnEnterPressed(fields[#fields])
assert(pack.name == "Renamed UI", "Dropdown rename failed")
selector.OnUpdateOptionFrame(selector, row, selector.options()[2])
for _, action in ipairs(row.pools.packAction) do assert(not action.visible, "Pack actions leaked onto the new-pack row") end
local searchHint
for _, f in ipairs(visible("font")) do if f.text == "Search AddOns, profiles or variations…" then searchHint = f end end
assert(searchHint and searchHint.parent.kind == "EditBox" and searchHint.textColor[1] >= 0.65,
  "Search hint must draw on the editbox above its backdrop")
C_AddOns.GetNumAddOns = function() return 1 end
C_AddOns.GetAddOnMetadata = function() return "extra-id" end
C_AddOns.GetAddOnInfo = function() return "Extra Addon" end
click("Manage")
local extraCheck = visible("checkbox")[1]
assert(extraCheck.checked_texture.desaturated and extraCheck.backdrop_enabledcolor[1] == 0.76)
extraCheck:SetValue(true, "RUN_CALLBACK")
click("Save")
assert(pack.additionalAddons["extra-id"] == "Extra Addon")
button("Manage (1)")
local testIcon
for _, icon in ipairs(visible("addonIcon")) do if icon.texture == modules.Test.icon then testIcon = icon end end
assert(testIcon and testIcon.tooltip == "Open Test settings" and testIcon.enabled)
for _, state in ipairs({ "Normal", "Pushed", "Highlight", "Disabled" }) do
  local coords = testIcon["Get" .. state .. "Texture"](testIcon).texCoords
  assert(coords[1] == 1 / 12 and coords[2] == 11 / 12 and coords[3] == 1 / 12 and coords[4] == 11 / 12)
end
testIcon.click()
assert(openedSettings == 1, "Addon icon did not open its settings")
assert(#visible("texture") >= #visible("addonIcon"), "Addon row backgrounds are missing")
for _, f in ipairs(visible("font")) do
  if f.text == "Test" then assert(f.textColor[1] == 0.95, "Enabled addon without profiles is not white") end
end
local rowOffsets = {}
for _, icon in ipairs(visible("addonIcon")) do table.insert(rowOffsets, -icon.point[5]) end
table.sort(rowOffsets)
for i = 2, #rowOffsets do assert(rowOffsets[i] - rowOffsets[i - 1] == 44, "Empty addon rows have gaps") end
for _, f in ipairs(visible("button")) do assert(f.tooltip ~= "Variations", "Top variation button remains") end
addon.Packs.SaveVariation(pack, nil, "Compact", nil, "")
addon:RefreshWorkspace()
local function profileSelectors()
  local out = {}
  for _, f in ipairs(visible("dropdown")) do
    if f.moduleName == "Test" then table.insert(out, f) end
  end
  table.sort(out, function(a, b) return a.point[5] > b.point[5] end)
  return out
end
local function variationFields()
  local fields = {}
  for _, box in ipairs(frames) do
    if box.kind == "EditBox" and box.parent:IsShown() then
      if box.point and box.point[5] == -110 then fields.name = box
      elseif box.point and box.point[5] == -202 then
        if box.point[4] == 328 then fields.width = box else fields.height = box end
      elseif box.point and box.point[5] == -276 then fields.description = box end
    end
  end
  assert(fields.name and fields.width and fields.height and fields.description)
  return fields
end
local function membershipChecks()
  local checks = {}
  for _, box in ipairs(visible("checkbox")) do
    if box.parent.parent and box.parent.parent.kind == "ScrollFrame" then checks[#checks + 1] = box end
  end
  return checks
end
local function selectSource(selector, key)
  local options = selector.options()
  selector.OnMouseDownHook(nil, nil, options)
  for _, option in ipairs(options) do
    if option.label:find(key, 1, true) then option.onclick(); return end
  end
  error("Missing profile source: " .. key)
end
local function hoverRow(selector)
  for _, f in ipairs(visible("Frame")) do
    if f.actions then
      f.mouseOver = selector ~= nil and f.point[5] == selector.point[5] + 6
      f.parent.parent.mouseOver = selector ~= nil
      f.scripts.OnUpdate(f)
    end
  end
end
local function iconAt(tooltip, selector)
  hoverRow(selector)
  for _, icon in ipairs(visible("iconAction")) do
    if icon.tooltip == tooltip and icon.point[5] == selector.point[5] - 2 then
      assert(icon:GetWidth() == 28 and icon:GetHeight() == 28, "Profile action hit target is too small")
      assert(icon.parent:GetWidth() - icon.point[4] - icon:GetWidth() >= 20, "Profile action lacks right padding")
      if tooltip == "Add alternate profile" then
        for _, state in ipairs({ "Normal", "Pushed", "Highlight", "Disabled" }) do
          assert(icon["Get" .. state .. "Texture"](icon).atlas == "communities-icon-addgroupplus", "Native add icon is missing")
        end
      end
      return icon
    end
  end
  error("Missing row action: " .. tooltip)
end
local function checkRowHover(selector, addonLoaded)
  hoverRow(nil)
  for _, icon in ipairs(visible("iconAction")) do
    assert(icon.tooltip ~= "Add alternate profile" and icon.tooltip ~= "Clear selected profile"
      and icon.tooltip ~= "Remove alternate profile", "Profile action is visible without row hover")
  end
  if not addonLoaded then
    hoverRow(selector)
    for _, icon in ipairs(visible("iconAction")) do
      assert(icon.tooltip ~= "Add alternate profile" and icon.tooltip ~= "Clear selected profile"
        and icon.tooltip ~= "Remove alternate profile", "Unavailable addon shows profile actions on hover")
    end
    hoverRow(nil)
    return
  end
  local add = iconAt("Add alternate profile", selector)
  local remove = iconAt("Clear selected profile", selector)
  assert(add.enabled and remove.enabled, "Hovered profile actions have incorrect availability")
  assert(add.disabled_overlay.texture == nil, "Disabled plus has a rectangular overlay")
  for _, icon in ipairs(visible("iconAction")) do
    if icon.tooltip == "Add alternate profile" or icon.tooltip == "Clear selected profile" or icon.tooltip == "Remove alternate profile" then
      assert(icon.point[5] == selector.point[5] - 2, "Another row's actions appeared")
    end
  end
  hoverRow(nil)
  assert(not add:IsShown() and not remove:IsShown(), "Actions remained after leaving the row")
end
checkRowHover(profileSelectors()[1], true)
local sourceCalls, originalSources = 0, addon.ProfileSources
function addon:ProfileSources(...)
  sourceCalls = sourceCalls + 1
  return originalSources(self, ...)
end
addon:RefreshWorkspace()
assert(sourceCalls == 0, "Rendering eagerly enumerates all addon profiles")
selectSource(profileSelectors()[1], "Raid")
assert(sourceCalls == 1)
local id = pack.profileOrder[1]
assert(pack.profiles[id].sourceKey == "Raid" and pack.profiles[id].variations.default)
for _, f in ipairs(visible("font")) do
  if f.text == "Test" then assert(f.textColor[1] == 0.95, "Addon with profiles stayed grey") end
end
-- Variations are assigned inline: every row shows every variation as a toggle.
local function variationTabs()
  local out = {}
  for _, f in ipairs(visible("Button")) do if f.swatch then table.insert(out, f) end end
  table.sort(out, function(a, b) return a.point[4] < b.point[4] end)
  return out
end
local function openTab(index)
  local tab = variationTabs()[index]
  tab.scripts.OnClick(tab)
end
local function tabNamed(name)
  for _, tab in ipairs(variationTabs()) do if tab.label.text == name then return tab end end
  error("Missing variation tab: " .. name)
end
local function chipFor(selector, name)
  local best
  for _, chip in ipairs(visible("button")) do
    if chip.variationID and chip.text == name and chip.point[5] <= selector.point[5] - 3
      and (not best or chip.point[5] > best.point[5]) then best = chip end
  end
  return assert(best, "Missing variation toggle: " .. name)
end
local function findButton(text)
  for i = #frames, 1, -1 do
    if frames[i].kind == "button" and frames[i]:IsShown() and frames[i].text == text then return frames[i] end
  end
  error("Missing button: " .. text)
end
local function variationForm()
  local form, top = {}, 56
  for _, box in ipairs(visible("EditBox")) do
    if box.parent.kind == "Frame" and box.parent:GetWidth() == 460 then
      if box.point[5] == -(top + 92) then form.name = box
      elseif box.point[5] == -(top + 164) then if box.point[4] == 216 then form.width = box else form.height = box end
      elseif box.point[4] == 24 then form.description = box end
    end
  end
  assert(form.name and form.description, "Missing variation editor fields")
  for _, box in ipairs(visible("dropdown")) do
    if box.parent == form.name.parent and box.point[5] == -(top + 165) then form.resolution = box end
  end
  return form
end
local function warningIcons()
  local out = {}
  for _, f in ipairs(visible("Frame")) do
    if f.texture and f.texture.texture == [[Interface\DialogFrame\UI-Dialog-Icon-AlertNew]] then table.insert(out, f) end
  end
  return out
end
local compactID = pack.variationOrder[2]
local firstSelector = profileSelectors()[1]
local defaultChip, compactChip = chipFor(firstSelector, "Default"), chipFor(firstSelector, "Compact")
assert(defaultChip.assigned and not compactChip.assigned, "Toggles do not reflect the profile's variations")
assert(defaultChip.point[5] == firstSelector.point[5] - 3 and defaultChip.point[4] == 524,
  "Variation toggles do not start right of the profile column")
assert(defaultChip.borderColor[1] == 32 / 255 and defaultChip.borderColor[2] == 93 / 255, "Default chip is not the blue palette")
assert(compactChip.borderColor[1] == .24 and compactChip.text_overlay.textColor[1] == .6, "Unassigned toggle is not muted")
assert(not defaultChip.removeButton and not compactChip.tooltip, "Toggles still carry a remove control or tooltip")
compactChip.parent.parent.mouseOver, compactChip.mouseOver = true, true
compactChip.scripts.OnUpdate()
assert(compactChip.borderColor[1] == variationTabs()[3].swatch.color[1], "Unassigned toggle has no hover preview")
compactChip.parent.parent.mouseOver, compactChip.mouseOver = false, false
compactChip.scripts.OnUpdate()
local anchor = compactChip.text_overlay.point
for _, event in ipairs({ "OnMouseDown", "OnMouseUp" }) do
  compactChip.scripts[event](compactChip)
  for index, value in ipairs(anchor) do assert(compactChip.text_overlay.point[index] == value, "Clicking moves chip text") end
end
compactChip.click()
assert(#visible("EditBox") == 1, "Assigning a variation opened a dialog")
assert(pack.profiles[id].variations.default and pack.profiles[id].variations[compactID], "Toggle did not assign")
chipFor(profileSelectors()[1], "Default").click()
assert(not pack.profiles[id].variations.default and pack.profiles[id].variations[compactID], "Toggle did not unassign")
-- New alternates start unassigned, are flagged, and block saving until assigned.
iconAt("Add alternate profile", profileSelectors()[1]).click()
assert(#visible("EditBox") == 1, "Adding an alternate opened a dialog")
assert(#profileSelectors() == 2 and #pack.profileOrder == 1, "Blank alternate became an installable profile")
local blankRow = profileSelectors()[2].profileRow
assert(not next(blankRow.variations), "New alternate started with variations")
local icons = warningIcons()
assert(#icons == 1 and icons[1].point[5] == profileSelectors()[2].point[5] - 5
  and icons[1].point[4] + icons[1]:GetWidth() <= profileSelectors()[2].point[4], "Unassigned row lacks a warning beside its profile")
local tinted = false
for _, f in ipairs(visible("texture")) do
  if f.color and f.color[1] == .95 and f.color[4] == .12 and f.point[5] == profileSelectors()[2].point[5] + 6 then tinted = true end
end
assert(tinted, "Unassigned row is not tinted")
local saveAllButton = findButton("Save All Profiles")
assert(saveAllButton.enabled == false, "Save All Profiles allows unassigned profiles")
local blocker
for _, f in ipairs(visible("Frame")) do
  if f.parent == saveAllButton.parent and (f.tooltip or ""):find("Incomplete: Test", 1, true) then blocker = f end
end
assert(blocker and blocker:GetFrameLevel() > saveAllButton:GetFrameLevel(), "Blocked save does not explain why")
-- The add tab opens the variation manager, which only edits the variation itself.
local addTab = tabNamed("+ Add variation")
assert(addTab == variationTabs()[#variationTabs()] and addTab.count.text == "" and not addTab.swatch:IsShown())
addTab.scripts.OnClick(addTab)
local form = variationForm()
assert(hasText("New variation") and form.name:HasFocus() and not form.width, "New variation form is incomplete")
assert(not hasText("Profile Variations"), "Variation manager shows assignments")
form.name:SetText("Raid alternate")
click("Create")
local raidAlternate = pack.variationOrder[3]
assert(pack.variations[raidAlternate].name == "Raid alternate" and #addon.Packs.Profiles(pack, raidAlternate) == 0)
assert(variationTabs()[1].active, "Creating a variation left the current tab")
chipFor(profileSelectors()[2], "Raid alternate").click()
assert(blankRow.variations[raidAlternate] and #pack.profileOrder == 1, "Blank row assignment changed saved profiles")
assert(#warningIcons() == 1 and warningIcons()[1].tooltip:find("No profile selected", 1, true), "Variation without profile is not flagged")
selectSource(profileSelectors()[2], "Other")
-- Saving also needs every variation to have a profile; Default would otherwise be empty here.
chipFor(profileSelectors()[1], "Default").click()
assert(#warningIcons() == 0 and button("Save All Profiles"), "Completed row is still flagged")
assert(#pack.profileOrder == 2)
assert(pack.profiles[pack.profileOrder[2]].variations[raidAlternate])
local testIconCount = 0
for _, f in ipairs(visible("addonIcon")) do if f.texture == modules.Test.icon then testIconCount = testIconCount + 1 end end
assert(testIconCount == 1, "Alternate row repeats the addon icon")
local grouped = profileSelectors()
-- Tooltips use only WagoUI's native frame, never a shared library tooltip.
GameCooltip = setmetatable({}, { __index = function() error("WagoUI used GameCooltip") end })
local tooltipOwner = grouped[2]
tooltipOwner.mouseOver = true
tooltipOwner:ShowTooltip()
local nativeTooltip
for _, candidate in ipairs(visible("Frame")) do
  if candidate.owner == tooltipOwner then nativeTooltip = candidate end
end
assert(nativeTooltip and nativeTooltip.strata == "TOOLTIP" and nativeTooltip.clamped)
assert(nativeTooltip.text.fontFace == addon.FONT and nativeTooltip.text.fontSize == 12,
  "Native tooltip has the wrong font or size")
assert(nativeTooltip.text:GetText() == tooltipOwner.tooltip and nativeTooltip:GetWidth() <= 340,
  "Native tooltip lost its multi-line content or width limit")
grouped[1]:HideTooltip()
assert(nativeTooltip:IsShown(), "Another widget hid the current tooltip")
tooltipOwner:HideTooltip()
assert(not nativeTooltip:IsShown())
tooltipOwner:ShowTooltip()
tooltipOwner.mouseOver = false
nativeTooltip.scripts.OnUpdate(nativeTooltip)
assert(not nativeTooltip:IsShown(), "Native tooltip remained after leaving its owner")
local frameCount = #frames
tooltipOwner.mouseOver = true
tooltipOwner:ShowTooltip()
assert(#frames == frameCount, "Showing a tooltip allocates another frame")
tooltipOwner:Hide()
nativeTooltip.scripts.OnUpdate(nativeTooltip)
assert(not nativeTooltip:IsShown(), "Native tooltip remained after its owner was hidden")
tooltipOwner:Show(); tooltipOwner.mouseOver = false
assert(grouped[2].point[4] == grouped[1].point[4] + 16, "Alternate profile is not indented")
assert(grouped[2].point[4] + grouped[2]:GetWidth() == grouped[1].point[4] + grouped[1]:GetWidth(),
  "Indented profiles lost their aligned right edge")
assert(grouped[2].tooltip:find("Test\n", 1, true), "Alternate tooltip does not identify its addon")
for _, f in ipairs(visible("font")) do assert(f.text ~= "Alternate profile", "Redundant alternate label remains") end
local connectors = grouped[1].parent.pools.profileConnector
-- The saved additional addon draws its own branch after the Test group.
assert(connectors and #connectors == 4, "Addon group is missing its connecting branch")
assert(connectors[1]:GetWidth() == 8 and connectors[2]:GetWidth() == 1)
assert(connectors[2]:GetHeight() == 29, "Branch does not join the main and alternate dropdowns")
local sharedBackground = false
for _, background in ipairs(grouped[1].parent.pools.rowBackground) do
  if background:IsShown() and background.point[5] == grouped[1].point[5] + 6 then
    sharedBackground = background:GetHeight() == 87
  end
end
assert(sharedBackground, "Addon profiles are not enclosed in one shared row group")
local tagsBefore = CopyTable(pack.profiles[id].variations)
addon.Packs.SetMembership(pack, id, { default = true, [pack.variationOrder[2]] = true, [pack.variationOrder[3]] = true })
addon:RefreshWorkspace()
local withChips = profileSelectors()
assert(withChips[1].point[4] == 300 and withChips[1]:GetWidth() == 210, "Profile selector did not move left")
for _, control in ipairs(visible("button")) do
  if control.tooltip == "Choose additional addons to include" then
    assert(control.point[4] == 300, "Manage button did not move with the profile selectors")
  end
end
local colors = {}
for _, chip in ipairs(visible("button")) do
  if chip.variationID then
    assert(chip.point[4] >= 524 and chip.point[4] + chip:GetWidth() <= 826,
      "Variation chips overlap profile selectors or reserved action buttons")
    if chip.assigned then
      for _, other in ipairs(colors[chip.text] or {}) do
        assert(other[1] == chip.borderColor[1] and other[2] == chip.borderColor[2] and other[3] == chip.borderColor[3],
          "Variation chip colors differ between rows")
      end
      colors[chip.text] = { chip.borderColor }
    end
  end
end
assert(colors.Default[1][1] ~= colors.Compact[1][1] or colors.Default[1][2] ~= colors.Compact[1][2])
addon.Packs.SetMembership(pack, id, tagsBefore)
addon:RefreshWorkspace()
-- Tab actions reserve their space and only appear on hover.
local compactTab = tabNamed("Compact")
local compactWidth = compactTab:GetWidth()
assert(not compactTab.edit:IsShown() and not compactTab.delete:IsShown(), "Tab actions show without hovering")
compactTab.mouseOver = true
compactTab.scripts.OnEnter(compactTab)
assert(compactTab.edit:IsShown() and compactTab.delete:IsShown() and compactTab:GetWidth() == compactWidth,
  "Hovering a tab did not reveal its actions in place")
assert(compactTab.delete.texture == [[Interface\Buttons\UI-GroupLoot-Pass-Up]]
  and compactTab.edit.texture == [[Interface\Buttons\UI-OptionsButton]], "Tab actions use the wrong icons")
assert(compactTab.edit.point[4] < compactTab.delete.point[4], "Edit is not left of delete")
compactTab.mouseOver = false
compactTab.scripts.OnLeave(compactTab)
assert(not compactTab.edit:IsShown() and not compactTab.delete:IsShown(), "Tab actions remain after leaving")
local defaultTab = tabNamed("Default")
defaultTab.mouseOver = true
defaultTab.scripts.OnEnter(defaultTab)
assert(defaultTab.edit:IsShown() and not defaultTab.delete:IsShown(), "Default can be deleted")
defaultTab.mouseOver = false
defaultTab.scripts.OnLeave(defaultTab)
-- Editing validates before changing the pack.
tabNamed("Compact").edit.click()
form = variationForm()
assert(hasText("Edit variation") and form.name:GetText() == "Compact")
form.name:SetText("Default")
click("Save")
assert(form.name:IsShown() and pack.variations[compactID].name == "Compact", "Duplicate name escaped validation")
form.name:SetText("Compact")
for _, option in ipairs(form.resolution.options()) do
  if option.label == "Specific resolution(s)" then option.onclick() end
end
form = variationForm()
assert(form.width:IsShown() and form.width:GetText() == "1920" and form.height:GetText() == "1080",
  "Specific resolution is not prefilled with the screen size")
form.width:SetText("0")
click("Save")
assert(form.name:IsShown() and not pack.variations[compactID].resolutions, "Invalid resolution changed the pack")
form.width:SetText("1920")
form.description:SetText("Compact layout")
click("Save")
assert(not form.name:IsShown() and pack.variations[compactID].resolutions[1].width == 1920
  and pack.variations[compactID].description == "Compact layout")
assert(tabNamed("Compact").tooltip:find("1920 × 1080", 1, true), "Tab tooltip lacks the resolution")
tabNamed("+ Add variation").scripts.OnClick(tabNamed("+ Add variation"))
form = variationForm()
form.name:SetText("Disposable")
click("Create")
local disposable = pack.variationOrder[4]
-- Deletion always asks first, from the tab or from the editor.
addon.Packs.SetMembership(pack, id, { [disposable] = true })
addon:RefreshWorkspace()
tabNamed("Disposable").delete.click()
assert(hasText("Delete Disposable?"), "Tab delete did not ask for confirmation")
local orphanNotice = false
for _, f in ipairs(visible("font")) do
  if (f.text or ""):find("1 profile is only in Disposable", 1, true) then orphanNotice = true end
end
assert(orphanNotice, "Deletion does not warn about profiles that lose every variation")
click("Cancel")
assert(pack.variations[disposable], "Cancel deleted the variation")
tabNamed("Disposable").edit.click()
click("Delete")
assert(hasText("Delete Disposable?"))
click("Back")
assert(variationForm().name:GetText() == "Disposable", "Back did not return to the editor")
click("Delete")
click("Delete")
assert(not pack.variations[disposable] and pack.profiles[id] and not next(pack.profiles[id].variations),
  "Deleting a variation removed its profile or kept the tag")
assert(tabNamed("All").active, "Deleted variation's tab stayed selected")
assert(findButton("Save All Profiles").enabled == false and #warningIcons() == 1,
  "Profile left without variations is not flagged")
chipFor(profileSelectors()[1], "Compact").click()
assert(pack.profiles[id].variations[compactID] and #warningIcons() == 0)
chipFor(profileSelectors()[1], "Default").click()
local saveAll = button("Save All Profiles")
assert(saveAll:GetWidth() == 300 and saveAll:GetHeight() == 50 and saveAll.text_overlay.fontSize == 20)
assert(saveAll.point[4] == (saveAll.parent:GetWidth() - 300) / 2 and saveAll.point[5] == 14,
  "Save All Profiles is not centered at the bottom")
click("Save All Profiles")
local notes
for _, box in ipairs(visible("EditBox")) do if box.multiLine then notes = box end end
assert(notes and notes:GetText():find("## Updated / Added:", 1, true), "Missing editable Markdown notes")
local captureBar = visible("StatusBar")[1]
local captureProgress = captureBar and captureBar.parent
assert(captureProgress and captureProgress:GetWidth() == 280 and captureProgress:GetHeight() == 20,
  "Progress bar does not use its old thin dimensions")
assert(captureBar.barColor[1] == 201 / 255 and captureBar.barColor[2] == 180 / 255 and captureBar.barColor[3] == 0,
  "Progress bar does not use its original gold fill")
assert(captureProgress.backgroundColor[1] == .4 and captureProgress.blackBorder and captureBar.smoothed,
  "Progress bar lost its grey track, black border or smoothing")
local counterFound = false
for _, text in ipairs(visible("font")) do
  if text.parent == captureBar then
    counterFound = text.fontSize == 14 and text.fontFlags == "OUTLINE" and text.text == "2/2" and text.textColor[1] == 1
  end
end
assert(counterFound, "Progress counter does not use its old white outlined style")
captureProgress.scripts.OnUpdate(captureProgress, .25)
assert(captureBar:IsShown() and captureProgress.alpha == .75, "Capture progress does not fade on completion")
captureProgress.scripts.OnUpdate(captureProgress, .75)
assert(not captureBar:IsShown(), "Completed capture bar does not finish fading")
local notesSurface = notes.parent.parent
assert(notesSurface.point[5] == -98 and notesSurface:GetHeight() == 225,
  "Release notes are not laid out below their editing instructions")
assert(notes:HasFocus() and notesSurface.borderColor[1] == .76, "Notes editor does not show a focused editing state")
assert(notesSurface.backgroundColor[1] == .055 and nameEntry.backgroundColor[1] == .055,
  "Single-line and release-notes fields have different backgrounds")
assert(notes.fontFace == nameEntry.fontFace and notes.fontSize == nameEntry.fontSize
  and notes.highlightColor[1] == nameEntry.highlightColor[1], "Edit-box typography or selection styling differs")
local originalNotes = notes:GetText()
notes:ClearFocus()
assert(notesSurface.borderColor[1] == .45)
notes.mouseOver = true; notes.scripts.OnEnter(notes)
assert(notesSurface.borderColor[1] == .65, "Notes editor has no hover affordance")
notes.mouseOver = false; notes.scripts.OnLeave(notes)
notesSurface.scripts.OnMouseDown(notesSurface)
assert(notes:HasFocus() and notesSurface.borderColor[1] == .76 and notes:GetText() == originalNotes,
  "Clicking the editor surface does not focus it or changes its contents")
local logo, warningCount, reminder = false, 0, false
for _, f in ipairs(visible("texture")) do
  if f.texture == [[Interface\AddOns\WagoUI\media\wagoLogo512]] then logo = true end
  if f.texture == [[Interface\DialogFrame\UI-Dialog-Icon-AlertNew]] then warningCount = warningCount + 1 end
end
for _, f in ipairs(visible("font")) do
  if f.text == "Continue the upload through the Wago App after the reload!" then reminder = true end
end
assert(logo and warningCount == 2 and reminder, "Save dialog lost its logo, warning icons or upload reminder")
closeDialog()
assert(not addon.db.creator.saved[pack.id], "Closing notes saved the pack")
click("Save All Profiles")
assert(notes:IsShown() and notes:GetText():find("## Updated / Added:", 1, true), "Cancelled release lost its generated notes")
local edited = "# My release\n\n- Edited notes\n- Second line"
notes:SetText(edited)
local beforeReload = reloads
local reloadAction = button("Save and Reload")
reloadAction.click()
assert(reloads == beforeReload + 1 and not notes:IsShown(), "Save did not reload immediately")
assert(not addon.state.busy)
addon:RefreshWorkspace() -- The headless ReloadUI stub does not recreate the UI.
pack = addon.db.creator.packs[pack.id]
assert(addon.db.creator.saved[pack.id].releaseNotes[tostring(pack.updatedAt)] == edited, "Edited release notes not saved")
assert(pack.profiles[id].data)
assert(profileSelectors()[1].tooltip:find("Last save:", 1, true), "Saved timestamp missing from dropdown tooltip")
click("Save All Profiles")
assert(not notes:IsShown() and addon.state.notice == "No Changes detected", "Unchanged pack opens notes")
pack = addon.db.creator.packs[pack.id]
local exportBeforeWarning = modules.Test.exportProfile
modules.Test.exportProfile = function() return nil, false end
local draftBeforeFailure = addon.db.creator.packs[pack.id]
click("Save All Profiles")
assert(not notes:IsShown() and hasText("Couldn't save"), "A failed export opened the release notes instead of stopping")
local exportWarning = false
for _, f in ipairs(visible("font")) do
  if (f.text or ""):find("Test / ", 1, true) and (f.text or ""):find("Export failed.", 1, true) then exportWarning = true end
end
assert(exportWarning, "Couldn't save does not list the failed profile")
assert(addon.db.creator.packs[pack.id] == draftBeforeFailure and draftBeforeFailure.profiles[id].data, "A failed save changed the draft")
click("Okay")
modules.Test.exportProfile = exportBeforeWarning
pack = addon.db.creator.packs[pack.id]
-- A profile whose source is gone is marked on its row and blocks Save All, until it keeps its last capture.
local keysBeforeProblem = modules.Test.getProfileKeys
modules.Test.getProfileKeys = function() return {} end
addon:RefreshWorkspace()
local problemSave = findButton("Save All Profiles")
assert(problemSave.enabled == false, "Save All Profiles allows a profile that cannot be saved")
local problemBlocker
for _, f in ipairs(visible("Frame")) do
  if f.parent == problemSave.parent and (f.tooltip or ""):find("Fix the marked profiles before saving.", 1, true) then problemBlocker = f end
end
assert(problemBlocker and problemBlocker.tooltip:find("Can't be saved: Test", 1, true), "Blocked save does not explain the problem")
local problemRows = profileSelectors()
assert(#warningIcons() == #problemRows, "Every profile without a source must be marked")
for _, icon in ipairs(warningIcons()) do
  assert(icon.tooltip:find("no longer exists in Test. Pick another or remove it.", 1, true), "Problem row lacks an actionable message")
end
local keepTooltip = "Keep last capture\nShip the version you saved before until this profile can be saved again."
iconAt(keepTooltip, profileSelectors()[1]).click()
assert(pack.profiles[id].keepCapture and #warningIcons() == #problemRows - 1, "Keeping the last capture did not clear the problem")
assert(findButton("Save All Profiles").enabled == false, "Save All allowed the remaining problem")
for index = 2, #problemRows do iconAt(keepTooltip, profileSelectors()[index]).click() end
assert(#warningIcons() == 0 and button("Save All Profiles"), "Save All stayed blocked after keeping every last capture")
local locks = 0
for _, f in ipairs(visible("Frame")) do
  if (f.tooltip or ""):find("^Ships its last capture") and f.tooltip:find("no longer exists in Test", 1, true) then locks = locks + 1 end
end
assert(locks == #problemRows, "Kept profiles do not say why they ship their last capture")
modules.Test.getProfileKeys = keysBeforeProblem
addon:RefreshWorkspace()
for index = 1, #problemRows do iconAt("Stop keeping the last capture", profileSelectors()[index]).click() end
for _, p in pairs(pack.profiles) do assert(not p.keepCapture, "Could not stop keeping the last capture") end
-- A profile name most players already have is marked on its row, but does not block saving.
local sourceBeforeName = pack.profiles[id].sourceKey
modules.Test.getProfileKeys = function() return { Raid = true, Other = true, Default = true } end
pack.profiles[id].sourceKey = "Default"
addon:RefreshWorkspace()
assert(#warningIcons() == 1 and warningIcons()[1].tooltip == "Shared name", "Shared profile name is not marked")
assert(findButton("Save All Profiles").enabled ~= false, "A shared profile name blocks Save All")
pack.profiles[id].sourceKey = sourceBeforeName
modules.Test.getProfileKeys = keysBeforeProblem
addon:RefreshWorkspace()
assert(#warningIcons() == 0, "Renamed profile is still marked")
local headings = { Options = true, AddOn = true, Profile = true, Variations = true, Status = true }
for _, f in ipairs(visible("font")) do assert(not headings[f.text], "Column header remains: " .. tostring(f.text)) end
for _, f in ipairs(visible("button")) do
  assert(headings[f.text] == nil and not (f.tooltip or ""):find("Sort by", 1, true), "Clickable sorting header remains")
end
local orderedSelectors = {}
for _, f in ipairs(visible("dropdown")) do if f.moduleName then table.insert(orderedSelectors, f) end end
-- Cooldown Manager is managed through its own button instead of a profile dropdown.
for _, f in ipairs(visible("button")) do
  if f.tooltip == "Choose Cooldown Manager profiles to include" then
    table.insert(orderedSelectors, { moduleName = "Blizzard Cooldown Manager", point = f.point })
  end
end
table.sort(orderedSelectors, function(a, b) return a.point[5] > b.point[5] end)
local displayed, last = {}, nil
for _, f in ipairs(orderedSelectors) do
  if last ~= f.moduleName then table.insert(displayed, f.moduleName); last = f.moduleName end
end
for index, info in ipairs(addon:CreatorAddons()) do
  assert(displayed[index] == info.name, "Creator no longer follows automatic status/default order")
end
for _, f in ipairs(visible("button")) do assert(f.text ~= "Preview", "Creator preview button remains") end
click("Back to UI Packs")
local function buttonStarting(prefix)
  for _, f in ipairs(visible("button")) do if (f.text or ""):find(prefix, 1, true) == 1 then return f end end
end
if buttonStarting("Review everything instead") then click("Review everything instead") end
for _, f in ipairs(frames) do
  if f.visible and f.onClick and f.name and f.name.text == "Compact" then f.onClick() end
end
click("Next >>")
buttonStarting("Install (").click()
click("Individual Profiles")
click("Re-import")
click("Create your own UI Pack")
assert(#profileSelectors() == 2)
for _, f in ipairs(visible("button")) do assert(f.text ~= "Capture" and f.text ~= "Copy", "Removed profile actions remain") end
local search = visible("EditBox")[1]
search:SetText("no matching addons")
search.scripts.OnTextChanged(search, true)
local listTextures = 0
for _, f in ipairs(visible("texture")) do
  if f.parent.parent and f.parent.parent.kind == "ScrollFrame" then listTextures = listTextures + 1 end
end
assert(#visible("addonIcon") == 0 and listTextures == 0, "Filtered rows leave icons/backgrounds behind")
assert(hasText('Nothing matches "no matching addons"'), "Empty search result has no explanation")
search:SetText("")
search.scripts.OnTextChanged(search, true)
assert(#visible("addonIcon") > 0, "Rows did not return after clearing search")
local count = #frames
for _ = 1, 20 do addon:RefreshWorkspace() end
assert(#frames == count, "Redraw leaks widgets")
local savedLoaded, savedUpdated = modules.Test.isLoaded, modules.Test.isUpdated
local lap = LibStub("LibAddonProfiles")
local savedCanEnable = lap.CanEnableAnyAddOn
modules.Test.isLoaded = function() return false end
modules.Test.isUpdated = function() error("Unloaded addon version was queried by creator UI") end
addon:RefreshWorkspace()
assert(hasText("AddOn disabled - click to enable"))
checkRowHover(profileSelectors()[1], false)
for _, f in ipairs(visible("font")) do
  if f.text == "Test" then
    assert(f.textColor[1] == .5, "Disabled addon name is not grey")
    assert(f.fontSize == 16 and f.point[4] == 56 and f.point[5] == profileSelectors()[1].point[5] - 1,
      "Addon name with a status is not top-aligned")
  end
  if f.text == "AddOn disabled - click to enable" then
    assert(f.justifyH == "LEFT" and f.fontSize == 10 and f.textColor[1] == .6 and f.textColor[2] == .6 and f.textColor[3] == .6,
      "Status must remain small grey text under the addon name")
    assert(f.point[4] == 56 and f.point[5] == profileSelectors()[1].point[5] - 21,
      "Status is not the second line under the addon name")
  end
end
for _, f in ipairs(visible("button")) do assert(f.text ~= "Addon disabled", "Styled status button remains") end
local clickedStatus = false
for _, hit in ipairs(visible("Button")) do
  if hit.point and hit.point[5] == profileSelectors()[1].point[5] + 6 and hit:GetWidth() == 288 then
    hit.scripts.OnClick(hit); clickedStatus = true; break
  end
end
assert(clickedStatus and hasText("Enabled after reload"), "Plain status row lost its enable action")
assert(addon.state.needReload)
addon.state.creatorEnabled = nil
lap.CanEnableAnyAddOn = function() return false end
addon:RefreshWorkspace()
assert(not hasText("Not installed") and #profileSelectors() == 0, "Missing addon is visible by default")
local showMissing
for _, row in ipairs(visible("Button")) do
  if row.label and row.label.text == "+  Show AddOns that are not installed" then showMissing = row end
end
assert(showMissing and showMissing:GetWidth() == showMissing.parent:GetWidth() - 8 and showMissing:GetHeight() == 44,
  "Show uninstalled addons must be a full-width row")
assert(showMissing.plate.point[1] == "CENTER" and showMissing.line:GetWidth() == showMissing:GetWidth(),
  "Reveal action must be centered over a full-width divider")
showMissing.scripts.OnEnter(showMissing)
assert(showMissing.plate.backgroundColor[1] == .18 and showMissing.label.textColor[1] == 1)
showMissing.scripts.OnLeave(showMissing)
assert(showMissing.plate.backgroundColor[1] == .1)
for _, selector in ipairs(visible("dropdown")) do
  if selector.moduleName then assert(showMissing.point[5] < selector.point[5], "Show missing addons is not the last list entry") end
end
search:SetText("Test"); search.scripts.OnTextChanged(search, true)
assert(hasText("Not installed") and #profileSelectors() == 2, "Search did not include matching uninstalled addons")
search:SetText(""); search.scripts.OnTextChanged(search, true)
assert(not hasText("Not installed"), "Clearing search did not hide uninstalled addons again")
showMissing.scripts.OnClick(showMissing)
assert(hasText("Not installed") and #profileSelectors() == 2, "Show uninstalled addons did not reveal their profiles")
assert(showMissing:IsShown() and showMissing.label.text == "-  Hide AddOns that are not installed",
  "Reveal row did not become a hide action")
for _, selector in ipairs(visible("dropdown")) do
  if selector.moduleName then assert(showMissing.point[5] < selector.point[5], "Hide missing addons is not the last list entry") end
end
for _, control in ipairs(visible("button")) do assert(control.text ~= "Show AddOns that are not installed") end
checkRowHover(profileSelectors()[1], false)
showMissing.scripts.OnClick(showMissing)
assert(not hasText("Not installed") and #profileSelectors() == 0, "Hide action did not hide uninstalled addons")
assert(showMissing:IsShown() and showMissing.label.text == "+  Show AddOns that are not installed",
  "Hide action did not restore the show action")
search:SetText("Test"); search.scripts.OnTextChanged(search, true)
assert(hasText("Not installed") and #profileSelectors() == 2, "Hiding uninstalled addons excluded them from search")
search:SetText(""); search.scripts.OnTextChanged(search, true)
modules.Test.isLoaded = savedLoaded
modules.Test.isUpdated = function() return false end
addon:RefreshWorkspace()
assert(hasText("Outdated - update required"))
for _, f in ipairs(visible("font")) do
  if f.text == "Test" then assert(f.textColor[1] == .95, "Enabled outdated addon name is not white") end
end
for _, selector in ipairs(profileSelectors()) do assert(not selector.enabled, "Outdated addon permits source selection") end
assert(#pack.profileOrder == 2, "Unavailable addon lost its saved profiles")
modules.Test.isUpdated, lap.CanEnableAnyAddOn = savedUpdated, savedCanEnable
addon:RefreshWorkspace()
local alternateID = profileSelectors()[2].profileRow.profileID
local clearedTags = CopyTable(pack.profiles[profileSelectors()[1].profileRow.profileID].variations)
iconAt("Clear selected profile", profileSelectors()[1]).click()
assert(#profileSelectors() == 2 and not profileSelectors()[1].profileRow.profileID,
  "Clearing the main profile removed its row or promoted its alternate")
assert(not profileSelectors()[1].tooltip, "Unselected profile still shows a tooltip")
assert(pack.profiles[alternateID], "Clearing the main profile removed the alternate")
addon:InitializePacks(); addon:RefreshWorkspace()
assert(not profileSelectors()[1].profileRow.profileID, "Blank main row did not persist")
selectSource(profileSelectors()[1], "Other")
assert(not profileSelectors()[1].profileRow.profileID and #pack.profileOrder == 1,
  "Duplicate source selection was accepted")
selectSource(profileSelectors()[1], "Raid")
local replacementID = profileSelectors()[1].profileRow.profileID
for tag in pairs(clearedTags) do
  assert(replacementID and pack.profiles[replacementID].variations[tag], "Clearing the main profile reset its variations")
end
addon.Packs.SetMembership(pack, replacementID, { default = true })
addon:RefreshWorkspace()
iconAt("Remove alternate profile", profileSelectors()[2]).click()
assert(#profileSelectors() == 1 and not pack.profiles[alternateID], "Remove did not delete the alternate row")
pack.profiles[replacementID].data, pack.profiles[replacementID].lastUpdatedAt = "old-payload", 10
selectSource(profileSelectors()[1], "Other")
assert(not pack.profiles[replacementID].data and not pack.profiles[replacementID].lastUpdatedAt,
  "Changing the source retained the old profile's captured payload")
assert(profileSelectors()[1].tooltip == "Not saved yet")
pack.profiles[replacementID].lastSavedAt = "invalid"
assert(not addon.Packs.Validate(pack), "Invalid save timestamp was accepted")
pack.profiles[replacementID].lastSavedAt = nil
-- Variation tabs show either every variation or exactly one.
local tabs = variationTabs()
assert(#tabs == #pack.variationOrder + 2 and tabs[1].label.text == "All" and tabs[1].active, "All tab is missing or inactive")
assert(tabs[#tabs].label.text == "+ Add variation", "Add variation is not the last tab")
assert(tabs[1].count.text == tostring(#pack.profileOrder) and not tabs[1].swatch:IsShown())
for index, variationID in ipairs(pack.variationOrder) do
  local tab = tabs[index + 1]
  assert(tab.label.text == pack.variations[variationID].name and tab.swatch:IsShown(), "Variation tab is missing")
  assert(tab.count.text == tostring(#addon.Packs.Profiles(pack, variationID)), "Variation tab count is wrong")
end
for index = 2, #tabs do
  assert(tabs[index].point[4] >= tabs[index - 1].point[4] + tabs[index - 1]:GetWidth(), "Variation tabs overlap")
end
openTab(4)
assert(variationTabs()[4].active and not variationTabs()[1].active, "Clicked tab is not active")
assert(#profileSelectors() == 0, "Variation tab shows addons without a profile in it")
openTab(1)
iconAt("Add alternate profile", profileSelectors()[1]).click()
chipFor(profileSelectors()[2], "Raid alternate").click()
selectSource(profileSelectors()[2], "Raid")
local tabProfile = profileSelectors()[2].profileRow
assert(tabProfile.profileID, "Picking a profile did not keep its row")
local tabTags = pack.profiles[tabProfile.profileID].variations
assert(tabTags[raidAlternate] and not tabTags.default, "Profile picked in a variation tab joined the wrong variations")
openTab(1)
assert(#profileSelectors() == 2, "All tab does not show every row")
openTab(2)
assert(#profileSelectors() == 1 and profileSelectors()[1].profileRow.profileID == replacementID,
  "Default tab shows rows from another variation")
openTab(1)
search:SetText("raid alt"); search.scripts.OnTextChanged(search, true)
assert(#profileSelectors() == 1 and profileSelectors()[1].profileRow == tabProfile, "Search does not match variation names")
local clearSearch
for _, f in ipairs(visible("Button")) do if f.cross and f.parent == search then clearSearch = f end end
assert(clearSearch, "Search has no clear button")
clearSearch.scripts.OnClick(clearSearch)
assert(search.text == "" and #profileSelectors() == 2 and not clearSearch:IsShown(), "Clearing search did not restore rows")
iconAt("Remove alternate profile", profileSelectors()[2]).click()
assert(#pack.profileOrder == 1)
-- Check every curated palette against its actual normal and hover backgrounds.
local tags = { default = true }
for index = 1, 5 do
  local variation = addon.Packs.SaveVariation(pack, nil, "Palette " .. index, nil, "")
  tags[variation] = true
end
addon.Packs.SetMembership(pack, replacementID, tags)
addon:RefreshWorkspace()
local wrapped = profileSelectors()[1]
local lastChip = chipFor(wrapped, "Palette 5")
assert(lastChip.point[5] < wrapped.point[5] - 3 and lastChip.point[4] + lastChip:GetWidth() <= 826,
  "Many variations do not wrap inside the variation column")
local function luminance(color)
  local function linear(value) return value <= .04045 and value / 12.92 or ((value + .055) / 1.055) ^ 2.4 end
  return linear(color[1]) * .2126 + linear(color[2]) * .7152 + linear(color[3]) * .0722
end
local minimumContrast, checked = math.huge, 0
for _, chip in ipairs(visible("button")) do
  if chip.variationID then
    assert(not chip.tooltip and not chip.scripts.OnEnter,
      "Variation chips still show tooltips")
    for _, plainButton in ipairs(chip.parent.pools.button or {}) do
      assert(plainButton ~= chip, "Variation styling can leak into a reused plain button")
    end
    chip.ShowTooltip = function() end
    for _, event in ipairs({ "OnEnter", "OnLeave" }) do
      chip.mouseOver, chip.parent.parent.mouseOver = event == "OnEnter", event == "OnEnter"
      chip.scripts.OnUpdate()
      local foreground, background = luminance(chip.text_overlay.textColor), luminance(chip.backgroundColor)
      local ratio = (math.max(foreground, background) + .05) / (math.min(foreground, background) + .05)
      minimumContrast = math.min(minimumContrast, ratio)
      assert(ratio >= 4.5, "Chip text fails minimum contrast")
    end
    checked = checked + 1
  end
end
assert(checked >= 6)
print(string.format("Variation chip contrast: %.2f:1 minimum across normal/hover states.", minimumContrast))
local deletePrompt
function addon:ShowPrompt(_, yes) deletePrompt = yes end
packSelector().options()[1].delete()
assert(addon.db.creator.packs[pack.id], "Dropdown deleted without confirmation")
deletePrompt()
assert(not addon.db.creator.packs[pack.id])
for _, f in ipairs(visible("dropdown")) do assert(not f.enabled, "Deleting the last pack left the selector unlocked") end
-- Rebuild the workspace with only persisted database values, as after /reload.
local function reopenWorkspace()
  addon.frames.mainFrame:Hide()
  addon.db = CopyTable(addon.db)
  loadWorkspace()
  addon.frames.mainFrame = new("root")
  addon:CreateWorkspace(addon.frames.mainFrame)
end
assert(addon.db.workspaceMode == "create")
reopenWorkspace()
button("Back to UI Packs") -- Still in creator mode, including with no created packs.
click("Back to UI Packs")
assert(addon.db.workspaceMode == "install")
reopenWorkspace()
button("Create a UI Pack") -- With no UI Pack anywhere, the welcome screen offers creating one.
addon.db.workspaceMode = "unknown"
reopenWorkspace()
assert(addon.db.workspaceMode == "install", "Invalid stored mode must fall back to user mode")
print("Creator, variation editing, capture, wizard and expert UI smoke checks passed.")
