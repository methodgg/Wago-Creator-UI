---@type string
local addonName = ...
---@class WagoUI
local addon = select(2, ...)
local L = addon.L
local Controls = addon.Controls

local TITLE = "|cFFC1272DWago|r UI Packs"

-- The title names the current view and the slash command that opens it.
function addon:SetTitle(creating)
  self.frames.mainFrame.Title:SetText((creating and "Create " or "Install ") .. TITLE .. " - slash command: "
    .. (creating and "/wagoc" or self.slashPrefixes[1]))
end

function addon:CreateMainFrame()
  local metaVersion = C_AddOns.GetAddOnMetadata(addonName, "Version")

  local frame = CreateFrame("Frame", addonName .. "Frame", UIParent, "BackdropTemplate")
  frame:Hide()
  frame:SetSize(addon.ADDON_WIDTH, addon.ADDON_HEIGHT)
  frame:SetFrameStrata("HIGH")
  frame:SetFrameLevel(100)
  frame:SetToplevel(true)
  frame:SetClampedToScreen(true)
  frame:EnableMouse(true)
  frame:SetMovable(true)
  -- Escape closes the window.
  table.insert(UISpecialFrames, frame:GetName())
  Controls.Backdrop(frame)
  frame.surface:SetAlpha(1)
  Controls.Border(frame)
  Controls.ScaleToScreen(frame)
  frame:SetPoint(addon.db.anchorTo, UIParent, addon.db.anchorFrom, addon.db.xoffset, addon.db.yoffset)
  -- Dragging anywhere on the window moves it, and it reopens where it was left.
  frame:SetScript("OnMouseDown", function(self, mouseButton)
    if mouseButton ~= "LeftButton" or self.isMoving then return end
    self.isMoving = true
    self:StartMoving()
  end)
  frame:SetScript("OnMouseUp", function(self)
    if not self.isMoving then return end
    self.isMoving = false
    self:StopMovingOrSizing()
    local from, _, to, x, y = self:GetPoint(1)
    addon.db.anchorFrom, addon.db.anchorTo = from, to
    addon.db.xoffset, addon.db.yoffset = x, y
  end)

  local titleBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -3)
  titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -3)
  titleBar:SetHeight(30)
  titleBar:SetBackdrop({ bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], edgeFile = [[Interface\Buttons\WHITE8X8]],
    edgeSize = 1, tileSize = 64, tile = true })
  titleBar:SetBackdropColor(.2, .2, .2, 1)
  titleBar:SetBackdropBorderColor(0, 0, 0, 1)

  frame.Title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.Title:SetFont(addon.FONT, 20, "")
  frame.Title:SetTextColor(.8, .8, .8, 1)
  frame.Title:SetPoint("CENTER", titleBar, "CENTER", 0, 1)
  frame.Title:SetText(TITLE)

  local close = CreateFrame("Button", nil, titleBar)
  close:SetFrameLevel(750)
  close:SetSize(16, 16)
  for _, state in ipairs({ "Normal", "Highlight", "Pushed" }) do
    close["Set" .. state .. "Texture"](close, [[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
    close["Get" .. state .. "Texture"](close):SetDesaturated(true)
  end
  close:SetAlpha(.7)
  close:SetPoint("RIGHT", titleBar, "RIGHT", -2, 0)
  close:SetScript("OnClick", function() frame:Hide() end)

  local versionString = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  versionString:SetTextColor(.8, .8, .8, 1)
  versionString:SetText("v" .. metaVersion)
  versionString:SetPoint("LEFT", titleBar, "LEFT", 2, 0)

  local reloadIndicator = Controls.IconButton(frame, 40, "UI-RefreshButton")
  reloadIndicator:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -38)
  reloadIndicator:SetTooltip(L["IMPORT_RELOAD_WARNING1"])
  reloadIndicator:SetFrameStrata("DIALOG")
  reloadIndicator:Hide()
  reloadIndicator.onClick = Controls.Reload()

  function addon:ToggleReloadIndicator(show, text)
    if show then
      reloadIndicator:Show()
    else
      reloadIndicator:Hide()
    end
    reloadIndicator:SetTooltip(text or L["IMPORT_RELOAD_WARNING1"])
  end

  local autoStartCheckbox = Controls.Checkbox(frame, 25)
  autoStartCheckbox:SetChecked(addon.db.autoStart)
  autoStartCheckbox.onToggle = function(checked) addon.db.autoStart = checked end
  autoStartCheckbox:SetPoint("TOPLEFT", frame, "TOPRIGHT", 10, 0)
  autoStartCheckbox:Hide()

  local resetButton = Controls.Button(frame, 60, 40, "RESET", 16)
  resetButton:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, -30)
  resetButton.onClick = addon.ShowAddonResetPrompt
  resetButton:Hide()

  local forceErrorButton = Controls.Button(frame, 120, 40, "Force Error", 16)
  forceErrorButton:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, -80)
  forceErrorButton.onClick = addon.TestErrorHandling
  forceErrorButton:Hide()

  if addon.db.debug then
    autoStartCheckbox:Show()
    resetButton:Show()
    forceErrorButton:Show()
  end

  addon.frames.mainFrame = frame

  hooksecurefunc(
    frame,
    "Hide",
    function()
      local promptFunc = function(promptText, successCallback, cancelCallback, okayText, cancelText)
        C_Timer.After(
          0.1,
          function()
            frame:Show()
            addon:ShowPrompt(promptText, successCallback, cancelCallback, okayText, cancelText)
          end
        )
      end
      local cancelFunc = function()
        addon.state.needReload = false
      end
      --some profile imports close this frame as it is added to UISpecialFrames so we need to reopen it
      if addon.state.isImporting then
        addon.state.needReopen = true
        return
      end
      if addon.state.needReload and not addon.state.besideCooldownManager then
        promptFunc(L["IMPORT_RELOAD_WARNING2"], Controls.Reload(), cancelFunc, L["Reload UI"], L["Cancel"])
      end
    end
  )

  addon:ApplyFont(frame)
  return frame
end
