local addonName, addon = ...

function PrivateAddParents(data)
  local parent = data.parent
  if (parent) then
    local parentData = WeakAuras.GetData(parent)
    WeakAuras.Add(parentData)
    PrivateAddParents(parentData)
  end
end

local function PrivateDuplicateAura(data, newParent, massEdit, targetIndex)
  local base_id = data.id.." "
  local num = 2

  -- if the old id ends with a number increment the number
  local matchName, matchNumber = string.match(data.id, "^(.-)(%d*)$")
  matchNumber = tonumber(matchNumber)
  if (matchName ~= "" and matchNumber ~= nil) then
    base_id = matchName
    num = matchNumber + 1
  end

  local new_id = base_id..num
  while (WeakAuras.GetData(new_id)) do
    new_id = base_id..num
    num = num + 1
  end

  local newData = CopyTable(data)
  newData.id = new_id
  newData.parent = nil
  newData.uid = WeakAuras.GenerateUniqueID()
  if newData.controlledChildren then
    newData.controlledChildren = {}
  end
  WeakAuras.Add(newData)
  -- WeakAuras.NewDisplayButton(newData, massEdit)
  if (newParent or data.parent) then
    local parentId = newParent or data.parent
    local parentData = WeakAuras.GetData(parentId)
    local index
    if targetIndex then
      index = targetIndex
    elseif newParent then
      index = #parentData.controlledChildren + 1
    else
      index = tIndexOf(parentData.controlledChildren, data.id) + 1
    end
    if (index) then
      tinsert(parentData.controlledChildren, index, newData.id)
      newData.parent = parentId
      WeakAuras.Add(newData)
      WeakAuras.Add(parentData)
      PrivateAddParents(parentData)

      -- ignore UI stuff, we don't need

      -- for index, id in pairs(parentData.controlledChildren) do
      --   local childButton = OptionsPrivate.GetDisplayButton(id)
      --   childButton:SetGroup(parentData.id, parentData.regionType == "dynamicgroup")
      --   childButton:SetGroupOrder(index, #parentData.controlledChildren)
      -- end

      -- if not massEdit then
      --   local button = OptionsPrivate.GetDisplayButton(parentData.id)
      --   button.callbacks.UpdateExpandButton()
      -- end
      -- OptionsPrivate.ClearOptions(parentData.id)
    end
  end
  return newData
end

local function DuplicateGroups(sourceParent, targetParent, mapping)
  for index, childId in pairs(sourceParent.controlledChildren) do
    local childData = WeakAuras.GetData(childId)
    if childData.controlledChildren then
      local newChildGroup = PrivateDuplicateAura(childData, targetParent.id)
      mapping[childData] = newChildGroup
      DuplicateGroups(childData, newChildGroup, mapping)
    end
  end
end

local function DuplicateAuras(sourceParent, targetParent, mapping)
  for index, childId in pairs(sourceParent.controlledChildren) do
    local childData = WeakAuras.GetData(childId)
    if childData.controlledChildren then
      DuplicateAuras(childData, mapping[childData], mapping)
    else
      PrivateDuplicateAura(childData, targetParent.id, true, index)
    end
  end
end

local function OnDuplicateClick(id)
  local data = WeakAuras.GetData(id)
  if not data then
    print("no data for ", id)
    return
  end
  if (WeakAuras.IsImporting()) then return end
  if data.controlledChildren then
    local newGroup = PrivateDuplicateAura(data)

    local mapping = {}
    -- This builds the group skeleton
    DuplicateGroups(data, newGroup, mapping)
    -- Do this after duplicating all groups
    -- local suspended = OptionsPrivate.Private.PauseAllDynamicGroups()
    -- And this fills in the leafs
    DuplicateAuras(data, newGroup, mapping)

    -- local button = OptionsPrivate.GetDisplayButton(newGroup.id)
    -- button.callbacks.UpdateExpandButton()

    -- for old, new in pairs(mapping) do
    --   local button = OptionsPrivate.GetDisplayButton(new.id)
    --   button.callbacks.UpdateExpandButton()
    -- end

    -- OptionsPrivate.SortDisplayButtons(nil, true)
    -- OptionsPrivate.PickAndEditDisplay(newGroup.id)

    -- OptionsPrivate.Private.ResumeAllDynamicGroups(suspended)
  else
    -- local new = OptionsPrivate.DuplicateAura(data)
    -- OptionsPrivate.SortDisplayButtons(nil, true)
    -- OptionsPrivate.PickAndEditDisplay(new.id)
  end
  print("duplicated ", id, " to ", data.id.." 2")
  return data.id.." 2"
end


local function convertToTenEighty(auraId)
  local d = WeakAurasSaved.displays
  local parentKey = "NnoggieUI 1440"
  local sizeMap = {
    [10] = 8,
    [12] = 10,
    [14] = 12,
    [15] = 13, --dh fury bar no momentum
    [16] = 16, --breath
    [18] = 14,
    [24] = 20, --demonbolt
    [30] = 22,
    [35] = 26,
    [40] = 30,
    [42] = 32,
    [60] = 45,
  }
  local groupOffsets = {
    ["NnoggieUI 1080 Health Pots, Potions, Racials, Trinkets"] = -234,
    ["NnoggieUI 1080 Defensive Speed and Externals"] = -190,

    ["NnoggieUI 1080 DK"] = 10, --main group yOffset
    ["N10 DK Unholy Runes"] = -202,
    ["N10 DK Frost Runes"] = -202,
    ["N10 DK Blood Runes"] = -202,
    ["N10 DK Unholy Runic Power"] = -209,
    ["N10 DK Frost Runic Power"] = -209,
    ["N10 DK Blood Runic Power"] = -209,
    ["N10 DK Unholy Procs"] = -184,
    ["N10 DK Frost Procs"] = -184,
    ["N10 DK Blood Procs"] = -184,
    ["N10 DK Unholy Main Abilities"] = -211,
    ["N10 DK Frost Main Abilities"] = -211,
    ["N10 DK Blood Main Abilities"] = -211,
    ["N10 DK Unholy Utility Abilities"] = -256,
    ["N10 DK Frost Utility Abilities"] = -256,
    ["N10 DK Blood Utility Abilities"] = -256,
    ["N10 DK Unholy Damage Procs"] = -281,
    ["N10 DK Frost Damage Procs"] = -281,
    ["N10 DK Blood Damage Procs"] = -281,
    ["N10 DK Notifiers"] = -330,

    ["NnoggieUI 1080 Warrior"] = 10, --main group yOffset
    ["N10 Warrior Arms Swingtimer"] = -198,
    ["N10 Warrior Arms Rage"] = -207,
    ["N10 Warrior Arms Procs"] = -184,
    ["N10 Warrior Arms Main Abilities"] = -209,
    ["N10 Warrior Arms Utility Abilities"] = -254,
    ["N10 Warrior Arms Damage Procs"] = -279,
    ["N10 Warrior Fury Rage"] = -202,
    ["N10 Warrior Fury Procs"] = -184,
    ["N10 Warrior Fury Main Abilities"] = -204,
    ["N10 Warrior Fury Utility Abilities"] = -249,
    ["N10 Warrior Fury Damage Procs"] = -274,
    ["N10 Warrior Protection Rage"] = -202,
    ["N10 Warrior Protection Procs"] = -184,
    ["N10 Warrior Protection Main Abilities"] = -204,
    ["N10 Warrior Protection Utility Abilities"] = -249,
    ["N10 Warrior Protection Damage Procs"] = -274,
    ["N10 Warrior Notifiers"] = -349.7,

    ["NnoggieUI 1080 Warlock"] = 10,
    ["N10 Warlock Mana"] = -201,
    ["N10 Warlock Soul Shards"] = -207,
    ["N10 Warlock Damage Procs"] = -279,
    ["N10 Warlock Utility Abilities"] = -254,
    ["N10 Warlock Demonology Procs"] = -184,
    ["N10 Warlock Demonology Main Abilities"] = -210,
    ["N10 Warlock Affliction Procs"] = -184,
    ["N10 Warlock Affliction Main Abilities"] = -210,
    ["N10 Warlock Destruction Procs"] = -184,
    ["N10 Warlock Destruction Main Abilities"] = -210,
    ["N10 Warlock Notifiers"] = -330,

    ["NnoggieUI 1080 Paladin"] = 10,
    ["N10 Paladin Dusk"] = -201,
    ["N10 Paladin Dawn"] = -201,
    ["N10 Paladin Mana"] = -201,
    ["N10 Paladin Holy Power Retribution"] = -207,
    ["N10 Paladin Holy Power Retribution Inner Grace"] = -207,
    ["N10 Paladin Holy Power Protection"] = -207,
    ["N10 Paladin Damage Procs"] = -279,
    ["N10 Paladin Utility Abilities"] = -254,
    ["N10 Paladin Retribution Procs"] = -184,
    ["N10 Paladin Retribution Main Abilities"] = -210,
    ["N10 Paladin Protection Procs"] = -184,
    ["N10 Paladin Protection Main Abilities"] = -210,
    ["N10 Paladin Notifiers"] = -330,

    ["NnoggieUI 1080 Evoker"] = 10,
    ["N10 Evoker Devastation Mana"] = -201,
    ["N10 Evoker Essences"] = -207,
    ["N10 Evoker Damage Procs"] = -279,
    ["N10 Evoker Utility Abilities"] = -254,
    ["N10 Evoker Devastation Procs"] = -184,
    ["N10 Evoker Devastation Main Abilities"] = -210,
    ["N10 Evoker Notifiers"] = -330,

    ["NnoggieUI 1080 Demon Hunter"] = 10,
    ["N10 Demon Hunter Havoc Momentum"] = -201,
    ["N10 Demon Hunter Vengeance Demon Spikes Active"] = -201,
    ["N10 Demon Hunter Havoc Fury Momentum"] = -207,
    ["N10 Demon Hunter Vengeance Fury"] = -207,
    ["N10 Demon Hunter Havoc Fury"] = -205,
    ["N10 Demon Hunter Damage Procs"] = -279,
    ["N10 Demon Hunter Utility Abilities"] = -254,
    ["N10 Demon Hunter Havoc Procs"] = -184,
    ["N10 Demon Hunter Havoc Main Abilities"] = -210,
    ["N10 Demon Hunter Vengeance Procs"] = -184,
    ["N10 Demon Hunter Vengeance Main Abilities"] = -210,
    ["N10 Demon Hunter Notifiers"] = -330,

    ["NnoggieUI 1080 Shaman"] = 10,
    ["N10 Shaman Enhancement Maelstrom"] = -205,
    ["N10 Shaman Damage Procs"] = -279,
    ["N10 Shaman Utility Abilities"] = -254,
    ["N10 Shaman Enhancement Procs"] = -184,
    ["N10 Shaman Enhancement Main Abilities"] = -210,
    ["N10 Shaman Notifiers"] = -330,

  }
  local groupXOffsets = {
    ["NnoggieUI 1080 Health Pots, Potions, Racials, Trinkets"] = -441,
    ["NnoggieUI 1080 Defensive Speed and Externals"] = -211,
  }

  local idMap = {
    ["NnoggieUI 1440"] = "NnoggieUI 1080",
    ["N14"] = "N10",
  }

  -- first collect all aura ids that we need to change
  local auraIdsToChange = {}

  local function addChildren(data)
    if data.controlledChildren then
      for _, childId in pairs(data.controlledChildren) do
        table.insert(auraIdsToChange, childId)
        addChildren(d[childId])
      end
    end
  end

  -- TODO: auraId is not used, make sure we use it and get all children with it instead of the current approach
  for id, data in pairs(d) do
    if string.find(id, parentKey) and strsub(id, strlen(id)) == "2" then
      table.insert(auraIdsToChange, id)
      addChildren(data)
    end
  end

  local renameId = function(id)
    local newId
    for searchKey, replacement in pairs(idMap) do
      if string.find(id, searchKey) then
        newId = string.gsub(id, searchKey, replacement)
        newId = string.sub(newId, 1, -3)
      end
    end
    return newId
  end

  local renameAnchor = function(anchor)
    local newAnchor
    for searchKey, replacement in pairs(idMap) do
      if string.find(anchor, searchKey) then
        newAnchor = string.gsub(anchor, searchKey, replacement)
      end
    end
    return newAnchor
  end

  for _, id in pairs(auraIdsToChange) do
    local newId = renameId(id)
    if newId then
      --vdt(d[id])
      --print("new: "..newId.." old: "..id)
      d[newId] = d[id]
      d[id] = nil
      d[newId].id = newId

      if d[newId].parent then
        local newParentId = renameId(d[newId].parent)
        if newParentId then
          d[newId].parent = newParentId
        end
      end

      local childrenIds = d[newId].controlledChildren

      if childrenIds then
        local newChildrenIds = {}
        for index, childId in ipairs(childrenIds) do
          local newChildId = renameId(childId)
          if newChildId then
            table.insert(newChildrenIds, newChildId)
          end
        end
        d[newId].controlledChildren = newChildrenIds
      end
      local data = d[newId]
      if data.regionType == "icon" then
        local mappedSize = sizeMap[data.width]
        if mappedSize then
          data.width = mappedSize
          data.height = mappedSize
        end
        if data.subRegions then
          for k, subRegion in pairs(data.subRegions) do
            if subRegion.type == "subtext" then
              local mappedSize = sizeMap[subRegion.text_fontSize]
              if mappedSize then
                data.subRegions[k].text_fontSize = mappedSize
              end
            end
          end
        end
      elseif data.regionType == "aurabar" then
        local mappedHeight = sizeMap[data.height]
        if mappedHeight then
          data.height = mappedHeight
        end
        local mappedWidth = sizeMap[data.width]
        if mappedWidth then
          data.width = mappedWidth
        end

        local anchor = data.anchorFrameFrame
        if anchor then
          data.anchorFrameFrame = renameAnchor(anchor)
        end
        if data.subRegions then
          for k, subRegion in pairs(data.subRegions) do
            if subRegion.type == "subtext" then
              local mappedSize = sizeMap[subRegion.text_fontSize]
              if mappedSize then
                data.subRegions[k].text_fontSize = mappedSize
              end
            end
          end
        end
      end

      local newGroupOffset = groupOffsets[data.id]
      if newGroupOffset then
        data.yOffset = newGroupOffset
      end

      local newGroupXOffset = groupXOffsets[data.id]
      if newGroupXOffset then
        data.xOffset = newGroupXOffset
      end
    end
  end
end

--convertToTenEighty("NnoggieUI 1440 DK  2")
--convertToTenEighty("NnoggieUI 1440 Warrior  2")
--convertToTenEighty("NnoggieUI 1440 Warlock 2")
--convertToTenEighty("NnoggieUI 1440 Paladin  2")
--convertToTenEighty("NnoggieUI 1440 Evoker  2")
--convertToTenEighty("NnoggieUI 1440 Demon Hunter 2")


--convertToTenEighty("NnoggieUI 1440 Health Pots, Potions, Racials, Trinkets 2")
-- convertToTenEighty("NnoggieUI 1440 Defensive Speed and Externals 2")

local function duplicateConvertExport(auraId)
  local duplicatedId = OnDuplicateClick(auraId)
  local newParentId = convertToTenEighty(duplicatedId)

  -- todo: export
  -- todo: delete
  -- need reload?
end

_G["NUI"] = _G["NUI"] or {}
_G["NUI"].OnDuplicateClick = OnDuplicateClick
