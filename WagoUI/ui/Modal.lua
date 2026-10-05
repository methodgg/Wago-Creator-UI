-- The shared modal dialog plus error and notice feedback.
local addon = select(2, ...)
local UI = addon.UI
local ui = UI.view
local button, ctaButton, input, label, reset = UI.button, UI.ctaButton, UI.input, UI.label, UI.reset
local widget = UI.widget
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

-- Closing a dialog by any means runs its onClose, so a prompt's × counts as cancelling it.
local function closeModal()
  local onClose = ui.modal.onClose
  ui.modal.onClose = nil
  ui.modal:Hide()
  ui.modalShade:Hide()
  if onClose then onClose() end
end

local function modal(title, width, height)
  width, height = width or 600, height or 524
  local f = ui.modal
  f.onClose = nil
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

-- The one confirmation style: an optional title, a warning icon with the message and grey details below it,
-- then cancel on the left and the confirming action on the right. Sizes itself to the text.
local function confirm(options)
  local width = 440
  local f = modal(options.title or "", width, 400)
  f.error:Hide()
  local top = options.title and 68 or 28
  local alert = widget(f, "confirmAlert", function() return f:CreateTexture(nil, "ARTWORK") end)
  alert:SetTexture([[Interface\DialogFrame\UI-Dialog-Icon-AlertNew]])
  alert:SetSize(32, 32)
  alert:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -top)
  local message = label(f, options.message, 70, top, width - 94, 16)
  message:SetWordWrap(true)
  local bottom = top + message:GetStringHeight()
  if options.details then
    local details = label(f, options.details, 70, bottom + 8, width - 94, 14, { .6, .6, .6 })
    details:SetWordWrap(true)
    bottom = bottom + 8 + details:GetStringHeight()
  end
  local buttons = math.max(top + 32, bottom) + 28
  f:SetHeight(buttons + 36 + 24)
  ctaButton(f, options.cancelText or addon.L["Cancel"], 24, buttons, 150, 36, closeModal, "neutral", 15)
  ctaButton(f, options.confirmText or addon.L["Okay"], 196, buttons, 220, 36, function()
    f.onClose = nil
    closeModal()
    if options.onConfirm then options.onConfirm() end
  end, "primary", 15)
  f.onClose = options.onCancel
  return f
end

-- Every prompt in the addon uses the confirmation dialog: the first line is the message, the rest details.
function addon:ShowPrompt(text, onConfirm, onCancel, confirmText, cancelText)
  local message, details = tostring(text):match("^([^\n]*)\n?(.*)$")
  confirm({ message = message, details = details ~= "" and details or nil, onConfirm = onConfirm, onCancel = onCancel,
    confirmText = confirmText, cancelText = cancelText })
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
UI.confirm = confirm
UI.dangerButton = dangerButton
UI.modal = modal
UI.modalList = modalList
UI.notice = notice
UI.safely = safely
UI.textDialog = textDialog
