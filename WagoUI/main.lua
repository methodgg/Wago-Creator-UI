local addonName, addon = ...;
_G[addonName] = addon;
local DF = _G["DetailsFramework"];
local db
local init

addon.frames = {};

function addon:ShowFrame()
  if not addon.framesCreated then
    init()
    addon.framesCreated = true
    addon.frames.mainFrame:Show();
  else
    addon.frames.mainFrame:Show();
  end
end

function addon:HideFrame()
  addon.frames.mainFrame:Hide();
end

function addon:ToggleFrame()
  if (addon.frames and addon.frames.mainFrame and addon.frames.mainFrame:IsShown()) then
    addon:HideFrame();
  else
    addon:ShowFrame();
  end
end

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

function init()
  addon:RegisterErrorHandledFunctions()
  addon:SetupWagoData()
  local mainFrame = addon:CreateMainFrame()
  addon:CreateProfileTable(mainFrame)
  addon:MakeCopyHelper()
end
