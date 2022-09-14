--[[
TheNexusAvenger

Stores settings.
--]]

local NexusVRCharacterModel = require(script.Parent.Parent)
local NexusObject = NexusVRCharacterModel:GetResource("NexusInstance.NexusObject")
local NexusEvent = NexusVRCharacterModel:GetResource("NexusInstance.Event.NexusEvent")

local Settings = NexusObject:Extend()
Settings:SetClassName("Settings")



--[[
Creates a settings object.
--]]
function Settings:__new()
    self:InitializeSuper()

    --Store the settings.
    self.Defaults = {}
    self.Overrides = {}
    self.SettingsChangeEvents = {}
    self.SettingsCache = {}
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
    local Defaults,Overrides = self.Defaults,self.Overrides
    local SplitSettingNames = string.split(Setting,".")
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
function Settings:SetSetting(Setting: string, Value: any): nil
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
function Settings:SetDefaults(Defaults: {[string]: any}): nil
    --Set the defaults.
    self.Defaults = Defaults
    self.SettingsCache = {}

    --Fire all the event changes.
    for _, Event in pairs(self.SettingsChangeEvents) do
        Event:Fire()
    end
end

--[[
Sets all the overrides.
--]]
function Settings:SetOverrides(Overrides: {[string]: any}): nil
    --Set the overrides.
    self.Overrides = Overrides
    self.SettingsCache = {}

    --Fire all the event changes.
    for _, Event in pairs(self.SettingsChangeEvents) do
        Event:Fire()
    end
end

--[[
Returns a changed signal for a setting.
--]]
function Settings:GetSettingsChangedSignal(SettingName: string): CustomEvent
    SettingName = string.lower(SettingName)

    --Create the event if none exists.
    if not self.SettingsChangeEvents[SettingName] then
        self.SettingsChangeEvents[SettingName] = NexusEvent.new()
    end

    --Return the event.
    return self.SettingsChangeEvents[SettingName]
end

--[[
Destroys the settings.
--]]
function Settings:Destroy(): nil
    --Disconnect the settings.
    for _,Event in pairs(self.SettingsChangeEvents) do
        Event:Disconnect()
    end
    self.SettingsChangeEvents = {}
end



return Settings