--Loads Nexus VR Character Model on the client.
--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VRService = game:GetService("VRService")

local NexusVRCharacterModel = ReplicatedStorage:WaitForChild("NexusVRCharacterModel") :: ModuleScript
local NexusBufferedReplication = require(NexusVRCharacterModel:WaitForChild("Packages"):WaitForChild("NexusBufferedReplication")) :: any
local CameraService = (require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("CameraService")) :: any).GetInstance()
local CharacterService = (require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("CharacterService")) :: any).GetInstance()
local ControlService = (require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("ControlService")) :: any).GetInstance()
local DefaultCursorService = (require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("DefaultCursorService")) :: any).GetInstance()
local EnigmaService = (require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("EnigmaService")) :: any).GetInstance()
local Settings = (require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("Settings")) :: any).GetInstance()
local BufferProtocol = require(NexusVRCharacterModel:WaitForChild("Util"):WaitForChild("BufferProtocol")) :: any
local UpdateInputs = NexusVRCharacterModel:WaitForChild("UpdateInputs") :: UnreliableRemoteEvent
local ReplicationReady = NexusVRCharacterModel:WaitForChild("ReplicationReady") :: RemoteEvent

local PlayerBufferedRemoteEventReceiver = NexusBufferedReplication.Receiver.PlayerBufferedRemoteEventReceiver



--Add the deprecation warning to the bundled Nexus VR Core.
local NexusVRCore = require(ReplicatedStorage:WaitForChild("NexusVRCore")) :: any
local BaseScreenGui = NexusVRCore.BaseScreenGui
if BaseScreenGui then --Older versions (non-bundled versions) do not have this in the main module.
    local OriginalBaseScreenGuiConstructor = BaseScreenGui.__new
    BaseScreenGui.__new = function(...)
        warn("Using the bundled (automically loaded) Nexus VR Core with Nexus VR Character Model is deprecated.\nIt is recommended to move to a fixed version, which can be downloaded from GitHub.")
        return OriginalBaseScreenGuiConstructor(...)
    end
end

--Load the settings.
Settings:SetDefaults(HttpService:JSONDecode((NexusVRCharacterModel:WaitForChild("Configuration") :: StringValue).Value))

--Connect replication for other players.
local LastPlayerUpdates = {} :: {[Player]: number}
local UpdateInputsPlayerBufferedRemoteEventReceiver = PlayerBufferedRemoteEventReceiver.new(UpdateInputs, function(Buffer)
    return BufferProtocol.Deserialize(Buffer)
end)
UpdateInputsPlayerBufferedRemoteEventReceiver:OnDataReceived(function(Player: Player, Data)
    if Player == Players.LocalPlayer then return end

    --Return if the update is after the latest update.
    --Unreliable events do not guarentee order.
    local UpdateTime = Data.UpdateTime
    if UpdateTime then
        if LastPlayerUpdates[Player] and UpdateTime < LastPlayerUpdates[Player] then return end
        LastPlayerUpdates[Player] = UpdateTime
    end

    --Update the character.
    local Character = CharacterService:GetCharacter(Player)
    if Character then
        Character:UpdateFromInputs(Data.HeadCFrame, Data.LeftHandCFrame, Data.RightHandCFrame, Data.CurrentWalkspeed, {
            LeftFoot = Data.LeftFootCFrame,
            RightFoot = Data.RightFootCFrame,
        })
    end
end)
Players.PlayerRemoving:Connect(function(Player)
    LastPlayerUpdates[Player] = nil
end)
ReplicationReady:FireServer()

--Connect updating all the character Motor6Ds.
--Must be done after Stepped to override Animators.
RunService.Stepped:Connect(function()
    CharacterService:RefreshAllCharacters()
end)

--Allow checking if Nexus VR Character Model is loaded without being in VR.
local LoadedPrintStatementPrinted = false
UserInputService.InputBegan:Connect(function(Input)
    if not LoadedPrintStatementPrinted and Input.KeyCode == Enum.KeyCode.F9 and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) and Settings:GetSetting("Output.AllowClientToOutputLoadedMessage") ~= false then
        LoadedPrintStatementPrinted = true
        print(`Nexus VR Character Model version {Settings:GetSetting("Version.Tag")} ({Settings:GetSetting("Version.Commit")}) is loaded.`)
    end
end)

--Wait for VR to be enabled.
while not UserInputService.VREnabled do
    UserInputService:GetPropertyChangedSignal("VREnabled"):Wait()
    warn("VR was detected later than when Nexus VR Character Model loaded. This may be a Roblox bug.")
end

--Disable the native VR controller models.
--Done in a pcall in case the SetCore is not registered or is removed.
task.spawn(function()
    for i = 1, 600 do
        local Worked = pcall(function()
            StarterGui:SetCore("VREnableControllerModels", false)
            DefaultCursorService:SetCursorState("Detect")
        end)
        if Worked then break end
        task.wait(0.1)
    end
end)

--Display a message if R6 is used.
local Character = Players.LocalPlayer.Character
while not Character do
    Character = Players.LocalPlayer.CharacterAdded:Wait()
end
if Character:WaitForChild("Humanoid").RigType == Enum.HumanoidRigType.R6 then
    local R6Message = (require(NexusVRCharacterModel:WaitForChild("UI"):WaitForChild("R6Message")) :: any).new()
    R6Message:Open()
    return
end

--Set the initial controller and camera.
--Must happen before loading the settings in the main menu.
ControlService:SetActiveController(Settings:GetSetting("Movement.DefaultMovementMethod"))
CameraService:SetActiveCamera(Settings:GetSetting("Camera.DefaultCameraOption"))

--Load the menu.
local MainMenu = (require(NexusVRCharacterModel:WaitForChild("UI"):WaitForChild("MainMenu")) :: any).GetInstance()
MainMenu:SetUpOpening()

--Load the backpack.
if Settings:GetSetting("Extra.NexusVRBackpackEnabled") ~= false then
    task.defer(function()
        local NexusVRBackpack = require(ReplicatedStorage:WaitForChild("NexusVRBackpack")) :: {Load: (any) -> ()}
        NexusVRBackpack:Load()
    end)
end

--Load Enigma.
if Settings:GetSetting("Extra.EnigmaEnabled") ~= false then
    EnigmaService:Enable()
end

--Start updating the VR character.
RunService:BindToRenderStep("NexusVRCharacterModelUpdate", Enum.RenderPriority.Camera.Value - 1, function()
    ControlService:UpdateCharacter()
end)

--Disable FadeOutViewOnCollision.
if Settings:GetSetting("DisableFadeOutViewOnCollision") == true then
    VRService.FadeOutViewOnCollision = false
end