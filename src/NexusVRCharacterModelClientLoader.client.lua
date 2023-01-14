--[[
TheNexusAvenger

Loads Nexus VR Character Model on the client.
--]]
--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local NexusVRCharacterModel = ReplicatedStorage:WaitForChild("NexusVRCharacterModel") :: ModuleScript
local CameraService = (require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("CameraService")) :: any).GetInstance()
local CharacterService = (require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("CharacterService")) :: any).GetInstance()
local ControlService = (require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("ControlService")) :: any).GetInstance()
local DefaultCursorService = (require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("DefaultCursorService")) :: any).GetInstance()
local Settings = (require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("Settings")) :: any).GetInstance()
local UpdateInputs = NexusVRCharacterModel:WaitForChild("UpdateInputs") :: RemoteEvent
local ReplicationReady = NexusVRCharacterModel:WaitForChild("ReplicationReady") :: RemoteEvent



--Load the settings.
Settings:SetDefaults(HttpService:JSONDecode((NexusVRCharacterModel:WaitForChild("Configuration") :: StringValue).Value))

--Connect replication for other players.
UpdateInputs.OnClientEvent:Connect(function(Player, HeadCFrame, LeftHandCFrame, RightHandCFrame)
    local Character = CharacterService:GetCharacter(Player)
    if Character then
        Character:UpdateFromInputs(HeadCFrame, LeftHandCFrame, RightHandCFrame)
    end
end)
ReplicationReady:FireServer()

--Allow checking if Nexus VR Character Model is loaded without being in VR.
local LoadedPrintStatementPrinted = false
UserInputService.InputBegan:Connect(function(Input)
    if not LoadedPrintStatementPrinted and Input.KeyCode == Enum.KeyCode.F9 and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) and Settings:GetSetting("Output.AllowClientToOutputLoadedMessage") ~= false then
        LoadedPrintStatementPrinted = true
        print("Nexus VR Character Model is loaded.")
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

--Start updating the VR character.
RunService:BindToRenderStep("NexusVRCharacterModelUpdate", Enum.RenderPriority.Camera.Value - 1, function()
    ControlService:UpdateCharacter()
end)