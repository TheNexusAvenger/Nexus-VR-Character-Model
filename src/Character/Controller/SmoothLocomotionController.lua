 --[[
TheNexusAvenger

Local character controller using teleporting.
--]]

local THUMBSTICK_DEADZONE_RADIUS = 0.2



local VRService = game:GetService("VRService")
local UserInputService = game:GetService("UserInputService")

local NexusVRCharacterModel = require(script.Parent.Parent.Parent)
local BaseController = NexusVRCharacterModel:GetInstance("Character.Controller.BaseController")
local ArcWithBeacon = NexusVRCharacterModel:GetInstance("Character.Controller.Visual.ArcWithBeacon")
local CameraService = NexusVRCharacterModel:GetInstance("State.CameraService")
local VRInputService = NexusVRCharacterModel:GetInstance("State.VRInputService")

local SmoothLocomotionController = BaseController:Extend()
SmoothLocomotionController:SetClassName("SmoothLocomotionController")



--[[
Enables the controller.
--]]
function SmoothLocomotionController:Enable()
    self.super:Enable()
    self.LastUpdateTime = tick()
    VRService:SetTouchpadMode(Enum.VRTouchpad.Right,Enum.VRTouchpadMode.ABXY)
end

--[[
Disables the controller.
--]]
function SmoothLocomotionController:Disable()
    self.super:Disable()
    self.LastUpdateTime = nil
    VRService:SetTouchpadMode(Enum.VRTouchpad.Right,Enum.VRTouchpadMode.VirtualThumbstick)
end

--[[
Updates the local character. Must also update the camara.
--]]
function SmoothLocomotionController:UpdateCharacter()
    --Update the world CFrame reference.
    self:UpdateReferenceWorldCFrame()
    if not self.Character then
        return
    end
    self.Character.TweenComponents = false

    --Get the VR inputs and convert them to world space.
    local VRInputs = VRInputService:GetVRInputs()

    --Unsit the player if A is pressed.
    if UserInputService:IsKeyDown(Enum.KeyCode.ButtonA) and self.Character.Humanoid.Sit then
        self.Character.Humanoid.Sit = false
    end

    --Move the character if the threshold is met and the player can move.
    if not self.Character.Humanoid.Sit and self.Character.Humanoid.WalkSpeed > 0 then
        local InputPosition = VRInputService:GetThumbstickPosition(Enum.KeyCode.Thumbstick1)
        local InputRadius = ((InputPosition.X ^ 2) + (InputPosition.Y ^ 2)) ^ 0.5
        if InputRadius >= THUMBSTICK_DEADZONE_RADIUS then
            --Calculate the CFrame rotation of the controller.
            local ControllerRotation = CFrame.new(-VRInputs[Enum.UserCFrame.LeftHand].Position) * VRInputs[Enum.UserCFrame.LeftHand]

            --Apply the position offset.
            local DeltaTime = tick() - self.LastUpdateTime
            local Speed = self.Character.Humanoid.WalkSpeed * InputRadius * DeltaTime
            local MoveOffsetCFrame = ControllerRotation * CFrame.new(InputPosition.X * Speed,0,-InputPosition.Y * Speed)
            self.ReferenceWorldCFrame = self.ReferenceWorldCFrame * CFrame.new(MoveOffsetCFrame.X,0,MoveOffsetCFrame.Z)
            self:UpdateReferenceWorldCFrame()
        end
    end
    self.LastUpdateTime = tick()

    --Convert the VR inputs from local to world space.
    for _,InputEnum in pairs({Enum.UserCFrame.Head,Enum.UserCFrame.LeftHand,Enum.UserCFrame.RightHand}) do
        VRInputs[InputEnum] = self.ReferenceWorldCFrame * self:ScaleInput(VRInputs[InputEnum])
    end

    --Update the character.
    self.Character:UpdateFromInputs(VRInputs[Enum.UserCFrame.Head],VRInputs[Enum.UserCFrame.LeftHand],VRInputs[Enum.UserCFrame.RightHand])

    --Update the camera.
    CameraService:UpdateCamera(VRInputs[Enum.UserCFrame.Head])
end



return SmoothLocomotionController