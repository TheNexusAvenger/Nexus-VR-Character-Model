--Displays warnings when loading Nexus VR Character Model.
--!strict

local HttpService = game:GetService("HttpService")



return function(): ()
    --Load the configuration.
    local ConfigurationValue = script.Parent.Parent:WaitForChild("Configuration")
    local Configuration = HttpService:JSONDecode(ConfigurationValue.Value)

    --Determine the suppressed warnings.
    local SupressedWarnings = {}
    if Configuration.Output and Configuration.Output.SuppressWarnings then
        for _, WarningName in Configuration.Output.SuppressWarnings do
            SupressedWarnings[string.lower(WarningName)] = true
        end
    end
    if SupressedWarnings["all"] then return end

    --Build the warnings.
    local Warnings = {
        {
            Key = "MissingNexusVRBackpackEnabled",
            Message = "The configuration entry Extra.NexusVRBackpackEnabled is missing (defaults to true).",
            Condition = function()
               return Configuration.Extra == nil or Configuration.Extra.NexusVRBackpackEnabled == nil
            end,
        },
        {
            Key = "MissingAllowClientToOutputLoadedMessage",
            Message = "The configuration entry Extra.AllowClientToOutputLoadedMessage is missing (defaults to true).",
            Condition = function()
               return Configuration.Output == nil or Configuration.Output.AllowClientToOutputLoadedMessage == nil
            end,
        },
        {
            Key = "MissingDisableHeadLocked",
            Message = "The configuration entry Camera.DisableHeadLocked is missing (defaults to true).",
            Condition = function()
               return Configuration.Camera == nil or Configuration.Camera.DisableHeadLocked == nil
            end,
        },
    }

    --Output the warnings.
    for _, Warning in Warnings do
        if not SupressedWarnings[string.lower(Warning.Key)] and Warning.Condition() then
            warn(Warning.Message)
            warn(`\tThis warning can be disabled by adding \"{Warning.Key}\" or \"All\" to Output.SuppressWarnings in the configuration of Nexus VR Character Model.`)
        end
    end
end