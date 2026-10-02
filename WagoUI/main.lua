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
  addon:CreateCopyHelper()
  local mainFrame = addon:CreateMainFrame()
  addon:CreateWorkspace(mainFrame)
  mainFrame:HookScript("OnHide", function() addon.db.introEnabled = false end)
  addon.dbC.hasLoggedIn = true
  if addon.dbC.pendingAlt then
    addon:ShowPrompt("Continue alt setup?", function()
      addon:ApplyAlt(addon.dbC.pendingAlt, function(failed)
        if #failed > 0 then addon:AddonPrintError(table.concat(failed, ", ")) end
      end)
    end)
  end
end
