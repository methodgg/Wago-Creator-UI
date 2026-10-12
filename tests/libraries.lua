-- Run from the repository root: lua tests/no_ui_framework.lua (Lua 5.1).
-- WagoUI draws its own controls (WagoUI/ui/Controls.lua). Details! Framework and the LibWagoFramework wrapper
-- around it must not come back through the files the addon loads or the packager's externals.
local banned = { "DetailsFramework", "LibDFramework", "Details%-Framework", "LibWagoFramework" }

local function read(path)
  local file = assert(io.open(path, "rb"), "Missing file: " .. path)
  local text = file:read("*a")
  file:close()
  return text
end

local checked = 0
local function check(path)
  local text = read(path)
  for _, pattern in ipairs(banned) do
    assert(not text:find(pattern), path .. " refers to " .. pattern:gsub("%%", ""))
  end
  checked = checked + 1
  return text
end

-- Follows every Script and Include from an XML file. Third-party libraries come from the packager and are skipped;
-- the file that lists them is still checked.
local function walk(path)
  for _, pattern in ipairs(banned) do
    assert(not path:find(pattern), path .. " is loaded")
  end
  local text = check(path)
  if not path:find("%.xml$") then return end
  local dir = path:match("^(.*)/")
  for file in text:gmatch("file=[\"']([^\"']+)[\"']") do
    local child = dir .. "/" .. file:gsub("\\", "/")
    if not child:find("^WagoUI/libs/[^/]+/") then walk(child) end
  end
end

for line in check("WagoUI/WagoUI.toc"):gmatch("[^\r\n]+") do
  if not line:find("^#") then walk("WagoUI/" .. line:gsub("\\", "/")) end
end
check("WagoUI/pkgmeta.yaml")
assert(checked > 20, "The load files were not followed")
print(checked .. " loaded files and the packager config are free of Details! Framework.")
