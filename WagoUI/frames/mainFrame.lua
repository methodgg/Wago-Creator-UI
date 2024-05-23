local addonName, addon = ...;
local DF = _G["DetailsFramework"];
local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE");

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

  local autoStartCheckbox = DF:CreateSwitch(frame,
    function(_, _, value)
      addon.db.autoStart = value
    end,
    false, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, DF:GetTemplate("switch", "OPTIONS_CHECKBOX_BRIGHT_TEMPLATE"))
  autoStartCheckbox:SetSize(25, 25)
  autoStartCheckbox:SetAsCheckBox()
  autoStartCheckbox:SetPoint("TOPLEFT", frame, "TOPRIGHT", 10, 0)
  autoStartCheckbox:SetValue(addon.db.autoStart)

  local resetButton = DF:CreateButton(frame, nil, 60, 40, "RESET", nil, nil, nil, nil, nil, nil,
    options_dropdown_template);
  resetButton:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, -30);
  resetButton.text_overlay:SetFont(resetButton.text_overlay:GetFont(), 16);
  resetButton:SetClickFunction(addon.ShowAddonResetPrompt);

  local forceErrorButton = DF:CreateButton(frame, nil, 120, 40, "Force Error", nil, nil, nil, nil, nil, nil,
    options_dropdown_template);
  forceErrorButton:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, -80);
  forceErrorButton.text_overlay:SetFont(forceErrorButton.text_overlay:GetFont(), 16);
  forceErrorButton:SetClickFunction(addon.TestErrorHandling);

  addon.frames.mainFrame = frame;
  return frame
end
