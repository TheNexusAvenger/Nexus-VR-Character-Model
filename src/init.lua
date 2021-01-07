--[[
TheNexusAvenger

Loads Nexus VR Character Model.
--]]

--Client should send replication at 30hz.
--A buffer is added in case this rate is exceeded
--briefly, such as an unstable connection.
local REPLICATION_RATE_LIMIT = 35



local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterPlayer = game:GetService("StarterPlayer")

local NexusProject = require(script:WaitForChild("NexusProject"))

local NexusVRCharacterModel = NexusProject.new(script)
NexusVRCharacterModel.SingletonInstances = {}



--[[
Sets the configuration to use. Intended to be
run once by the server.
--]]
function NexusVRCharacterModel:SetConfiguration(Configuration)
    --Create the value.
    local ConfigurationValue = script:FindFirstChild("Configuration")
    if not ConfigurationValue then
        ConfigurationValue = Instance.new("StringValue")
        ConfigurationValue.Name = "Configuration"
        ConfigurationValue.Parent = script
    end

    --Store the configuration.
    ConfigurationValue.Value = HttpService:JSONEncode(Configuration)
end

--[[
Loads Nexus VR Character Model.
--]]
function NexusVRCharacterModel:Load()
    --Return if a version is already loaded.
    if ReplicatedStorage:FindFirstChild("NexusVRCharacterModel") then
        return
    end

    --Rename and move the script to ReplicatedStorage.
    script.Name = "NexusVRCharacterModel"
    script:WaitForChild("NexusVRCore").Parent = ReplicatedStorage
    script.Parent = ReplicatedStorage

    --Set up the client scripts.
    local NexusVRCharacterModelClientLoader = script:WaitForChild("NexusVRCharacterModelClientLoader")
    for _,Player in pairs(Players:GetPlayers()) do
        coroutine.wrap(function()
            --Create and store a ScreenGui with the script.
            --This prevents the script disappearing on respawn.
            local ScreenGui = Instance.new("ScreenGui")
            ScreenGui.ResetOnSpawn = false
            ScreenGui.Name = "NexusVRCharacterModelClientLoader"
            NexusVRCharacterModelClientLoader:Clone().Parent = ScreenGui
            ScreenGui.Parent = Player:WaitForChild("PlayerGui")
        end)()
    end
    NexusVRCharacterModelClientLoader:Clone().Parent = StarterPlayer:WaitForChild("StarterPlayerScripts")

    --Set up replication.
    local RateLimter = NexusVRCharacterModel:GetResource("State.RateLimiter")
    local UpdateRateLimiter = RateLimter.new(REPLICATION_RATE_LIMIT)
    local UpdateInputsEvent = Instance.new("RemoteEvent")
    UpdateInputsEvent.Name = "UpdateInputs"
    UpdateInputsEvent.Parent = script
    UpdateInputsEvent.OnServerEvent:Connect(function(Player,HeadCFrame,LeftHandCFrame,RightHandCFrame)
        --Ignore the input if 3 CFrames aren't given.
        if typeof(HeadCFrame) ~= "CFrame" then return end
        if typeof(LeftHandCFrame) ~= "CFrame" then return end
        if typeof(RightHandCFrame) ~= "CFrame" then return end

        --Ignore if the rate limit was reached.
        if UpdateRateLimiter:RateLimitReached(Player) then return end

        --Replicate the CFrames to the other players.
        for _,OtherPlayer in pairs(Players:GetPlayers()) do
            if Player ~= OtherPlayer then
                UpdateInputsEvent:FireClient(OtherPlayer,Player,HeadCFrame,LeftHandCFrame,RightHandCFrame)
            end
        end
    end)
end

--[[
Returns a static instance of a class.
Intended for objects that can only have
1 instance.
--]]
function NexusVRCharacterModel:GetInstance(Path)
    --Create the singleton instance if non exists.
    if not NexusVRCharacterModel.SingletonInstances[Path] then
        NexusVRCharacterModel.SingletonInstances[Path] = NexusVRCharacterModel:GetResource(Path).new()
    end

    --Return the singleton instance.
    return NexusVRCharacterModel.SingletonInstances[Path]
end

--[[
Clears the static instances. Only
intended for use at the end of tests.
--]]
function NexusVRCharacterModel:ClearInstances()
    for _,Ins in pairs(NexusVRCharacterModel.SingletonInstances) do
        if Ins.Destroy then
            Ins:Destroy()
        end
    end
    NexusVRCharacterModel.SingletonInstances = {}
end



return NexusVRCharacterModel