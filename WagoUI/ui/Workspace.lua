-- Entry point: builds the workspace frames once and redraws the active view.
local addon = select(2, ...)
local DF = DetailsFramework
local Packs = addon.Packs
local UI = addon.UI
local ui = UI.view
local button, dropdown, input, label, reset, scroll = UI.button, UI.dropdown, UI.input, UI.label, UI.reset, UI.scroll
local textDialog = UI.textDialog
local startSetup = UI.startSetup
local creator = UI.creator
local install = UI.install

local function render()
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

UI.render = render
