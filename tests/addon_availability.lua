-- Run with Lua 5.1. Exercise the real library helper with a cold addon inventory.
local private, calls = {}, 0
local reasons = { "DISABLED", "DEP_DISABLED", "DEMAND_LOADED", "DEP_MISSING", "INTERFACE_VERSION" }
C_AddOns = {
  GetNumAddOns = function() return 500 end,
  GetAddOnInfo = function(index)
    calls = calls + 1
    return "Addon" .. index, "", "", index > #reasons, reasons[index]
  end,
  EnableAddOn = function() end,
}
assert(loadfile("WagoUI_Libraries/LibAddonProfiles/Utils.lua"))("WagoUI", {
  GetLibAddonProfilesInternal = function() return private end,
})
assert(not private:CanEnableAnyAddOn(nil))
assert(not private:CanEnableAnyAddOn({}))
for i = 1, 79 do assert(not private:CanEnableAnyAddOn({ "Missing" .. i })) end
assert(private:CanEnableAnyAddOn({ "Addon1" }))
assert(private:CanEnableAnyAddOn({ "Addon2" }))
assert(private:CanEnableAnyAddOn({ "Addon3" }))
assert(not private:CanEnableAnyAddOn({ "Addon4" }))
assert(not private:CanEnableAnyAddOn({ "Addon5" }))
assert(private:CanEnableAnyAddOn({ "Missing", "Addon500" }))
local coldCalls = calls
for i = 1, 79 do assert(not private:CanEnableAnyAddOn({ "Missing" .. i })) end
assert(calls == coldCalls, "Warm status checks rescan installed addons")
print("Cold inventory calls: " .. coldCalls .. "; warm inventory calls: " .. (calls - coldCalls))
assert(coldCalls == 500, "First open scans the inventory more than once")
print("Addon availability checks passed: disabled, demand-loaded, missing and blocked dependencies.")
