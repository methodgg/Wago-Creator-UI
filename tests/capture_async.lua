-- Exercise capture pacing with the actual LibAsync scheduler and queued frame timers.
local addon, modules, captureAsync = dofile("tests/check.lua")
local library = {}
local environment = setmetatable({
  LibStub = { GetLibrary = function() end, NewLibrary = function() return library end },
  CreateFrame = function()
    return {
      Show = function(self) self.shown = true end,
      Hide = function(self) self.shown = false end,
      SetScript = function(self, _, callback) self.update = callback end,
    }
  end,
  debugprofilestop = function() return 0 end,
  debugstack = function() return "" end,
  geterrorhandler = function() return error end,
  max = math.max,
}, { __index = _G })
setfenv(assert(loadfile("WagoUI/libs/LibAsync/LibAsync.lua")), environment)()
captureAsync.Await = library.Await
local handler = library:GetHandler({ type = "everyFrame", maxTime = 40, maxTimeCombat = 8, errorHandler = error })
function addon:Async(callback, name) handler:Async(callback, name) end
local timers, frame, exports, finished, updates = {}, 0, 0, false, {}
C_Timer.After = function(delay, callback)
  assert(delay == 0)
  timers[#timers + 1] = callback
end
modules.Test.exportProfile = function(_, key) exports = exports + 1; return "payload-" .. key end
local pack = addon:NewPack("Paced capture")
local alternate = addon.Packs.SaveVariation(pack, nil, "Alternate", nil, "")
addon.Packs.AddProfile(pack, "Test", "Raid", "Raid", { default = true })
addon.Packs.AddProfile(pack, "Test", "Other", "Other", { [alternate] = true })
addon:CapturePack(pack, nil, function() finished = true end, function(current, total)
  assert(total == 2)
  updates[#updates + 1] = { current = current, frame = frame }
end)
local function nextFrame()
  frame = frame + 1
  local ready = timers
  timers = {}
  for _, callback in ipairs(ready) do callback() end
  if handler.frame.shown then handler.frame:update(.016) end
end
assert(addon.state.busy and not finished and updates[1].current == 0)
nextFrame()
assert(exports == 0 and not finished, "Capture started before its loading UI could render")
nextFrame()
assert(exports == 1 and not finished and updates[2].current == 1)
nextFrame()
assert(exports == 2 and not finished and updates[3].current == 2)
assert(updates[2].frame < updates[3].frame, "Progress steps ran within one frame")
assert(addon.db.creator.packs[pack.id] == pack, "Capture published its partial result")
nextFrame()
assert(finished and not addon.state.busy and handler.size == 0)
assert(addon.db.creator.packs[pack.id] ~= pack, "Completed capture was not published")
print("Actual LibAsync capture pacing and atomic publication checks passed.")
