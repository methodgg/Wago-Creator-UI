---@class WagoUI
local addon = select(2, ...)

local frames = {
  "ElvUI_StaticPopup1",
  "ElvUI_StaticPopup2",
  "ElvUI_StaticPopup3",
  "ElvUI_StaticPopup4",
  "ElvUI_StaticPopup5",
  "StaticPopup1",
  "StaticPopup2",
  "StaticPopup3",
  "StaticPopup4",
  "StaticPopup5",
  "PlaterOptionsPanelFrame",
  "DetailsWelcomeWindow",
  "DetailsNewsWindow",
  "StreamOverlayWelcomeWindow",
  "ViragDevToolFrame",
  "ElvUIInstallFrame",
  "CellChangelogsFrame",
  "BugSackFrame",
  "ScriptErrorsFrame"
  -- "DevToolFrame"
}

local detailsFrames = {
  "DetailsBaseFrame1",
  "DetailsBaseFrame2"
}

local function hideAddOnPopups()
  for _, frameName in ipairs(frames) do
    local frame = _G[frameName]
    if frame then
      frame:Hide()
      frame.Show = function()
      end
    end
  end
  if SplashFrame and SplashFrame.BottomCloseButton then
    if SplashFrame:IsShown() then
      SplashFrame.BottomCloseButton:Click()
    end
  end
  if C_AddOns.IsAddOnLoaded("OmniCD") then
    if OmniCDDB and OmniCDDB.global then
      OmniCDDB.global.disableElvMsg = true
    end
  end

  local Details = _G["_detalhes"]
  if Details and Details.is_first_run then
    for _, frameName in ipairs(detailsFrames) do
      local frame = _G[frameName]
      if frame then
        frame:Hide()
        frame.Show = function()
        end
      end
    end
    C_Timer.After(
      10,
      function()
        Details.is_first_run = false
        Details.is_version_first_run = false
      end
    )
  end
end

function addon:SuppressAddOnSpam()
  local Details = _G["_detalhes"]
  if Details then
    if Details.is_first_run and #Details.custom == 0 then
      Details:AddDefaultCustomDisplays()
    end
  end
  hideAddOnPopups()
  --keep trying to hide popups for 10 seconds
  for i = 1, 10 do
    C_Timer.After(
      i,
      function()
        hideAddOnPopups()
      end
    )
  end
end
