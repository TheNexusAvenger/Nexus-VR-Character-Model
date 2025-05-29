--Loads Nexus VR Character Model.
--!strict

--Version information should be set right before distribution (not committed).
local VERSION_TAG = "dev"
local VERSION_COMMIT = "00000000"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local NexusBufferedReplication = require(script:WaitForChild("Packages"):WaitForChild("NexusBufferedReplication"))
local Settings = require(script:WaitForChild("State"):WaitForChild("Settings")).GetInstance()
local BufferProtocol = require(script:WaitForChild("Util"):WaitForChild("BufferProtocol"))

local BufferedRemoteEventSender = NexusBufferedReplication.Sender.BufferedRemoteEventSender
local EnrollableRemoteEvent = NexusBufferedReplication.Sender.EnrollableRemoteEvent

local NexusVRCharacterModel = {}

export type NexusVRCharacterModel = typeof(NexusVRCharacterModel)



--[[
Sets the configuration to use. Intended to be
run once by the server.
--]]
function NexusVRCharacterModel.SetConfiguration(self: NexusVRCharacterModel, Configuration: any): ()
    --Create the value.
    local ConfigurationValue = script:FindFirstChild("Configuration") :: StringValue
    if not ConfigurationValue then
        local NewConfigurationValue = Instance.new("StringValue")
        NewConfigurationValue.Name = "Configuration"
        NewConfigurationValue.Parent = script
        ConfigurationValue = NewConfigurationValue
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
    --This is a bit hacky, but the only good option in Wally.
    if not ReplicatedStorage:FindFirstChild("NexusVRCore") then
        local Packages = script:FindFirstChild("Packages")
        if Packages then
            local NexusVRCore = Packages:FindFirstChild("nexus-vr-core", true)
            local NexusInstance = Packages:FindFirstChild("nexus-instance", true)
            if NexusVRCore and NexusInstance then
                local NewNexusVRCore = NexusVRCore:Clone()
                NewNexusVRCore.Name = "NexusVRCore"
                NewNexusVRCore:WaitForChild("Packages"):WaitForChild("NexusInstance"):Destroy()

                local NewNexusInstance = NexusInstance:Clone()
                NewNexusInstance.Name = "NexusInstance"
                NewNexusInstance.Parent = NewNexusVRCore:WaitForChild("Packages")
                NewNexusVRCore.Parent = ReplicatedStorage
            end
        end
    end

    --Output any warnings.
    (require(ReplicatedStorage:WaitForChild("NexusVRCharacterModel"):WaitForChild("Util"):WaitForChild("Warnings")) :: any)()

    --Set up the client scripts.
    script:WaitForChild("NexusVRCharacterModelClientLoader").Parent = ReplicatedStorage

    --Set up replication.
    local UpdateInputsEvent = Instance.new("UnreliableRemoteEvent")
    UpdateInputsEvent.Name = "UpdateInputs"
    UpdateInputsEvent.Parent = script

    local ReplicationReadyEvent = Instance.new("RemoteEvent")
    ReplicationReadyEvent.Name = "ReplicationReady"
    ReplicationReadyEvent.Parent = script

    local EnrollableUpdateInputsEvent = EnrollableRemoteEvent.new(UpdateInputsEvent)
    local UpdateInputsBufferedRemoteEventSender = BufferedRemoteEventSender.WithPlayerKeys(EnrollableUpdateInputsEvent :: any, function(Data: BufferProtocol.BufferProtocolData)
        return BufferProtocol.Serialize(Data)
    end)
    UpdateInputsBufferedRemoteEventSender:StartDataSendingWithDelay(1 / 30)

    UpdateInputsEvent.OnServerEvent:Connect(function(Player, Data: BufferProtocol.BufferProtocolData)
        if typeof(Data) ~= "table" then return end
        UpdateInputsBufferedRemoteEventSender:QueueData(Player, Data)
    end)

    ReplicationReadyEvent.OnServerEvent:Connect(function(Player)
        EnrollableUpdateInputsEvent:EnrollPlayer(Player)
    end)

    --Load Nexus VR Backpack.
    if Settings:GetSetting("Extra.NexusVRBackpackEnabled") ~= false then
        (require(10728805649) :: any)()
    end
end




NexusVRCharacterModel.Api = (require(script:WaitForChild("Api")) :: any)()
return NexusVRCharacterModel