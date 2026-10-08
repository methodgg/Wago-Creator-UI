-- Blizzard Cooldown Manager: class-specific layouts picked from every character's cache.
local addon = select(2, ...)
local Packs = addon.Packs
local UI = addon.UI
local button, check, input, label, reset = UI.button, UI.check, UI.input, UI.label, UI.reset
local dragGhost, emptyList, managerList, managerRow = UI.dragGhost, UI.emptyList, UI.managerList, UI.managerRow
local closeModal, modal, safely = UI.closeModal, UI.modal, UI.safely
local function render() UI.render() end

local CDM = "Blizzard Cooldown Manager"
-- Blizzard's undo arrow: the layout goes back to the version saved before.
local KEEP = "common-icon-undo"
local ALERT = "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:14:14|t "
local KEPT = "|A:common-icon-undo:14:14|a "

-- A classAndSpecTag such as 121 is class 12 (Demon Hunter), spec 1 (Havoc).
local function specIcon(tag)
  local info = C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo
  local icon = info and select(4, info(tag % 10, false, false, nil, nil, nil, math.floor(tag / 10)))
  return icon or 134400
end

local function classColored(text, tag)
  local class = C_CreatureInfo and C_CreatureInfo.GetClassInfo(math.floor(tag / 10))
  local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class.classFile]
  return color and color.colorStr and ("|c" .. color.colorStr .. text .. "|r") or text
end

-- Class-colored layout name, with its character when it is not the one logged in.
local function layoutName(key, tag, character)
  local text = classColored(key, tag)
  if character and character ~= addon:CharacterKey() then text = text .. " |cff808080(" .. character .. ")|r" end
  return text
end

local function includedLayouts(pack)
  local result = {}
  for _, p in ipairs(Packs.Profiles(pack)) do
    if p.moduleName == CDM then table.insert(result, p) end
  end
  return result
end

-- Picks which Cooldown Manager layouts the pack exports; each one ships with every variation.
local function cooldownManager(pack)
  local query = ""
  local f = modal(CDM, 760, 600)
  local notes = label(f, "Give every Cooldown Manager profile a unique name. If two profiles share a name, only one of them "
    .. "can be imported. A good name is \"<YourName> <Spec>\".", 24, 58, 712, 13, { .7, .7, .7 })
  notes:SetWordWrap(true)
  label(f, "Exported CDM profiles will be available in all of your UI Pack variations.", 24, 92, 712, 13, { .7, .7, .7 })
  label(f, "Profiles from other characters are only available after logging into those characters at least once.",
    24, 110, 712, 13, { 1, .65, .3 }):SetWordWrap(true)
  label(f, "Your profiles", 24, 140, 344, 16)
  local includedHeading = label(f, "", 392, 140, 344, 16)
  local search = input(f, "", 24, 164, 344)
  label(f, "Click or drag a profile to move it between the lists.", 392, 174, 344, 12, { .55, .55, .55 })
  local available = managerList(f, "availableLayouts", 24, 206, 344, 290)
  local included = managerList(f, "includedLayouts", 392, 206, 344, 290)
  dragGhost({ available, included })

  local draw
  local function include(source)
    -- Packs puts every layout into all variations.
    safely(function()
      Packs.AddProfile(pack, CDM, source.key, source.key, nil, "cdm", source.character, source.classAndSpecTag)
    end)
    render(); draw()
  end
  local function exclude(p)
    safely(function() Packs.RemoveProfile(pack, p.id) end)
    render(); draw()
  end
  draw = function()
    reset(available.content); reset(included.content)
    local chosen, taken = includedLayouts(pack), {}
    for _, p in ipairs(chosen) do taken[(p.sourceCharacter or "") .. "|" .. p.sourceKey] = true end
    local y = 0
    for _, source in ipairs(addon:ProfileSources(CDM)) do
      local text = (source.key .. " " .. (source.character or "")):lower()
      if not taken[(source.character or "") .. "|" .. source.key] and text:find(query, 1, true) then
        managerRow(available, y, {
          icon = specIcon(source.classAndSpecTag), text = layoutName(source.key, source.classAndSpecTag, source.character),
          actionTexture = [[Interface\ChatFrame\ChatFrameExpandArrow]], tooltip = "Include in this UI Pack",
          onActivate = function() include(source) end, dropTarget = included,
        })
        y = y + 32
      end
    end
    if y == 0 then emptyList(available, query == "" and "No more profiles to include." or "No profiles match your search.") end
    available.content:SetHeight(math.max(1, y))
    y = 0
    -- Layouts Save All could not save are marked here, where they can be removed or keep their last capture.
    local problems = addon:GetCaptureProblems(pack)
    for _, p in ipairs(chosen) do
      local problem = problems[p.id]
      local kept = not problem and p.keepCapture and p.data and addon:CaptureProblem(p)
      -- Shared layout names only warn; the layout still saves.
      local nameWarning = addon:ProfileNameWarning(p)
      local text = layoutName(p.sourceKey, p.classAndSpecTag, p.sourceCharacter)
      local tooltip = problem and (problem .. "\nClick to remove it from this UI Pack.")
        or kept and ("Ships its last capture.\n" .. kept) or "Remove from this UI Pack"
      managerRow(included, y, {
        icon = specIcon(p.classAndSpecTag), text = ((problem or nameWarning) and ALERT or kept and KEPT or "") .. text,
        actionTexture = [[Interface\Buttons\UI-GroupLoot-Pass-Up]], dropTarget = available,
        tooltip = nameWarning and (nameWarning .. "\n\n" .. tooltip) or tooltip,
        onActivate = function() exclude(p) end,
        secondAtlas = KEEP, secondTooltip = p.keepCapture and "Stop keeping the last capture"
          or "Keep last capture\nShip the version you saved before until this layout can be saved again.",
        secondAction = p.data and (problem or p.keepCapture) and function()
          safely(function() Packs.KeepCapture(pack, p.id, not p.keepCapture) end)
          render(); draw()
        end or nil,
      })
      y = y + 32
    end
    if y == 0 then emptyList(included, "Click a profile on the left to include it.") end
    included.content:SetHeight(math.max(1, y))
    includedHeading:SetText("Included profiles (" .. #chosen .. ")")
  end
  search:SetScript("OnTextChanged", function(self) query = self:GetText():lower(); draw() end)
  search:SetFocus()
  -- Frozen layouts keep their last export, so tweaking a spec later does not change a published pack.
  check(f, "Update Cooldown Manager profiles when saving", not pack.cdmExportsFrozen, 24, 512,
    function(value) pack.cdmExportsFrozen = not value or nil end)
  button(f, "Done", 606, 552, 130, function() closeModal(); render() end)
  draw()
end

UI.CDM = CDM
UI.cooldownManager = cooldownManager
UI.includedLayouts = includedLayouts
UI.layoutName = layoutName
