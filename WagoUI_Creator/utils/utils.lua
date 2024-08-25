---@class WagoUICreator
local addon = select(2, ...)

---@param table table
---@return number | nil
function addon:TableNumEntries(table)
  if not table then
    return nil
  end
  local num = 0
  for _, _ in pairs(table) do
    num = num + 1
  end
  return num
end

---@param table table
---@param conditionFunc function
---@return number | nil Returns the index of the first element that satisfies the condition function
function addon:TableGetIndex(table, conditionFunc)
  if not table then
    return nil
  end
  for index, value in pairs(table) do
    if conditionFunc(value) then
      return index
    end
  end
  return nil
end
