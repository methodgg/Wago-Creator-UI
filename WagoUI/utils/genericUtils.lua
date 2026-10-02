---@class WagoUI
local addon = select(2, ...)

local addonNameForPrint = "|cFFC1272DWago|r UI Packs"

function addon:AddonPrint(...)
  print(addonNameForPrint..":", tostringall(...))
end

function addon:AddonPrintError(...)
  print(addonNameForPrint.."|r|cffff9117:|r", tostringall(...))
end
