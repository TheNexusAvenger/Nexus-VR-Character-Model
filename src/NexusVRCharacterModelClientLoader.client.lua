--[[
TheNexusAvenger

Loads Nexus VR Character Model on the client.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local VRService = game:GetService("VRService")

local NexusVRCharacterModel = require(ReplicatedStorage:WaitForChild("NexusVRCharacterModel"))
local CameraService = NexusVRCharacterModel:GetInstance("State.CameraService")
local CharacterService = NexusVRCharacterModel:GetInstance("State.CharacterService")
local ControlService = NexusVRCharacterModel:GetInstance("State.ControlService")
local Settings = NexusVRCharacterModel:GetInstance("State.Settings")
local UpdateInputs = NexusVRCharacterModel:GetResource("UpdateInputs")



--Load the settings.
Settings:SetOverrides(HttpService:JSONDecode(NexusVRCharacterModel:GetResource("Configuration").Value))

--Connect replication for other players.
UpdateInputs.OnClientEvent:Connect(function(Player,HeadCFrame,LeftHandCFrame,RightHandCFrame)
    local Character = CharacterService:GetCharacter(Player)
    if Character then
        Character:UpdateFromInputs(HeadCFrame,LeftHandCFrame,RightHandCFrame)
    end
end)

--Connect the local player if VR is enabled.
if VRService.VREnabled then
    --Disable the native VR pointer.
    --Done in a pcall in case the SetCore is not registered or is removed.
    coroutine.wrap(function()
        for i = 1,600 do
            local Worked = pcall(function()
                StarterGui:SetCore("VRLaserPointerMode",0)
                StarterGui:SetCore("VREnableControllerModels",false)
            end)
            if Worked then break end
            wait(0.1)
        end
    end)()

    --Enable Nexus VR pointing.
    local NexusVRCore = require(ReplicatedStorage:WaitForChild("NexusVRCore"))
    local VRPointing = NexusVRCore:GetResource("Interaction.VRPointing")
    VRPointing:ConnectEvents()
    VRPointing:RunUpdating()

    --Display a message if R6 is used.
    local Character = Players.LocalPlayer.Character
    while not Character do
        Character = Players.LocalPlayer.Character
        wait()
    end
    if Character:WaitForChild("Humanoid").RigType == Enum.HumanoidRigType.R6 then
        local R6Message = NexusVRCharacterModel:GetInstance("UI.R6Message")
        R6Message:Open()
        return
    end

    --Set the initial controller and camera.
    --Must happen before loading the settings in the main menu.
    ControlService:SetActiveController(Settings:GetSetting("Movement.DefaultMovementMethod"))
    CameraService:SetActiveCamera(Settings:GetSetting("Camera.DefaultCameraOption"))

    --Load the menu.
    local MainMenu = NexusVRCharacterModel:GetInstance("UI.MainMenu")
    MainMenu:SetUpOpening()

    --Start updating the VR character.
    RunService:BindToRenderStep("NexusVRCharacterModelUpdate",Enum.RenderPriority.Camera.Value - 1,function()
        ControlService:UpdateCharacter()
    end)
end