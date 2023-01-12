--[[
TheNexusAvenger

Stores settings.
--]]
--!strict

local NexusVRCharacterModel = script.Parent.Parent
local NexusEvent = require(NexusVRCharacterModel:WaitForChild("NexusInstance"):WaitForChild("Event"):WaitForChild("NexusEvent"))

local Settings ={}
Settings.__index = Settings
local StaticInstance = nil

export type Settings ={
    new: () -> (Settings),
    GetInstance: () -> (Settings),

    GetSetting: (self: Settings, Setting: string) -> (any),
    SetSetting: (self: Settings, Setting: string, Value: any) -> (),
    SetDefaults: (self: Settings, Defaults: {[string]: any}) -> (),
    SetOverrides: (self: Settings, Overrides: {[string]: any}) -> (),
    GetSettingsChangedSignal: (self: Settings, Setting: string) -> (NexusEvent.NexusEvent<>),
    Destroy: (self: Settings) -> (),
}



--[[
Creates a settings object.
--]]
function Settings.new(): Settings
    return (setmetatable({
        Defaults = {},
        Overrides = {},
        SettingsChangeEvents = {},
        SettingsCache = {},
    }, Settings) :: any) :: Settings
end

--[[
Returns a singleton instance of settings.
--]]
function Settings.GetInstance(): Settings
    if not StaticInstance then
        StaticInstance = Settings.new()
    end
    return StaticInstance
end

--[[
Returns the value of a setting.
--]]
function Settings:GetSetting(Setting: string): any
    --Return a cached entry if one exists.
    if self.SettingsCache[Setting] ~= nil then
        return self.SettingsCache[Setting]
    end

    --Get the table containing the setting.
    local Defaults, Overrides = self.Defaults, self.Overrides
    local SplitSettingNames = string.split(Setting, ".")
    for i = 1, #SplitSettingNames - 1 do
        Defaults = Defaults[SplitSettingNames[i]] or {}
        Overrides = Overrides[SplitSettingNames[i]] or {}
    end

    --Return the value.
    local Value = Overrides[SplitSettingNames[#SplitSettingNames]]
    if Value == nil then
        Value = Defaults[SplitSettingNames[#SplitSettingNames]]
    end
    self.SettingsCache[Setting] = Value
    return Value
end

--[[
Sets the value of a setting.
--]]
function Settings:SetSetting(Setting: string, Value: any): ()
    --Set the setting.
    local Overrides = self.Overrides
    local SplitSettingNames = string.split(Setting,".")
    for i = 1, #SplitSettingNames - 1 do
        if not Overrides[SplitSettingNames[i]] then
            Overrides[SplitSettingNames[i]] = {}
        end
        Overrides = Overrides[SplitSettingNames[i]]
    end
    Overrides[SplitSettingNames[#SplitSettingNames]] = Value
    self.SettingsCache[Setting] = Value

    --Fire the changed signal.
    local Event = self.SettingsChangeEvents[string.lower(Setting)]
    if Event then
        Event:Fire()
    end
end

--[[
Sets all the defaults.
--]]
function Settings:SetDefaults(Defaults: {[string]: any}): ()
    --Set the defaults.
    self.Defaults = Defaults
    self.SettingsCache = {}

    --Fire all the event changes.
    for _, Event in self.SettingsChangeEvents do
        Event:Fire()
    end
end

--[[
Sets all the overrides.
--]]
function Settings:SetOverrides(Overrides: {[string]: any}): ()
    --Set the overrides.
    self.Overrides = Overrides
    self.SettingsCache = {}

    --Fire all the event changes.
    for _, Event in self.SettingsChangeEvents do
        Event:Fire()
    end
end

--[[
Returns a changed signal for a setting.
--]]
function Settings:GetSettingsChangedSignal(Overrides: string): NexusEvent.NexusEvent<>
    Overrides = string.lower(Overrides)

    --Create the event if none exists.
    if not self.SettingsChangeEvents[Overrides] then
        self.SettingsChangeEvents[Overrides] = NexusEvent.new()
    end

    --Return the event.
    return self.SettingsChangeEvents[Overrides]
end

--[[
Destroys the settings.
--]]
function Settings:Destroy(): ()
    --Disconnect the settings.
    for _,Event in self.SettingsChangeEvents do
        Event:Disconnect()
    end
    self.SettingsChangeEvents = {}
end



return Settings