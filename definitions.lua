---@class LibAddonProfiles : table
---@field GetModule fun(self, moduleName: string) : LibAddonProfilesModule
---@field GetAllModules fun(self) : table<string, LibAddonProfilesModule>
---@field GenericEncode fun(self, profileKey : string , data: table) : string
---@field GenericDecode fun(self, profileString : string) : string | nil, table | nil, table | nil

---@class LibAddonProfilesPrivate : table
---@field modules table<string, LibAddonProfilesModule>
---@field GenericEncode fun(self, profileKey : string , data: table) : string
---@field GenericDecode fun(self, profileString : string) : string | nil, table | nil, table | nil
---@field DeepCompareAsync fun(self, tableA : table, tableB : table, ignoredKeys: table | nil) : boolean
---@field PrintError fun(self, ...)
---@field LibSerializeSerializeAsyncEx fun(self, configForLS : table , inTable: table) : string
---@field LibSerializeDeserializeAsync fun(self, serialized: string) : table

---@class LibAddonProfilesModule : table
---@field moduleName string
---@field slash string
---@field icon number | string
---@field isLoaded fun() : boolean
---@field needsInitialization fun() : boolean
---@field openConfig fun() : nil
---@field closeConfig fun() : nil
---@field preventRename boolean?
---@field exportProfile fun(profileKey: string) : string | nil
---@field importProfile fun(profileString: string, profileKey: string, isDuplicateProfile?: boolean)
---@field testImport fun(profileString: string, profileKey: string | nil, profileData: table| nil, rawData: table | nil) : string | nil
---@field isDuplicate fun(profileKey: string) : boolean
---@field needReloadOnImport? boolean
---@field needProfileKey? boolean
---@field exportGroup? fun(profileKey: string)
---@field getProfileKeys? fun() : table<string, any>
---@field getCurrentProfileKey? fun() : string
---@field setProfile? fun(profileKey: string)
---@field areProfileStringsEqual fun(profileStringA: string | table, profileStringB: string | table) : areEqual: boolean, changedEntries: table | nil, removedEntries: table | nil

---@class ModuleConfig : table
---@field moduleName string
---@field lapModule LibAddonProfilesModule
---@field dropdownOptions fun(index: number): table
---@field copyFunc fun() | nil
---@field hookRefresh fun() | nil
---@field copyButtonTooltipText string | nil
---@field sortIndex number | nil

---@class LibDeflateAsync
---@field CompressDeflate fun(self: LibDeflateAsync, input: string, options: table): string
---@field EncodeForPrint fun(self: LibDeflateAsync, input: string): string)
---@field EncodeForWoWAddonChannel fun(self: LibDeflateAsync, input: string): string
---@field DecodeForPrint fun(self: LibDeflateAsync, input: string): string
---@field DecodeForWoWAddonChannel fun(self: LibDeflateAsync, input: string): string
---@field DecompressDeflate fun(self: LibDeflateAsync, input: string): string

---@class LibCompress
---@field Decompress fun(self: LibCompress, input: string): string
---@field GetAddonEncodeTable fun(self: LibCompress): table
---@field CompressHuffman fun(self: LibCompress, input: string): string
---@field DecompressHuffman fun(self: LibCompress, input: string): string
---@class AceSerializer-3.0Async
---@field Serialize fun(self: AceSerializer-3.0Async, input: any): string
---@field Deserialize fun(self: AceSerializer-3.0Async, input: string): boolean, table | nil

---@class LibSerialize
---@field SerializeAsyncEx fun(self:LibSerialize, configForLS: table, inTable: table) : function
---@field DeserializeAsync fun(self:LibSerialize, serialized: string) : function

---@class LibAsync : table
---@field GetHandler fun(self, config: LibAsyncConfig | nil) : LibAsyncHandler

---@class LibAsyncConfig
---@field type "everyFrame" The type of handler to create.
---@field maxTime number The maximum time in milliseconds to spend on a single update.
---@field maxTimeCombat number The maximum time in milliseconds to spend on a single update while in dungeon combat.
---@field errorHandler fun(msg: string, stacktrace?: string, name?: string) The error handler to use when a coroutine errors.

---@class LibAsyncHandler
---@field size number
---@field frame table
---@field update table
---@field CancelAsync fun(self, name: string)
---@field Async fun(self, func: function, name: string, singleton: boolean)
