-- Creator dialogs: release notes, additional addons, export options and first-time setup.
local addon = select(2, ...)
local LAP = LibStub("LibAddonProfiles")
local UI = addon.UI
local button, check, label, rowBackground, scroll = UI.button, UI.check, UI.label, UI.rowBackground, UI.scroll
local widget = UI.widget
local closeModal, modal, modalList, notice, safely = UI.closeModal, UI.modal, UI.modalList, UI.notice, UI.safely
local textDialog = UI.textDialog
local function render() UI.render() end

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
  -- Blocked WeakAuras are chosen in the WeakAuras manager.
  content:SetHeight(math.max(1, y))
  button(f, "Save", 424, 476, 150, function()
    pack.exportOptions = pack.exportOptions or {}
    pack.exportOptions[moduleName] = options
    pack.revision = pack.revision + 1
    closeModal(); render()
  end)
end

local function startSetup()
  textDialog("New UI pack", "", "Create", function(value) addon:NewPack(value) end)
end

UI.additionalAddons = additionalAddons
UI.exportOptions = exportOptions
UI.saveCapture = saveCapture
UI.startSetup = startSetup
UI.wagoAddons = wagoAddons
