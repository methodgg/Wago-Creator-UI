local addonName, addon = ...;
_G[addonName] = addon;
local DF = _G["DetailsFramework"];
local init

addon.frames = {};

function addon.ShowAddonResetPrompt()
  DF:ShowPromptPanel("Reset?"
    , function()
      DetailsFrameworkPromptSimple:SetHeight(80)
      addon.ResetOptions()
    end,
    function()
      DetailsFrameworkPromptSimple:SetHeight(80)
    end,
    nil,
    nil)
  DetailsFrameworkPromptSimple:SetHeight(100)
end

function addon:ToggleFrame()
  if (addon.frames and addon.frames.mainFrame and addon.frames.mainFrame:IsShown()) then
    addon:HideFrame();
  else
    addon:ShowFrame();
  end
end

function addon:HideFrame()
  addon.frames.mainFrame:Hide();
end

function addon:ShowFrame()
  if not addon.framesCreated then
    init()
    addon.framesCreated = true
  end
  addon.frames.mainFrame:Show();
end

function init()
  addon:RegisterErrorHandledFunctions()
  addon:SetupWagoData()
  addon:CreateCopyHelper()
  local mainFrame = addon:CreateMainFrame()
  addon:CreateIntroFrame(mainFrame)
  addon:CreateAltFrame(mainFrame)
  addon:CreateExpertFrame(mainFrame)
  if addon.db.introEnabled then
    addon:ShowIntroFrame()
  elseif not addon.dbC.hasLoggedIn and addon.db.anyInstalled then
    addon:ShowAltFrame()
  else
    addon:ShowExpertFrame()
  end
  if not addon.dbC.hasLoggedIn or not addon.db.hasLoggedInEver then
    addon:SuppressAddOnSpam()
  end
  addon.dbC.hasLoggedIn = true
  addon.db.hasLoggedInEver = true
end
