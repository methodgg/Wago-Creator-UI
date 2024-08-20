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
