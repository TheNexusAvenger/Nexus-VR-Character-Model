--[[
TheNexusAvenger

Loads Nexus VR Character Model.
--]]
--!strict

--Version information should be set right before distribution (not committed).
local VERSION_TAG = "dev"
local VERSION_COMMIT = "00000000"



local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterPlayer = game:GetService("StarterPlayer")
local VRService = game:GetService("VRService")

local Settings = require(script:WaitForChild("State"):WaitForChild("Settings")).GetInstance()

local NexusVRCharacterModel = {}



--[[
Sets the configuration to use. Intended to be
run once by the server.
--]]
function NexusVRCharacterModel:SetConfiguration(Configuration: any): ()
    --Create the value.
    local ConfigurationValue = script:FindFirstChild("Configuration")
    if not ConfigurationValue then
        ConfigurationValue = Instance.new("StringValue")
        ConfigurationValue.Name = "Configuration"
        ConfigurationValue.Parent = script
    end

    --Add the version.
    local HideVersion = false
    if Configuration.Extra then
        HideVersion = (Configuration.Extra.HideVersion == true)
    end
    if not Configuration.Version then
        Configuration.Version = {}
    end
    if not Configuration.Version.Tag then
        Configuration.Version.Tag = (HideVersion and "Hidden" or VERSION_TAG)
    end
    if not Configuration.Version.Commit then
        Configuration.Version.Commit = (HideVersion and "Hidden" or VERSION_COMMIT)
    end

    --Store the configuration.
    ConfigurationValue.Value = HttpService:JSONEncode(Configuration)
    Settings:SetDefaults(Configuration)
end

--[[
Loads Nexus VR Character Model.
--]]
function NexusVRCharacterModel:Load(): ()
    --Return if a version is already loaded.
    if ReplicatedStorage:FindFirstChild("NexusVRCharacterModel") then
        return
    end

    --Rename and move the script to ReplicatedStorage.
    script.Name = "NexusVRCharacterModel"
    script:WaitForChild("NexusVRCore").Parent = ReplicatedStorage
    script.Parent = ReplicatedStorage;

    --Enable AvatarGestures.
    VRService.AvatarGestures = true

    --Output any warnings.
    (require(ReplicatedStorage:WaitForChild("NexusVRCharacterModel"):WaitForChild("Util"):WaitForChild("Warnings")) :: any)()

    --Set up the client scripts.
    local NexusVRCharacterModelClientLoader = script:WaitForChild("NexusVRCharacterModelClientLoader")
    for _,Player in pairs(Players:GetPlayers()) do
        task.spawn(function()
            --Create and store a ScreenGui with the script.
            --This prevents the script disappearing on respawn.
            local ScreenGui = Instance.new("ScreenGui")
            ScreenGui.ResetOnSpawn = false
            ScreenGui.Name = "NexusVRCharacterModelClientLoader"
            NexusVRCharacterModelClientLoader:Clone().Parent = ScreenGui
            ScreenGui.Parent = Player:WaitForChild("PlayerGui")
        end)
    end
    NexusVRCharacterModelClientLoader:Clone().Parent = StarterPlayer:WaitForChild("StarterPlayerScripts")

    --Load Nexus VR Backpack.
    if Settings:GetSetting("Extra.NexusVRBackpackEnabled") ~= false then
        (require(10728805649) :: any)()
    end
end




NexusVRCharacterModel.Api = (require(script:WaitForChild("Api")) :: any)()
return NexusVRCharacterModel