---@class WagoUI
local addon = select(2, ...)
local L = addon.L

local UPDATE_CHECK_DELAY = 15
local LINK_TYPE = "garrmission"
local LINK_SUBTYPE = "wagoui"

local function GenerateCommandHyperlink(command, ...)
  local prefix =
    string.format("|cff82c5ff|H" .. LINK_TYPE .. ":" .. LINK_SUBTYPE .. ":%1$s:%2$s|h[", command, string.join(" ", ...))
  local suffix = "]|h|r"
  return prefix, suffix
end

local function ProcessCommand(command, ...)
  if command == "open" then
    local packId = string.trim((...))
    addon:ShowFrame()
    addon:SetActivePack(packId)
  end
end

local function OnHyperlinkClick(link)
  local linkType, linkSubtype, linkCommand = string.split(":", link, 3)
  if linkType == LINK_TYPE and linkSubtype == LINK_SUBTYPE then
    ProcessCommand(string.split(":", linkCommand))
  end
end

hooksecurefunc("SetItemRef", OnHyperlinkClick)

---@param releaseNotes table<string, string>
---@return number
local function GetLatestReleaseNoteTimestamp(releaseNotes)
  local latestTimestamp = 0
  for timestampStr in pairs(releaseNotes) do
    local timestamp = tonumber(timestampStr)
    if timestamp and timestamp > latestTimestamp then
      latestTimestamp = timestamp
    end
  end
  return latestTimestamp
end

---@param packId string
---@param pack table
local function PrintNewUpdate(packId, pack)
  local prefix, suffix = GenerateCommandHyperlink("open", packId)
  local link = string.format(L["UPDATE_LINK_TEXT"], prefix, suffix)
  addon:AddonPrint("Updates available for " .. pack.localName .. "! " .. link)
end

function addon:CheckAvailableUpdates()
  if not WagoUI_Storage then
    return
  end
  C_Timer.After(
    UPDATE_CHECK_DELAY,
    function()
      for packId, pack in pairs(WagoUI_Storage) do
        if not pack.isLocal then
          local latest = GetLatestReleaseNoteTimestamp(pack.releaseNotes)
          local latestSeen = addon.db.latestSeenReleasenotes[packId]
          if not latestSeen then -- don't notify on new pack
            addon.db.latestSeenReleasenotes[packId] = latest
          elseif latest > latestSeen then
            PrintNewUpdate(packId, pack)
            addon.db.latestSeenReleasenotes[packId] = latest
          end
        end
      end
    end
  )
end
