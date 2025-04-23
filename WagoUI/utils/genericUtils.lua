---@class WagoUI
local addon = select(2, ...)

local addonNameForPrint = "|cFFC1272DWago|r UI Packs"

function addon:AddonPrint(...)
  print(addonNameForPrint..":", tostringall(...))
end

function addon:AddonPrintError(...)
  print(addonNameForPrint.."|r|cffff9117:|r", tostringall(...))
end

do
  local f = CreateFrame("frame")
  local tx = f:CreateTexture()
  function addon:TestTexture(path)
    tx:SetTexture("?")
    tx:SetTexture(path)
    return tx:GetTexture()
  end
end
