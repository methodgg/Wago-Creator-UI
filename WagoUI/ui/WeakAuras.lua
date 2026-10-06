-- WeakAuras: groups are picked in their own manager, then assigned to variations on their creator rows.
local addon = select(2, ...)
local LAP = LibStub("LibAddonProfiles")
local LWF = LibStub("LibWagoFramework")
local Packs = addon.Packs
local UI = addon.UI
local button, input, label, reset = UI.button, UI.input, UI.label, UI.reset
local dragGhost, emptyList, managerList, managerRow = UI.dragGhost, UI.emptyList, UI.managerList, UI.managerRow
local closeModal, modal, safely = UI.closeModal, UI.modal, UI.safely
local function render() UI.render() end

local WA = "WeakAuras"
-- Large aura collections are listed in part; searching narrows them down.
local LIMIT = 200
local GREY = { .7, .7, .7 }
local INCLUDE, REMOVE = [[Interface\ChatFrame\ChatFrameExpandArrow]], [[Interface\Buttons\UI-GroupLoot-Pass-Up]]
local BLOCK, COPY = 255352, 134327

local function includedAuras(pack)
  local result = {}
  for _, p in ipairs(Packs.Profiles(pack)) do
    if p.moduleName == WA then table.insert(result, p) end
  end
  return result
end

local function auraIcon(data)
  local icon = data and (data.groupIcon or data.displayIcon)
  return tonumber(icon) or (type(icon) == "string" and icon ~= "" and icon) or 134400
end

-- Every aura below a group, nested groups included.
local function childCount(displays, id, cache)
  if cache[id] then return cache[id] end
  local count = 0
  for _, child in ipairs(displays[id] and displays[id].controlledChildren or {}) do
    count = count + 1 + childCount(displays, child, cache)
  end
  cache[id] = count
  return count
end

-- The aura's name, how many auras it holds and, for auras inside a group, which group.
local function auraText(displays, id, cache)
  local text, count = id, childCount(displays, id, cache)
  if count > 0 then text = text .. " |cff808080(" .. count .. (count == 1 and " aura" or " auras") .. ")|r" end
  local parent = displays[id] and displays[id].parent
  if parent then text = text .. " |cff808080in " .. parent .. "|r" end
  return text
end

-- Shows one aura's export string to copy, exported with the pack's options and blocked auras.
local function exportString(pack, id, back)
  local lap = addon:EnsureIntegration(WA)
  if not lap then return end
  addon:Async(function()
    if lap.setExportOptions then lap:setExportOptions(pack.exportOptions and pack.exportOptions[WA] or {}) end
    local blocked = {}
    for blockedID in pairs(pack.blockedAuras or {}) do
      if blockedID ~= id then blocked[blockedID] = true end
    end
    local text = lap:exportGroup(id, blocked)
    if not text then return end
    local f = modal("Export string", 560, 230)
    label(f, id, 24, 62, 512, 14, GREY)
    local box = input(f, text, 24, 88, 512)
    box:HighlightText()
    box:SetFocus()
    label(f, "Press Ctrl+C to copy.", 24, 132, 512, 13, { .55, .55, .55 })
    button(f, "Back", 406, 172, 130, closeModal)
    f.onClose = back
  end, "weakAuraExportString")
end

local function toggleOptions()
  if WeakAurasOptions and WeakAurasOptions:IsShown() then
    LWF:EndSplitView(WeakAurasOptions, addon.ResetFramePosition)
    return
  end
  if not WeakAurasOptions then LAP:GetModule(WA):openConfig() end
  if not WeakAurasOptions then return end
  WeakAurasOptions:Show()
  LWF:StartSplitView(addon.frames.mainFrame, WeakAurasOptions, true, 20)
end

-- Picks which WeakAuras the pack exports and which are never exported, not even inside an included group.
local function weakAurasManager(pack)
  local query = ""
  local f = modal(WA, 760, 600)
  label(f, "Make sure you have the author's permission to share every WeakAura you include.", 24, 58, 712, 13,
    { 1, .65, .3 }):SetWordWrap(true)
  label(f, "Including a group includes every aura in it. Included WeakAuras join all variations; change that on their "
    .. "rows in the creator.", 24, 80, 712, 13, GREY):SetWordWrap(true)
  label(f, "Only groups are listed until you search. Blocked WeakAuras are left out of every export.", 24, 114, 712, 13, GREY)
  label(f, "Your WeakAuras", 24, 140, 344, 16)
  local includedHeading = label(f, "", 392, 140, 344, 16)
  local search = input(f, "", 24, 164, 344)
  label(f, "Click or drag a WeakAura to move it between the lists.", 392, 174, 344, 12, { .55, .55, .55 })
  local available = managerList(f, "availableAuras", 24, 206, 344, 290)
  local included = managerList(f, "includedAuras", 392, 206, 344, 290)
  dragGhost({ available, included })

  local draw
  local function back() weakAurasManager(pack) end
  local function include(id)
    safely(function()
      local tags = {}
      for _, variationID in ipairs(pack.variationOrder) do tags[variationID] = true end
      Packs.AddProfile(pack, WA, id, id, tags, "group")
    end)
    render(); draw()
  end
  local function exclude(p)
    safely(function() Packs.RemoveProfile(pack, p.id) end)
    render(); draw()
  end
  local function block(id, blocked)
    pack.blockedAuras = pack.blockedAuras or {}
    pack.blockedAuras[id] = blocked or nil
    pack.revision = pack.revision + 1
    render(); draw()
  end
  draw = function()
    reset(available.content); reset(included.content)
    local displays = WeakAurasSaved and WeakAurasSaved.displays or {}
    local chosen, blocked, taken, cache = includedAuras(pack), pack.blockedAuras or {}, {}, {}
    for _, p in ipairs(chosen) do taken[p.sourceKey] = true end
    local ids = {}
    for id, data in pairs(displays) do
      local listed = query == "" and not data.parent or query ~= "" and id:lower():find(query, 1, true)
      if listed and not taken[id] and not blocked[id] then table.insert(ids, id) end
    end
    table.sort(ids, function(a, b) return a:lower() < b:lower() end)
    local y = 0
    for index = 1, math.min(#ids, LIMIT) do
      local id = ids[index]
      managerRow(available, y, {
        icon = auraIcon(displays[id]), text = auraText(displays, id, cache),
        actionTexture = INCLUDE, tooltip = "Include in this UI Pack", onActivate = function() include(id) end,
        dropTarget = included, secondTexture = BLOCK, secondTooltip = "Block from every export",
        secondAction = function() block(id, true) end,
      })
      y = y + 32
    end
    if #ids > LIMIT then
      label(available.content, (#ids - LIMIT) .. " more. Search to find them.", 0, y + 8, available.content:GetWidth(), 13,
        { .5, .5, .5 }):SetJustifyH("CENTER")
      y = y + 32
    end
    if y == 0 then emptyList(available, query == "" and "No more WeakAuras to include." or "No WeakAuras match your search.") end
    available.content:SetHeight(math.max(1, y))

    y = 0
    for _, p in ipairs(chosen) do
      managerRow(included, y, {
        icon = auraIcon(displays[p.sourceKey]), text = auraText(displays, p.sourceKey, cache),
        color = displays[p.sourceKey] and { 1, 1, 1 } or { .5, .5, .5 },
        actionTexture = REMOVE, tooltip = "Remove from this UI Pack", onActivate = function() exclude(p) end,
        dropTarget = available, secondTexture = COPY, secondTooltip = "Copy export string",
        secondAction = displays[p.sourceKey] and function() exportString(pack, p.sourceKey, back) end or nil,
      })
      y = y + 32
    end
    local blockedIDs = {}
    for id in pairs(blocked) do table.insert(blockedIDs, id) end
    table.sort(blockedIDs, function(a, b) return a:lower() < b:lower() end)
    for _, id in ipairs(blockedIDs) do
      managerRow(included, y, {
        icon = auraIcon(displays[id]), text = id .. " (Blocked)", color = { 1, .35, .3 },
        actionTexture = REMOVE, tooltip = "Allow exporting again", onActivate = function() block(id, false) end,
        dropTarget = available,
      })
      y = y + 32
    end
    if y == 0 then emptyList(included, "Click a WeakAura on the left to include it.") end
    included.content:SetHeight(math.max(1, y))
    includedHeading:SetText("Included WeakAuras (" .. #chosen .. ")")
  end
  search:SetScript("OnTextChanged", function(self) query = self:GetText():lower(); draw() end)
  search:SetFocus()
  button(f, "Toggle WeakAuras", 24, 552, 180, toggleOptions)
  button(f, "Done", 606, 552, 130, function() closeModal(); render() end)
  -- Closing the manager also closes WeakAuras' window if it was docked beside it.
  f.onClose = function()
    if WeakAurasOptions then LWF:EndSplitView(WeakAurasOptions, addon.ResetFramePosition) end
  end
  draw()
end

UI.includedAuras = includedAuras
UI.weakAurasManager = weakAurasManager
