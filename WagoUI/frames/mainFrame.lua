local addonName, addon = ...;
local DF = _G["DetailsFramework"];
local L = addon.L

function addon:CreateMainFrame()
  local metaVersion = C_AddOns.GetAddOnMetadata(addonName, "Version");

  local panelOptions = {
    DontRightClickClose = true,
    NoTUISpecialFrame = false,
    -- UseScaleBar = true, --disable for now might use it later on
    NoCloseButton = false,
  }
  local frame = DF:CreateSimplePanel(UIParent, addon.ADDON_WIDTH, addon.ADDON_HEIGHT, "WagoUI",
    addonName.."Frame",
    panelOptions, addon.db);
  frame:Hide()
  DF:ApplyStandardBackdrop(frame);
  DF:CreateBorder(frame, 1, 0, 0);
  frame:ClearAllPoints();
  frame:SetFrameStrata("HIGH");
  frame:SetFrameLevel(100);
  frame:SetToplevel(true)
  frame:SetPoint(addon.db.anchorTo, UIParent, addon.db.anchorFrom, addon.db.xoffset, addon.db.yoffset)
  hooksecurefunc(frame, "StopMovingOrSizing", function()
    local from, _, to, x, y = frame:GetPoint(nil)
    addon.db.anchorFrom, addon.db.anchorTo = from, to
    addon.db.xoffset, addon.db.yoffset = x, y
  end)
  frame.__background:SetAlpha(1)

  frame.Title:SetFont(frame.Title:GetFont(), 16);
  frame.Title:SetPoint("CENTER", frame.TitleBar, "CENTER", 0, 1)

  local versionString = frame.TitleBar:CreateFontString(addonName.."VersionString", "overlay", "GameFontNormalSmall")
  versionString:SetTextColor(.8, .8, .8, 1)
  versionString:SetText("v"..metaVersion)
  versionString:SetPoint("LEFT", frame.TitleBar, "LEFT", 2, 0)

  local reloadIndicator = DF:CreateButton(frame, nil, 40, 40, "", nil, nil,
    "UI-RefreshButton", nil, nil, nil, nil);
  reloadIndicator:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -30)
  reloadIndicator:SetTooltip(L["IMPORT_RELOAD_WARNING1"]);
  reloadIndicator:SetFrameStrata("DIALOG")
  reloadIndicator:Hide()
  reloadIndicator:SetClickFunction(function()
    if not addon.db.introEnabled then
      ReloadUI()
    end
  end)

  function addon:ToggleReloadIndicator(show)
    if show then
      reloadIndicator:Show()
    else
      reloadIndicator:Hide()
    end
  end

  local autoStartCheckbox = DF:CreateSwitch(frame,
    function(_, _, value)
      addon.db.autoStart = value
    end,
    false, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, DF:GetTemplate("switch", "OPTIONS_CHECKBOX_BRIGHT_TEMPLATE"))
  autoStartCheckbox:SetSize(25, 25)
  autoStartCheckbox:SetAsCheckBox()
  autoStartCheckbox:SetPoint("TOPLEFT", frame, "TOPRIGHT", 10, 0)
  autoStartCheckbox:SetValue(addon.db.autoStart)

  local resetButton = addon.DF:CreateButton(frame, 60, 40, "RESET", 16)
  resetButton:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, -30);
  resetButton:SetClickFunction(addon.ShowAddonResetPrompt);

  local forceErrorButton = addon.DF:CreateButton(frame, 120, 40, "Force Error", 16)
  forceErrorButton:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, -80);
  forceErrorButton:SetClickFunction(addon.TestErrorHandling);

  addon.frames.mainFrame = frame;

  hooksecurefunc(frame, "Hide", function()
    local promptFunc = function(promptText, successCallback, cancelCallback, okayText, cancelText)
      C_Timer.After(0.1, function()
        frame:Show()
        addon.DF:ShowPrompt(promptText, successCallback, cancelCallback, okayText, cancelText)
      end)
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
      if addon.db.introEnabled then
        if addon.state.currentPage == "DonePage" then
          promptFunc(L["IMPORT_RELOAD_WARNING2"], ReloadUI, cancelFunc, L["Reload UI"], L["Cancel"])
        else
          local notFinishedFunc = function()
            addon.state.needReload = false
            addon:ToggleReloadIndicator(false)
            addon:GotoPage("WelcomePage")
            frame:Hide()
          end
          promptFunc(L["INTRO_NOTFINISHED_WARNING"], notFinishedFunc, cancelFunc, L["Abort"], L["Cancel"])
        end
      else
        promptFunc(L["IMPORT_RELOAD_WARNING2"], ReloadUI, cancelFunc, L["Reload UI"], L["Cancel"])
      end
    end
  end)

  return frame
end
