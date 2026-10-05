-- The shared modal dialog plus error and notice feedback.
local addon = select(2, ...)
local UI = addon.UI
local ui = UI.view
local button, input, label, reset, widget = UI.button, UI.input, UI.label, UI.reset, UI.widget
local function render() UI.render() end

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

local function dangerButton(parent, text, x, y, width, onClick)
  local f = button(parent, text, x, y, width, onClick, nil, nil, nil, "dangerButton")
  f:SetBackdropColor(.55, .1, .12, 1)
  return f
end

UI.closeModal = closeModal
UI.dangerButton = dangerButton
UI.modal = modal
UI.modalList = modalList
UI.notice = notice
UI.safely = safely
UI.textDialog = textDialog
