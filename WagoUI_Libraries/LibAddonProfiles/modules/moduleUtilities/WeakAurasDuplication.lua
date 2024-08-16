-- START duplication, code from WA addon
local function privateAddParents(data)
  local parent = data.parent
  if (parent) then
    local parentData = WeakAuras.GetData(parent)
    WeakAuras.Add(parentData)
    privateAddParents(parentData)
  end
end

local function privateDuplicateAura(data, newParent, massEdit, targetIndex)
  local base_id = data.id .. " "
  local num = 2

  -- if the old id ends with a number increment the number
  local matchName, matchNumber = string.match(data.id, "^(.-)(%d*)$")
  matchNumber = tonumber(matchNumber)
  if (matchName ~= "" and matchNumber ~= nil) then
    base_id = matchName
    num = matchNumber + 1
  end

  local new_id = base_id .. num
  while (WeakAuras.GetData(new_id)) do
    new_id = base_id .. num
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
      privateAddParents(parentData)
    -- ignore UI stuff, we don't need
    end
  end
  return newData
end

local function duplicateGroups(sourceParent, targetParent, mapping)
  for index, childId in pairs(sourceParent.controlledChildren) do
    local childData = WeakAuras.GetData(childId)
    if childData.controlledChildren then
      local newChildGroup = privateDuplicateAura(childData, targetParent.id)
      mapping[childData] = newChildGroup
      duplicateGroups(childData, newChildGroup, mapping)
    end
  end
end

local function duplicateAuras(sourceParent, targetParent, mapping)
  for index, childId in pairs(sourceParent.controlledChildren) do
    local childData = WeakAuras.GetData(childId)
    if childData.controlledChildren then
      duplicateAuras(childData, mapping[childData], mapping)
    else
      privateDuplicateAura(childData, targetParent.id, true, index)
    end
  end
end

local function duplicateDisplay(id)
  local data = WeakAuras.GetData(id)
  if (WeakAuras.IsImporting()) then
    return
  end
  if data.controlledChildren then
    local newGroup = privateDuplicateAura(data)
    local mapping = {}
    -- This builds the group skeleton
    duplicateGroups(data, newGroup, mapping)
    -- And this fills in the leafs
    duplicateAuras(data, newGroup, mapping)
  end
end
-- END duplication
