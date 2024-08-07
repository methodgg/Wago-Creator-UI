---@class ModuleConfig : table
---@field moduleName string
---@field lapModule LibAddonProfilesModule
---@field dropdownOptions fun(index: number): table
---@field copyFunc fun() | nil
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
---@field SerializeAsyncEx fun(self:LibSerialize, configForLS: table | nil, inTable: table) : function
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
