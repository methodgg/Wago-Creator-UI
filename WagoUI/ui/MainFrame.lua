---@type string
local addonName = ...
---@class WagoUI
local addon = select(2, ...)
local DF = _G["DetailsFramework"]
local LWF = LibStub("LibWagoFramework")
local L = addon.L

function addon:CreateMainFrame()
  local metaVersion = C_AddOns.GetAddOnMetadata(addonName, "Version")

  local panelOptions = {
    DontRightClickClose = true,
    NoTUISpecialFrame = false,
    -- UseScaleBar = true, --disable for now might use it later on
    NoCloseButton = false
  }
  local addonTitle = "|cFFC1272DWago|r UI Packs"
  local frame =
      DF:CreateSimplePanel(
        UIParent,
        addon.ADDON_WIDTH,
        addon.ADDON_HEIGHT,
        addonTitle,
        addonName.."Frame",
        panelOptions,
        addon.db
      )
  frame:Hide()
  DF:ApplyStandardBackdrop(frame)
  DF:CreateBorder(frame, 1, 0, 0)
  frame:ClearAllPoints()
  frame:SetFrameStrata("HIGH")
  frame:SetFrameLevel(100)
  frame:SetToplevel(true)
  frame:SetClampedToScreen(true)
  LWF:ScaleFrameByUIParentScale(frame, 0.5333333333333)
  frame:SetPoint(addon.db.anchorTo, UIParent, addon.db.anchorFrom, addon.db.xoffset, addon.db.yoffset)
  hooksecurefunc(
    frame,
    "StopMovingOrSizing",
    function()
      local from, _, to, x, y = frame:GetPoint(nil)
      addon.db.anchorFrom, addon.db.anchorTo = from, to
      addon.db.xoffset, addon.db.yoffset = x, y
    end
  )
  frame.__background:SetAlpha(1)

  DF:SetFontSize(frame.Title, 20)
  frame.TitleBar:SetHeight(30)
  frame.Title:SetPoint("CENTER", frame.TitleBar, "CENTER", 0, 1)

  local versionString = frame.TitleBar:CreateFontString(addonName.."VersionString", "overlay", "GameFontNormalSmall")
  versionString:SetTextColor(.8, .8, .8, 1)
  versionString:SetText("v"..metaVersion)
  versionString:SetPoint("LEFT", frame.TitleBar, "LEFT", 2, 0)

  local logo = frame:CreateTexture(nil, "ARTWORK")
  logo:SetTexture([[Interface\AddOns\]] .. addonName .. [[\media\wagoLogo512]])
  logo:SetSize(100, 100)
  logo:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -34)

  local reloadIndicator = DF:CreateButton(frame, nil, 40, 40, "", nil, nil, "UI-RefreshButton", nil, nil, nil, nil)
  reloadIndicator:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -38)
  reloadIndicator:SetTooltip(L["IMPORT_RELOAD_WARNING1"])
  addon:UseWidgetTooltip(reloadIndicator)
  reloadIndicator:SetFrameStrata("DIALOG")
  reloadIndicator:Hide()
  reloadIndicator:SetClickFunction(
    function()
      ReloadUI()
    end
  )

  function addon:ToggleReloadIndicator(show, text)
    logo:SetShown(not show)
    if show then
      reloadIndicator:Show()
    else
      reloadIndicator:Hide()
    end
    reloadIndicator:SetTooltip(text or L["IMPORT_RELOAD_WARNING1"])
  end

  local autoStartCheckbox =
      LWF:CreateCheckbox(
        frame,
        25,
        function(_, _, value)
          addon.db.autoStart = value
        end,
        addon.db.autoStart
      )
  autoStartCheckbox:SetPoint("TOPLEFT", frame, "TOPRIGHT", 10, 0)
  autoStartCheckbox:Hide()

  local resetButton = LWF:CreateButton(frame, 60, 40, "RESET", 16)
  resetButton:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, -30)
  resetButton:SetClickFunction(addon.ShowAddonResetPrompt)
  resetButton:Hide()

  local forceErrorButton = LWF:CreateButton(frame, 120, 40, "Force Error", 16)
  forceErrorButton:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, -80)
  forceErrorButton:SetClickFunction(addon.TestErrorHandling)
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
      if addon.state.needReload then
        promptFunc(L["IMPORT_RELOAD_WARNING2"], ReloadUI, cancelFunc, L["Reload UI"], L["Cancel"])
      end
    end
  )

  addon:ApplyFont(frame)
  return frame
end
