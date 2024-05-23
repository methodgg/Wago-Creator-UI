local addonName, addon = ...;

function addon:AddonPrint(...)
  print("|c"..addon.color..addonName.."|r:", tostringall(...));
end

function addon:AddonPrintError(...)
  print("|c"..addon.color..addonName.."|r|cffff9117:|r", tostringall(...));
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
