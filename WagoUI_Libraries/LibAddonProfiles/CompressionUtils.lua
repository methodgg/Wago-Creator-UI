---@class LAPLoadingNamespace
local loadingAddonNamespace = select(2, ...)
---@class LibAddonProfilesPrivate
local private = loadingAddonNamespace.GetLibAddonProfilesInternal and loadingAddonNamespace:GetLibAddonProfilesInternal()
if (not private) then return end

---@param profileKey string
---@param profile table
---@param moduleName string
---@return string profileString The encoded profile string
function private:GenericEncode(profileKey, profile, moduleName)
  local Serializer = LibStub:GetLibrary("AceSerializer-3.0Async")
  local LibDeflate = LibStub:GetLibrary("LibDeflateAsync")
  local data = {
    profileKey = profileKey,
    profile = profile,
    moduleName = moduleName
  }
  local serialized = Serializer:Serialize(data)
  coroutine.yield()
  local compressed = LibDeflate:CompressDeflate(serialized, { level = 5 })
  coroutine.yield()
  local encoded = LibDeflate:EncodeForPrint(compressed)
  coroutine.yield()
  return encoded
end

---@param profileString string
---@return string | nil profileKey
---@return table | nil profileData only use this if the data was encapsulated in the first place, use rawData instead otherwise
---@return table | nil rawData
---@return string | nil moduleName
function private:GenericDecode(profileString)
  local Serializer = LibStub:GetLibrary("AceSerializer-3.0Async")
  local LibDeflate = LibStub:GetLibrary("LibDeflateAsync")
  local decoded = LibDeflate:DecodeForPrint(profileString)
  coroutine.yield()
  if not decoded then return end
  local decompressed = LibDeflate:DecompressDeflate(decoded)
  coroutine.yield()
  if not decompressed then return end
  local success, data = Serializer:Deserialize(decompressed)
  coroutine.yield()
  if success and data then
    return data.profileKey, data.profile, data, data.moduleName
  else
    return
  end
end

---@param tbl1 table
---@param tbl2 table
---@param ignoredKeys table | nil
---@param debug boolean | nil If true, print debug messages to chat
---@return boolean areEqual
function private:DeepCompareAsync(tbl1, tbl2, ignoredKeys, debug)
  if tbl1 == tbl2 then
    return true
  elseif type(tbl1) == "table" and type(tbl2) == "table" then
    for key1, value1 in pairs(tbl1) do
      if ignoredKeys and ignoredKeys[key1] then
        -- ignore this key
      else
        local value2 = tbl2[key1]
        if value2 == nil then
          -- avoid the type call for missing keys in tbl2 by directly comparing with nil
          if debug then
            vdt(key1.." is missing in tbl2")
          end
          return false
        elseif value1 ~= value2 then
          if type(value1) == "table" and type(value2) == "table" then
            coroutine.yield()
            if not private:DeepCompareAsync(value1, value2, ignoredKeys, debug) then
              if debug then
                vdt(key1.." is table and not equal in tbl2")
                vdt(value1, "value1")
                vdt(value2, "value2")
              end
              return false
            end
          elseif type(value1) == "number" and type(value2) == "number" and math.abs(value1 - value2) < 0.001 then
            -- floating point inaccuracy, consider them equal in this case
            if debug then
              vdt(key1.." floating point inaccuracy")
              vdt(value1, "value1")
              vdt(value2, "value2")
            end
            return true
          else
            if debug then
              vdt(key1.." is not equal in tbl2")
              vdt(value1, "value1")
              vdt(value2, "value2")
            end
            return false
          end
        end
      end
    end
    -- check for missing keys in tbl1
    for key2, _ in pairs(tbl2) do
      if tbl1[key2] == nil then
        if debug then
          vdt(key2.." is missing in tbl1")
        end
        return false
      end
    end
    return true
  end
  return false
end

---@param configForLS table | nil
---@param inTable table
---@return string serialized
function private:LibSerializeSerializeAsyncEx(configForLS, inTable)
  local LibSerialize = LibStub("LibSerialize")
  local co_handler = LibSerialize:SerializeAsyncEx(configForLS, inTable)
  local completed, serialized
  repeat
    completed, serialized = co_handler()
  until completed
  return serialized
end

---@param serialized string
---@return table table | nil
function private:LibSerializeDeserializeAsync(serialized)
  local LibSerialize = LibStub("LibSerialize")
  local co_handler = LibSerialize:DeserializeAsync(serialized)
  local completed, success, tab, str
  repeat
    completed, success, tab, str = co_handler()
  until completed
  return tab
end

---@param orig any
---@return any copy
function private:DeepCopyAsync(orig)
  local orig_type = type(orig)
  local copy
  coroutine.yield()
  if orig_type == "table" then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[self:DeepCopyAsync(orig_key)] = self:DeepCopyAsync(orig_value)
    end
    setmetatable(copy, self:DeepCopyAsync(getmetatable(orig)))
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end
