-- Empty states and the calls to action that lead people into creating a UI Pack.
local addon = select(2, ...)
local UI = addon.UI
local ui = UI.view
local label, reset, widget = UI.label, UI.reset, UI.widget
local ctaButton = UI.ctaButton
local function render() UI.render() end

local RED = addon.colorRGB
local WHITE = [[Interface\Buttons\WHITE8X8]]

local function card(parent, x, y, width, height, accent)
  local f = widget(parent, "card", function()
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    frame:SetBackdropColor(.1, .1, .1, 1)
    frame:SetBackdropBorderColor(.22, .22, .22, 1)
    frame.accent = frame:CreateTexture(nil, "ARTWORK")
    frame.accent:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    frame.accent:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    frame.accent:SetHeight(3)
    return frame
  end)
  reset(f)
  f:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
  f:SetSize(width, height)
  f.accent:SetColorTexture(unpack(accent))
  return f
end

-- A numbered step: badge and a short instruction.
local function step(parent, number, x, y, width, title)
  local badge = widget(parent, "stepBadge", function()
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    frame:SetBackdropColor(RED[1], RED[2], RED[3], .2)
    frame:SetBackdropBorderColor(RED[1], RED[2], RED[3], 1)
    frame:SetSize(24, 24)
    frame.number = frame:CreateFontString(nil, "OVERLAY")
    frame.number:SetFont(addon.FONT, 13, "")
    frame.number:SetPoint("CENTER", 0, -1)
    return frame
  end)
  badge:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
  badge.number:SetText(tostring(number))
  label(parent, title, x + 36, y + 4, width - 36, 15, { .95, .95, .95 })
end

-- Opens creator mode; without a UI Pack of its own the creator stays locked until one is created.
local function enterCreator()
  addon.db.workspaceMode = "create"
  ui.scroll:SetVerticalScroll(0)
  render()
end

-- Nothing installed and nothing created yet: offer both ways in, side by side.
local function welcome(body)
  local logo = widget(body, "welcomeLogo", function() return body:CreateTexture(nil, "ARTWORK") end)
  logo:SetTexture([[Interface\AddOns\WagoUI\media\wagoLogo512]])
  logo:SetSize(64, 64)
  logo:SetPoint("TOP", body, "TOP", 0, 0)
  label(body, "Welcome to WagoUI", 0, 74, body:GetWidth(), 26):SetJustifyH("CENTER")
  local width, gap = 422, 26
  local x = (body:GetWidth() - (2 * width + gap)) / 2
  local install = card(body, x, 124, width, 310, { .45, .45, .45, 1 })
  label(install, "Install a UI Pack", 24, 26, width - 48, 20)
  step(install, 1, 24, 70, width - 48, "Find a UI Pack you like on the Wago website")
  step(install, 2, 24, 112, width - 48, "Install it with the Wago App")
  step(install, 3, 24, 154, width - 48, "Come back here to set it up")
  local note = label(install, "Installed UI Packs show up here automatically.", 24, 254, width - 48, 13, { .55, .55, .55 })
  note:SetJustifyH("CENTER")
  local create = card(body, x + width + gap, 124, width, 310, { RED[1], RED[2], RED[3], 1 })
  label(create, "Create your own UI Pack", 24, 26, width - 48, 20)
  step(create, 1, 24, 70, width - 48, "Pick the AddOn profiles that make up your UI")
  step(create, 2, 24, 112, width - 48, "Save them all with one click")
  step(create, 3, 24, 154, width - 48, "Upload with the Wago App to share it")
  ctaButton(create, "Create a UI Pack", 24, 238, width - 48, 48, enterCreator, "primary", 20)
  body:SetHeight(444)
end

UI.enterCreator = enterCreator
UI.welcome = welcome
