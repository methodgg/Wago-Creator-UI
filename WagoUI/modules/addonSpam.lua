local addonName, addon = ...

local function hideAddOnPopups()
  for i = 1, 5 do
    local frameName = "ElvUI_StaticPopup"..i
    local frame = _G[frameName]
    if frame then
      frame:Hide()
    end
  end
  if PlaterOptionsPanelFrame and PlaterOptionsPanelFrame:IsShown() then PlaterOptionsPanelFrame:Hide() end

  if DetailsWelcomeWindow then DetailsWelcomeWindow:Hide(); end
  if DetailsNewsWindow then DetailsNewsWindow:Hide(); end
  if StreamOverlayWelcomeWindow then StreamOverlayWelcomeWindow:Hide(); end
  if ViragDevToolFrame then ViragDevToolFrame:Hide(); end
  if ElvUIInstallFrame then ElvUIInstallFrame:Hide(); end
  if SplashFrame and SplashFrame.BottomCloseButton then
    if SplashFrame:IsShown() then
      SplashFrame.BottomCloseButton:Click()
    end
  end
end

function addon:SuppressAddOnSpam()
  if _G["_detalhes"] then _G["_detalhes"].is_first_run = false end
  if _G["_detalhes"] then _G["_detalhes"].is_version_first_run = false end
  hideAddOnPopups()
  --keep trying to hide popups for 10 seconds
  for i = 1, 10 do
    C_Timer.After(i, function()
      hideAddOnPopups()
    end)
  end
end
