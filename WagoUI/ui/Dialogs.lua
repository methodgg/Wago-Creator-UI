-- Creator dialogs: release notes, additional addons, export options and first-time setup.
local addon = select(2, ...)
local LAP = LibStub("LibAddonProfiles")
local UI = addon.UI
local button, check, label, rowBackground, scroll = UI.button, UI.check, UI.label, UI.rowBackground, UI.scroll
local widget = UI.widget
local closeModal, modal, modalList, notice, safely = UI.closeModal, UI.modal, UI.modalList, UI.notice, UI.safely
local textDialog = UI.textDialog
local function render() UI.render() end

-- A capture with failed exports saved nothing; list what failed so the creator can fix it and save again.
local function captureFailed(issues)
  local f = modal("Couldn't save", 600, 420)
  label(f, "Nothing was saved. Fix these profiles, then save again.", 24, 58, 552, 14, { .8, .8, .8 })
  f.scroll:ClearAllPoints()
  f.scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -90)
  local content = modalList(f, 250)
  local y = 0
  for _, issue in ipairs(issues) do
    local line = label(content, issue, 0, y, 526, 13, { 1, .65, .3 })
    line:SetWordWrap(true)
    y = y + line:GetStringHeight() + 8
  end
  content:SetHeight(math.max(1, y))
  button(f, addon.L["Okay"], 446, 360, 130, closeModal)
end

local function saveCapture(pack, changes, issues)
  if #issues > 0 then captureFailed(issues); return end
  local generated, changed = addon:BuildReleaseNotes(pack)
  if not changed then notice("No Changes detected"); return end
  local f = modal("Release Notes", 600, 560)
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
  local logo = widget(f, "saveLogo", function() return f:CreateTexture(nil, "ARTWORK") end)
  logo:SetTexture([[Interface\AddOns\WagoUI\media\wagoLogo512]])
  logo:SetSize(128, 128)
  logo:SetPoint("TOP", f, "TOP", 0, -336)
  label(f, "Continue the upload through the Wago App after the reload!", 58, 476, 484, 16):SetJustifyH("CENTER")
  for _, x in ipairs({ 24, 546 }) do
    local warning = widget(f, "saveWarning", function() return f:CreateTexture(nil, "OVERLAY") end)
    warning:SetTexture([[Interface\DialogFrame\UI-Dialog-Icon-AlertNew]])
    warning:SetSize(30, 30)
    warning:SetPoint("TOPLEFT", f, "TOPLEFT", x, -468)
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
  button(f, "Save and Reload", 200, 504, 200, save, "Write SavedVariables for the Wago App", 40, 16, "saveReload")
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

-- A centred card on its own, outside the main window, so it shows whether or not WagoUI opens after the reload.
function addon:ShowAppHandoff()
  local WHITE, RED, width = [[Interface\Buttons\WHITE8X8]], addon.colorRGB, 540
  local shade = CreateFrame("Frame", nil, UIParent)
  shade:SetAllPoints(UIParent)
  shade:SetFrameStrata("FULLSCREEN_DIALOG")
  shade:EnableMouse(true)
  shade.texture = shade:CreateTexture(nil, "BACKGROUND")
  shade.texture:SetAllPoints()
  shade.texture:SetColorTexture(0, 0, 0, .55)
  local f = CreateFrame("Frame", "WagoUIAppHandoff", shade, "BackdropTemplate")
  LibStub("LibWagoFramework"):ScaleFrameByUIParentScale(f, 0.5333333333333)
  f:SetPoint("CENTER", UIParent, "CENTER")
  f:SetFrameLevel(shade:GetFrameLevel() + 10)
  f:EnableMouse(true)
  f:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
  f:SetBackdropColor(.08, .08, .08, .98)
  f:SetBackdropBorderColor(.22, .22, .22, 1)
  local accent = f:CreateTexture(nil, "ARTWORK")
  accent:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
  accent:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
  accent:SetHeight(3)
  accent:SetColorTexture(RED[1], RED[2], RED[3], 1)
  local logo = f:CreateTexture(nil, "ARTWORK")
  logo:SetTexture([[Interface\AddOns\WagoUI\media\wagoLogo512]])
  logo:SetSize(56, 56)
  logo:SetPoint("TOP", f, "TOP", 0, -26)
  label(f, "Continue in the Wago App", 0, 94, width, 24):SetJustifyH("CENTER")
  local text = label(f, "Your profiles are saved. Switch to the Wago App and open Create & Upload to finish "
    .. "setting up your UI Pack.", 40, 132, width - 80, 15, { .75, .75, .75 })
  text:SetJustifyH("CENTER")
  text:SetWordWrap(true)
  local top = 132 + text:GetStringHeight() + 22
  -- The screenshot sits in the top 1024x360 of a power-of-two texture.
  local shotWidth = width - 64
  local shotHeight = math.floor(shotWidth * 360 / 1024)
  local frame = CreateFrame("Frame", nil, f, "BackdropTemplate")
  frame:SetPoint("TOPLEFT", f, "TOPLEFT", 31, -top)
  frame:SetSize(shotWidth + 2, shotHeight + 2)
  frame:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
  frame:SetBackdropBorderColor(.3, .3, .3, 1)
  local shot = frame:CreateTexture(nil, "ARTWORK")
  shot:SetTexture([[Interface\AddOns\WagoUI\media\wagoAppCreate]])
  shot:SetTexCoord(0, 1, 0, 360 / 512)
  shot:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
  shot:SetSize(shotWidth, shotHeight)
  local buttonTop = top + shotHeight + 2 + 26
  UI.ctaButton(f, addon.L["Okay"], (width - 200) / 2, buttonTop, 200, 40, function() f:Hide() end, "primary", 17)
  f:SetSize(width, buttonTop + 40 + 26)
  -- Escape closes it like Okay; either way it never shows again.
  table.insert(UISpecialFrames, "WagoUIAppHandoff")
  f:SetScript("OnHide", function()
    -- Still shown means an ancestor hid it (Alt+Z, a cinematic); it comes back with the UI.
    if f:IsShown() then return end
    addon.db.appHandoff = "done"
    shade:Hide()
  end)
  shade:Show()
end

UI.additionalAddons = additionalAddons
UI.exportOptions = exportOptions
UI.saveCapture = saveCapture
UI.startSetup = startSetup
UI.wagoAddons = wagoAddons
