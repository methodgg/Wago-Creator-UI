-- Aura addons (WeakAuras, ForeverAuras): groups are picked in their own manager, then assigned to variations on their
-- creator rows.
local addon = select(2, ...)
local LAP = LibStub("LibAddonProfiles")
local Packs = addon.Packs
local UI = addon.UI
local button, input, label, reset = UI.button, UI.input, UI.label, UI.reset
local dragGhost, emptyList, managerList, managerRow = UI.dragGhost, UI.emptyList, UI.managerList, UI.managerRow
local closeModal, modal, safely = UI.closeModal, UI.modal, UI.safely
local function render() UI.render() end

-- Large aura collections are listed in part; searching narrows them down.
local LIMIT = 200
local GREY = { .7, .7, .7 }
local INCLUDE, REMOVE = [[Interface\ChatFrame\ChatFrameExpandArrow]], [[Interface\Buttons\UI-GroupLoot-Pass-Up]]
local BLOCK, COPY = 255352, 134327

local function includedAuras(pack, moduleName)
  local result = {}
  for _, p in ipairs(Packs.Profiles(pack)) do
    if p.moduleName == moduleName then table.insert(result, p) end
  end
  return result
end

local function auraIcon(aura)
  local icon = aura and aura.icon
  return tonumber(icon) or (type(icon) == "string" and icon ~= "" and icon) or 134400
end

-- Every aura below a group, nested groups included.
local function childCount(auras, id, cache)
  if cache[id] then return cache[id] end
  local count = 0
  for _, child in ipairs(auras[id] and auras[id].children or {}) do
    count = count + 1 + childCount(auras, child, cache)
  end
  cache[id] = count
  return count
end

-- The aura's name, how many auras it holds and, for auras inside a group, which group.
local function auraText(auras, id, cache)
  local text, count = id, childCount(auras, id, cache)
  if count > 0 then text = text .. " |cff808080(" .. count .. (count == 1 and " aura" or " auras") .. ")|r" end
  local parent = auras[id] and auras[id].parent
  if parent then text = text .. " |cff808080in " .. parent .. "|r" end
  return text
end

-- Shows one aura's export string to copy, exported with the pack's options and blocked auras.
local function exportString(pack, moduleName, id, back)
  local lap = addon:EnsureIntegration(moduleName)
  if not lap then return end
  addon:Async(function()
    if lap.setExportOptions then lap:setExportOptions(pack.exportOptions and pack.exportOptions[moduleName] or {}) end
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
  end, "auraExportString")
end

local function configFrame(moduleName)
  local lap = LAP:GetModule(moduleName)
  return lap and lap.getConfigFrame and lap:getConfigFrame()
end

-- Places the aura addon's open window beside WagoUI's, with WagoUI on the left when mineLeft is set.
local function dockAuras(moduleName, mineLeft, gap)
  local frame = configFrame(moduleName)
  if not frame or not frame:IsShown() then return end
  local offset = (mineLeft and -1 or 1) * gap
  local mainFrame = addon.frames.mainFrame
  frame:ClearAllPoints()
  frame:SetPoint(mineLeft and "LEFT" or "RIGHT", UIParent, "CENTER", -offset, 0)
  mainFrame:ClearAllPoints()
  mainFrame:SetPoint(mineLeft and "RIGHT" or "LEFT", UIParent, "CENTER", offset, 0)
end

-- Closes a docked aura addon window and puts WagoUI back where it was.
local function undockAuras(moduleName)
  local frame = configFrame(moduleName)
  if not frame or not frame:IsShown() then return end
  LAP:GetModule(moduleName):closeConfig()
  addon:ResetFramePosition()
end

local function toggleOptions(moduleName)
  local frame = configFrame(moduleName)
  if frame and frame:IsShown() then
    undockAuras(moduleName)
    return
  end
  LAP:GetModule(moduleName):openConfig()
  dockAuras(moduleName, true, 20)
end

-- Picks which auras the pack exports and which are never exported, not even inside an included group.
local function aurasManager(pack, moduleName)
  local query = ""
  -- Read once; auras change while the addon's own window is open, so toggling it reads them again.
  local lap = LAP:GetModule(moduleName)
  local auras = lap:getAuras()
  local f = modal(moduleName, 760, 600)
  label(f, "Make sure you have the author's permission to share every aura you include.", 24, 58, 712, 13,
    { 1, .65, .3 }):SetWordWrap(true)
  label(f, "Including a group includes every aura in it. Included auras join all variations; change that on their "
    .. "rows in the creator.", 24, 80, 712, 13, GREY):SetWordWrap(true)
  label(f, "Only groups are listed until you search. Blocked auras are left out of every export.", 24, 114, 712, 13, GREY)
  label(f, "Your " .. moduleName, 24, 140, 344, 16)
  local includedHeading = label(f, "", 392, 140, 344, 16)
  local search = input(f, "", 24, 164, 344)
  label(f, "Click or drag an aura to move it between the lists.", 392, 174, 344, 12, { .55, .55, .55 })
  local available = managerList(f, "availableAuras", 24, 206, 344, 290)
  local included = managerList(f, "includedAuras", 392, 206, 344, 290)
  dragGhost({ available, included })

  local draw
  local function back() aurasManager(pack, moduleName) end
  local function include(id)
    safely(function()
      local tags = {}
      for _, variationID in ipairs(pack.variationOrder) do tags[variationID] = true end
      Packs.AddProfile(pack, moduleName, id, id, tags, "group")
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
    local chosen, blocked, taken, cache = includedAuras(pack, moduleName), pack.blockedAuras or {}, {}, {}
    for _, p in ipairs(chosen) do taken[p.sourceKey] = true end
    local ids = {}
    for id, aura in pairs(auras) do
      local listed = query == "" and not aura.parent or query ~= "" and id:lower():find(query, 1, true)
      if listed and not taken[id] and not blocked[id] then table.insert(ids, id) end
    end
    table.sort(ids, function(a, b) return a:lower() < b:lower() end)
    local y = 0
    for index = 1, math.min(#ids, LIMIT) do
      local id = ids[index]
      managerRow(available, y, {
        icon = auraIcon(auras[id]), text = auraText(auras, id, cache),
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
    if y == 0 then emptyList(available, query == "" and "No more auras to include." or "No auras match your search.") end
    available.content:SetHeight(math.max(1, y))

    y = 0
    for _, p in ipairs(chosen) do
      managerRow(included, y, {
        icon = auraIcon(auras[p.sourceKey]), text = auraText(auras, p.sourceKey, cache),
        color = auras[p.sourceKey] and { 1, 1, 1 } or { .5, .5, .5 },
        actionTexture = REMOVE, tooltip = "Remove from this UI Pack", onActivate = function() exclude(p) end,
        dropTarget = available, secondTexture = COPY, secondTooltip = "Copy export string",
        secondAction = auras[p.sourceKey] and function() exportString(pack, moduleName, p.sourceKey, back) end or nil,
      })
      y = y + 32
    end
    local blockedIDs = {}
    for id in pairs(blocked) do table.insert(blockedIDs, id) end
    table.sort(blockedIDs, function(a, b) return a:lower() < b:lower() end)
    for _, id in ipairs(blockedIDs) do
      managerRow(included, y, {
        icon = auraIcon(auras[id]), text = id .. " (Blocked)", color = { 1, .35, .3 },
        actionTexture = REMOVE, tooltip = "Allow exporting again", onActivate = function() block(id, false) end,
        dropTarget = available,
      })
      y = y + 32
    end
    if y == 0 then emptyList(included, "Click an aura on the left to include it.") end
    included.content:SetHeight(math.max(1, y))
    includedHeading:SetText("Included " .. moduleName .. " (" .. #chosen .. ")")
  end
  search:SetScript("OnTextChanged", function(self) query = self:GetText():lower(); draw() end)
  button(f, "Toggle " .. moduleName, 24, 552, 180, function()
    toggleOptions(moduleName)
    auras = lap:getAuras()
    draw()
  end)
  button(f, "Done", 606, 552, 130, function() closeModal(); render() end)
  -- Closing the manager also closes the aura addon's window if it was docked beside it.
  f.onClose = function() undockAuras(moduleName) end
  draw()
end

UI.dockAuras = dockAuras
UI.includedAuras = includedAuras
UI.aurasManager = aurasManager
