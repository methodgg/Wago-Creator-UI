-- Mythic Dungeon Tools: routes are picked in their own manager, listed by dungeon, and ship with every variation.
-- Players see each route on its own and can import them all in one MDT window.
local addon = select(2, ...)
local LAP = LibStub("LibAddonProfiles")
local Packs = addon.Packs
local UI = addon.UI
local button, input, label, reset = UI.button, UI.input, UI.label, UI.reset
local dragGhost, emptyList, managerList, managerRow = UI.dragGhost, UI.emptyList, UI.managerList, UI.managerRow
local closeModal, modal, safely = UI.closeModal, UI.modal, UI.safely
local includedAuras = UI.includedAuras
local function render() UI.render() end

local MDT = "Mythic Dungeon Tools"
local GREY, MUTED, MISSING = { .7, .7, .7 }, { .55, .55, .55 }, { .5, .5, .5 }
local INCLUDE, REMOVE = [[Interface\ChatFrame\ChatFrameExpandArrow]], [[Interface\Buttons\UI-GroupLoot-Pass-Up]]
local ROW = 32
local INDENT = 16
-- Dungeons the creator collapsed, by name; kept while the game runs.
local collapsed = {}

-- Routes as a list in MDT's order, each with its id.
local function sortedRoutes(routes)
  local list = {}
  for id, route in pairs(routes) do table.insert(list, { id = id, route = route }) end
  table.sort(list, function(a, b) return (a.route.order or 0) < (b.route.order or 0) end)
  return list
end

-- "Author - Route" with the author in class color, as MDT lists routes. withDungeon puts the dungeon first, for rows
-- that are not under its heading.
local function routeText(route, withDungeon)
  local text = route.name or route.label
  if route.author and route.author ~= "" then
    local hex = route.authorClass and select(4, GetClassColor(route.authorClass))
    text = (hex and WrapTextInColorCode(route.author, hex) or route.author) .. " - " .. text
  end
  if withDungeon and route.category then text = route.category .. ": " .. text end
  return text
end

-- What the search looks through: route name, dungeon and author.
local function searchText(route)
  return (route.label .. " " .. (route.author or "")):lower()
end

local function routesManager(pack, moduleName)
  local query = ""
  local lap = LAP:GetModule(moduleName)
  local f = modal(moduleName, 760, 560)
  label(f, "Pick the routes this UI Pack ships. Players see every route on its own and can import them all at once "
    .. "in Mythic Dungeon Tools, where they choose which to keep.", 24, 58, 712, 13, GREY):SetWordWrap(true)
  label(f, "Your routes", 24, 100, 344, 16)
  local includedHeading = label(f, "", 392, 100, 344, 16)
  local search = input(f, "", 24, 124, 344)
  label(f, "Click or drag a route to move it between the lists.", 392, 134, 344, 12, MUTED)
  local available = managerList(f, "availableRoutes", 24, 166, 344, 290)
  local included = managerList(f, "includedRoutes", 392, 166, 344, 290)
  dragGhost({ available, included })

  local draw
  -- Routes join every variation on their own.
  local function include(entry)
    safely(function() Packs.AddProfile(pack, moduleName, entry.id, entry.route.label, nil, "group") end)
    render(); draw()
  end
  local function exclude(p)
    safely(function() Packs.RemoveProfile(pack, p.id) end)
    render(); draw()
  end
  draw = function()
    reset(available.content); reset(included.content)
    -- Read on every draw, so routes made in MDT since the last one show up.
    local routes = lap:getAuras()
    local chosen, taken = includedAuras(pack, moduleName), {}
    for _, p in ipairs(chosen) do taken[p.sourceKey] = true end

    -- Listed routes by dungeon, in MDT's order.
    local dungeons, byName = {}, {}
    for _, entry in ipairs(sortedRoutes(routes)) do
      local route = entry.route
      local listed = route.currentSeason ~= false and (query == "" or searchText(route):find(query, 1, true))
      if not taken[entry.id] and listed then
        local name = route.category or "?"
        if not byName[name] then
          byName[name] = { name = name, icon = route.categoryIcon, entries = {} }
          table.insert(dungeons, byName[name])
        end
        table.insert(byName[name].entries, entry)
      end
    end
    local y = 0
    for _, dungeon in ipairs(dungeons) do
      -- A search shows every match, collapsed or not.
      local open = query ~= "" or not collapsed[dungeon.name]
      managerRow(available, y, {
        icon = dungeon.icon, text = dungeon.name .. " (" .. #dungeon.entries .. ")", color = GREY,
        chevron = open and "open" or "closed", noDrag = true,
        onActivate = function()
          -- A search keeps every dungeon open; a click then would change what shows once it is cleared.
          if query ~= "" then return end
          collapsed[dungeon.name] = not collapsed[dungeon.name] or nil
          draw()
        end,
      })
      y = y + ROW
      if open then
        for _, entry in ipairs(dungeon.entries) do
          managerRow(available, y, {
            indent = INDENT, icon = entry.route.icon, text = routeText(entry.route), actionTexture = INCLUDE,
            dropTarget = included, tooltip = "Include in this UI Pack", onActivate = function() include(entry) end,
          })
          y = y + ROW
        end
      end
    end
    if y == 0 then
      emptyList(available, query == "" and "No more routes to include." or "No routes match your search.")
    end
    available.content:SetHeight(math.max(1, y))

    y = 0
    for _, p in ipairs(chosen) do
      local route = routes[p.sourceKey]
      managerRow(included, y, {
        icon = route and route.categoryIcon or lap.icon, text = route and routeText(route, true) or (p.name .. " (Missing in MDT)"),
        color = route and { 1, 1, 1 } or MISSING,
        actionTexture = REMOVE, tooltip = "Remove from this UI Pack", onActivate = function() exclude(p) end,
        dropTarget = available,
      })
      y = y + ROW
    end
    if y == 0 then emptyList(included, "Click a route on the left to include it.") end
    included.content:SetHeight(math.max(1, y))
    includedHeading:SetText("Included routes (" .. #chosen .. ")")
  end
  search:SetScript("OnTextChanged", function(self) query = self:GetText():lower(); draw() end)
  button(f, "Open " .. moduleName, 24, 512, 220, function()
    lap:openConfig()
    -- MDT loads its window on the next frame.
    C_Timer.After(0.2, function() if f:IsShown() then draw() end end)
  end)
  button(f, "Done", 606, 512, 130, function() closeModal(); render() end)
  draw()
end

UI.MDT = MDT
UI.routesManager = routesManager
