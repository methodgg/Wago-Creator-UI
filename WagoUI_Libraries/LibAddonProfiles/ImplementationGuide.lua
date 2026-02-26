--If you would like to have your AddOn integrated into WagoUI Packs we need a couple of accessible functions that our AddOns can call to manage profiles.
--In general the immplementation of the functions is up to you but make sure the behavior of your functions matches the expected behavior as described in the comments.
--IMPORTANT NOTE: If your AddOn needs to ReloadUI() after importing / setting profiles make sure NOT to call reloads within these functions (or their tail calls) directly. WagoUI will instead mark your AddOn has "needing reload" and handle reloads for all AddOns at the end of the setup together.

--For WagoUI to have access to your functions it is recommended to create a separate global API table and place all the needed functions in it.
YourAddonAPI = YourAddonAPI or {}


---@param profileKey string --the name of the profile to be exported
---@return string --the encoded profile string that can be imported by other users
function YourAddonAPI:ExportProfile(profileKey)
  -- NOTE: If your AddOn has no profile system we will call this function with "Global" as the profileKey
  -- NOTE: This function should NOT just export the CURRENT profile (if your AddOn has a profile system) but should be able to export any profile by name.

  -- It is recommended to use Blizzard functions from C_EncodingUtil for encoding / decoding.
  -- Add nil checks and error handling as needed, this is just a basic example of how to use the functions.

  local profileData = YourInternalDB.profiles[profileKey]
  local serialized = C_EncodingUtil.SerializeCBOR(profileData)
  local compressed = C_EncodingUtil.CompressString(serialized, Enum.CompressionMethod.Deflate,
    Enum.CompressionLevel.OptimizeForSize)
  local encoded = C_EncodingUtil.EncodeBase64(compressed)
  return encoded
end

---@param profileString string --the encoded profile string to be imported
---@param profileKey string --the name of the profile to be imported
function YourAddonAPI:ImportProfile(profileString, profileKey)
  -- NOTE: If your AddOn has no profile system we will call this function with "Global" as the profileKey and you should just import the data to your global settings.
  -- NOTE: This function should import the profile data to your AddOn and make it the current active profile if your AddOn has a profile system.
  -- NOTE: Make sure that the new profile is named after the profileKey passed to the function if you have a profile system. For AddOns with only Global settings you can ignore the profileKey.

  local decoded = C_EncodingUtil.DecodeBase64(profileString)
  local decompressed = C_EncodingUtil.DecompressString(decoded, Enum.CompressionMethod.Deflate)
  local deserialized = C_EncodingUtil.DeserializeCBOR(decompressed)
  YourInternalDB.profiles[profileKey] = deserialized
  local currentCharacterName = UnitName("player").."-"..GetRealmName()
  YourInternalDB.profileKeys[currentCharacterName] = profileKey --just an example
end

---@param profileString string --the profile string to decode
---@return table --the decoded profile data as a table
function YourAddonAPI:DecodeProfileString(profileString)
  -- NOTE: This function should decode the profile string and return the profile data as a table. This is used for comparing profiles and generating changelogs for creators.

  local decoded = C_EncodingUtil.DecodeBase64(profileString)
  local decompressed = C_EncodingUtil.DecompressString(decoded, Enum.CompressionMethod.Deflate)
  local deserialized = C_EncodingUtil.DeserializeCBOR(decompressed)
  return deserialized
end

---@param profileKey string -- profileKey of an existing profile
function YourAddonAPI:SetProfile(profileKey)
  -- NOTE: This function should set the current active profile to the profile with the given profileKey. This is used when users select a profile from the list of available profiles.
  local currentCharacterName = UnitName("player").."-"..GetRealmName()
  YourInternalDB.profileKeys[currentCharacterName] = profileKey
end

---@return table<string, boolean>  -- a table of all available profile keys in the format [profileKey] = true
function YourAddonAPI:GetProfileKeys()
  -- NOTE: This function should return a table of all available profile keys in the format [profileKey] = true, this is used to check for duplicates and validate profile keys.
  -- NOTE: If your AddOn has no profile system just return a table with "Global" as the only key.

  local profileKeys = {}
  for key, _ in pairs(YourInternalDB.profiles) do
    profileKeys[key] = true
  end
  return profileKeys
end

---@return string --the profileKey of the currently active profile
function YourAddonAPI:GetCurrentProfileKey()
  -- NOTE: This function should return the profile key of the currently active profile. This helps Creators exporting profiles correctly.
  -- NOTE: If your AddOn has no profile system just return "Global".

  local currentCharacterName = UnitName("player").."-"..GetRealmName()
  return YourInternalDB.profileKeys[currentCharacterName] or "Global"
end

function YourAddonAPI:OpenConfig()
  -- NOTE: This function should open the configuration interface of your AddOn.
  -- NOTE: If your AddOn has no configuration interface you can leave this function empty or just print a message to the user.
  -- NOTE: If your AddOn uses Editmode for configuration leave this function empty, we will open the Editmode config when the user tries to open the config for your AddOn.
  YourAddonConfigPanel:Show()
end

function YourAddonAPI:CloseConfig()
  -- NOTE: This function should close the configuration interface of your AddOn if it has one.
  YourAddonConfigPanel:Hide()
end
