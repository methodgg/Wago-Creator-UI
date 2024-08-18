---@type string
local addonName = ...
---@class WagoUI
local addon = select(2, ...)
_G[addonName] = addon
local DF = _G["DetailsFramework"]
local init

addon.frames = {}

function addon:ResetFramePosition()
  local defaults = addon.dbDefaults
  addon.db.anchorTo = defaults.anchorTo
  addon.db.anchorFrom = defaults.anchorFrom
  addon.db.xoffset = defaults.xoffset
  addon.db.yoffset = defaults.yoffset
  if addon.frames.mainFrame then
    addon.frames.mainFrame:ClearAllPoints()
    addon.frames.mainFrame:SetPoint(
      defaults.anchorTo,
      UIParent,
      defaults.anchorFrom,
      defaults.xoffset,
      defaults.yoffset
    )
  end
end

function addon.ShowAddonResetPrompt()
  DF:ShowPromptPanel(
    "Reset?",
    function()
      DetailsFrameworkPromptSimple:SetHeight(80)
      addon.ResetOptions()
    end,
    function()
      DetailsFrameworkPromptSimple:SetHeight(80)
    end,
    nil,
    nil
  )
  DetailsFrameworkPromptSimple:SetHeight(100)
end

function addon:ToggleFrame()
  if (addon.frames and addon.frames.mainFrame and addon.frames.mainFrame:IsShown()) then
    addon:HideFrame()
  else
    addon:ShowFrame()
  end
end

function addon:HideFrame()
  addon.frames.mainFrame:Hide()
end

function addon:ShowFrame()
  if not addon.framesCreated then
    init()
    addon.framesCreated = true
  end
  addon.frames.mainFrame:Show()
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
    addon:GotoPage(addon.db.introState.currentPage)
  elseif not addon.dbC.hasLoggedIn and addon.db.anyInstalled then
    addon:ShowAltFrame()
    addon:ResetFramePosition()
  else
    addon:ShowExpertFrame()
  end
  if not addon.dbC.hasLoggedIn or addon.db.introEnabled then
    addon:SuppressAddOnSpam()
  end
  addon.dbC.hasLoggedIn = true
  if addon.db.introEnabled then
    -- if the user just clicks away the addon disable the intro and dont auto start again
    addon.frames.mainFrame:HookScript(
      "OnHide",
      function()
        addon.db.introEnabled = false
      end
    )
  end
  if addon.dbC.needLoad then
    addon.frames.introFrame:Hide()
    addon.frames.expertFrame:Hide()
    addon:ShowAltFrame()
    addon:ContinueSetAllProfiles()
  end
end
