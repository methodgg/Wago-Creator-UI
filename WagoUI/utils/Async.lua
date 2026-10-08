---@class WagoUI
local addon = select(2, ...)

---@type LibAsync
local LibAsync = LibStub("LibAsync")

---@type LibAsyncConfig
local asyncConfig = {
  type = "everyFrame",
  maxTime = 40,
  maxTimeCombat = 8,
  errorHandler = function(msg, stackTrace, name)
    addon.state.busy, addon.state.isImporting = false, false
    if addon.frames.mainFrame then
      addon:ToggleReloadIndicator(addon.state.needReload)
      if addon.state.needReopen then addon.frames.mainFrame:Show(); addon.state.needReopen = nil end
    end
    addon:RefreshWorkspace()
    addon:OnError(msg, stackTrace, name)
  end
}

addon.asyncHandler = LibAsync:GetHandler(asyncConfig)

function addon:Async(func, name, singleton)
  addon.asyncHandler:Async(func, name, singleton)
end

function addon:CancelAsync(name)
  addon.asyncHandler:CancelAsync(name)
end
