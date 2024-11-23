--Loads Nexus VR Character Model.
--!strict

--Version information should be set right before distribution (not committed).
local VERSION_TAG = "dev"
local VERSION_COMMIT = "00000000"

--Client should send replication at 30hz.
--A buffer is added in case this rate is exceeded
--briefly, such as an unstable connection.
local REPLICATION_RATE_LIMIT = 35

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Settings = require(script:WaitForChild("State"):WaitForChild("Settings")).GetInstance()
local RateLimiter = require(script:WaitForChild("State"):WaitForChild("RateLimiter"))

local NexusVRCharacterModel = {}

export type NexusVRCharacterModel = typeof(NexusVRCharacterModel)



--[[
Sets the configuration to use. Intended to be
run once by the server.
--]]
function NexusVRCharacterModel.SetConfiguration(self: NexusVRCharacterModel, Configuration: any): ()
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
function NexusVRCharacterModel.Load(self: NexusVRCharacterModel): ()
    --Return if a version is already loaded.
    if ReplicatedStorage:FindFirstChild("NexusVRCharacterModel") then
        return
    end

    --Rename and move the script to ReplicatedStorage.
    script.Name = "NexusVRCharacterModel"
    script.Parent = ReplicatedStorage

    --Copy Nexus VR Core.
    if not ReplicatedStorage:FindFirstChild("NexusVRCore") then
        script:WaitForChild("NexusVRCore"):Clone().Parent = ReplicatedStorage
    end

    --Output any warnings.
    (require(ReplicatedStorage:WaitForChild("NexusVRCharacterModel"):WaitForChild("Util"):WaitForChild("Warnings")) :: any)()

    --Set up the client scripts.
    script:WaitForChild("NexusVRCharacterModelClientLoader").Parent = ReplicatedStorage

    --Set up replication.
    local ReadyPlayers = {}
    local UpdateRateLimiter = RateLimiter.new(REPLICATION_RATE_LIMIT)

    local UpdateInputsEvent = Instance.new("UnreliableRemoteEvent")
    UpdateInputsEvent.Name = "UpdateInputs"
    UpdateInputsEvent.Parent = script

    local ReplicationReadyEvent = Instance.new("RemoteEvent")
    ReplicationReadyEvent.Name = "ReplicationReady"
    ReplicationReadyEvent.Parent = script

    UpdateInputsEvent.OnServerEvent:Connect(function(Player, HeadCFrame: CFrame, LeftHandCFrame: CFrame, RightHandCFrame: CFrame, UpdateTime: number?, CurrentWalkspeed: number?, TrackerData: {[string]: CFrame}?)
        --Ignore the input if 3 CFrames aren't given.
        if typeof(HeadCFrame) ~= "CFrame" then return end
        if typeof(LeftHandCFrame) ~= "CFrame" then return end
        if typeof(RightHandCFrame) ~= "CFrame" then return end
        if UpdateTime and typeof(UpdateTime) ~= "number" then return end
        if UpdateTime and typeof(CurrentWalkspeed) ~= "number" then return end
        if TrackerData then
            if typeof(TrackerData) ~= "table" then return end
            for Key, Value in TrackerData do
                if Key ~= "LeftFoot" and Key ~= "RightFoot" then return end
                if typeof(Value) ~= "CFrame" then return end
            end
        end

        --Ignore if the rate limit was reached.
        if UpdateRateLimiter:RateLimitReached(Player) then return end

        --Replicate the CFrames to the other players.
        for _,OtherPlayer in Players:GetPlayers() do
            if Player ~= OtherPlayer and ReadyPlayers[OtherPlayer] then
                UpdateInputsEvent:FireClient(OtherPlayer, Player, HeadCFrame, LeftHandCFrame, RightHandCFrame, UpdateTime, CurrentWalkspeed, TrackerData)
            end
        end
    end)

    ReplicationReadyEvent.OnServerEvent:Connect(function(Player)
        ReadyPlayers[Player] = true
    end)

    Players.PlayerRemoving:Connect(function(Player)
        ReadyPlayers[Player] = nil
    end)

    --Load Nexus VR Backpack.
    if Settings:GetSetting("Extra.NexusVRBackpackEnabled") ~= false then
        (require(10728805649) :: any)()
    end
end




NexusVRCharacterModel.Api = (require(script:WaitForChild("Api")) :: any)()
return NexusVRCharacterModel