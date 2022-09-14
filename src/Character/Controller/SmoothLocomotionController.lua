 --[[
TheNexusAvenger

Local character controller using teleporting.
--]]

local THUMBSTICK_MANUAL_ROTATION_ANGLE = math.rad(45)
local THUMBSTICK_DEADZONE_RADIUS = 0.2



local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local NexusVRCharacterModel = require(script.Parent.Parent.Parent)
local BaseController = NexusVRCharacterModel:GetResource("Character.Controller.BaseController")
local VRInputService = NexusVRCharacterModel:GetInstance("State.VRInputService")

local SmoothLocomotionController = BaseController:Extend()
SmoothLocomotionController:SetClassName("SmoothLocomotionController")



--[[
Enables the controller.
--]]
function SmoothLocomotionController:Enable(): nil
    self.super:Enable()
    self.JoystickState = { Thumbstick = Enum.KeyCode.Thumbstick2 }

    --Connect requesting jumping.
    --ButtonA does not work with IsButtonDown.
    self.ButtonADown = false
    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(Input, Processsed)
        if Processsed then return end
        if Input.KeyCode == Enum.KeyCode.ButtonA then
            self.ButtonADown = true
        end
    end))
    table.insert(self.Connections, UserInputService.InputEnded:Connect(function(Input)
        if Input.KeyCode == Enum.KeyCode.ButtonA then
            self.ButtonADown = false
        end
    end))
end

--[[
Disables the controller.
--]]
function SmoothLocomotionController:Disable(): nil
    self.super:Disable()
    self.JoystickState = nil
end

--[[
Updates the local character. Must also update the camara.
--]]
function SmoothLocomotionController:UpdateCharacter(): nil
    --Update the base character.
    self.super:UpdateCharacter()
    if not self.Character then
        return
    end

    --Determine the direction to move the player.
    local ThumbstickPosition = VRInputService:GetThumbstickPosition(Enum.KeyCode.Thumbstick1)
    local LeftHandInputActive = (not NexusVRCharacterModel.Api.Controller or NexusVRCharacterModel.Api.Controller:IsControllerInputEnabled(Enum.UserCFrame.LeftHand))
    local RightHandInputActive = (not NexusVRCharacterModel.Api.Controller or NexusVRCharacterModel.Api.Controller:IsControllerInputEnabled(Enum.UserCFrame.RightHand))
    if ThumbstickPosition.Magnitude < THUMBSTICK_DEADZONE_RADIUS or not LeftHandInputActive then
        ThumbstickPosition = Vector3.new(0, 0, 0)
    end
    local WDown, SDown = not UserInputService:GetFocusedTextBox() and UserInputService:IsKeyDown(Enum.KeyCode.W), not UserInputService:GetFocusedTextBox() and UserInputService:IsKeyDown(Enum.KeyCode.S)
    local DDown, ADown = not UserInputService:GetFocusedTextBox() and UserInputService:IsKeyDown(Enum.KeyCode.D), not UserInputService:GetFocusedTextBox() and UserInputService:IsKeyDown(Enum.KeyCode.A)
    local ForwardDirection = (WDown and 1 or 0) + (SDown and -1 or 0) + ThumbstickPosition.Y
    local SideDirection = (DDown and 1 or 0) + (ADown and -1 or 0) + ThumbstickPosition.X

    --Move the player in that direction.
    Players.LocalPlayer:Move(Vector3.new(SideDirection, 0, -ForwardDirection), true)

    --Snap rotate the character.
    if not self.Character.Humanoid.Sit then
        --Update and fetch the right joystick's state.
        local DirectionState, _, StateChange = self:GetJoystickState(self.JoystickState)

        --Snap rotate the character.
        local HumanoidRootPart = self.Character.Parts.HumanoidRootPart
        if StateChange == "Extended" and RightHandInputActive then
            if DirectionState == "Left" then
                --Turn the player to the left.
                self:PlayBlur()
                HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position) * CFrame.Angles(0, THUMBSTICK_MANUAL_ROTATION_ANGLE, 0) * (CFrame.new(-HumanoidRootPart.Position) * HumanoidRootPart.CFrame)
            elseif DirectionState == "Right" then
                --Turn the player to the right.
                self:PlayBlur()
                HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position) * CFrame.Angles(0, -THUMBSTICK_MANUAL_ROTATION_ANGLE, 0) * (CFrame.new(-HumanoidRootPart.Position) * HumanoidRootPart.CFrame)
            end
        end
    end

    --Update the vehicle seat.
    self:UpdateVehicleSeat()

    --Jump the player.
    if (not UserInputService:GetFocusedTextBox() and UserInputService:IsKeyDown(Enum.KeyCode.Space)) or self.ButtonADown then
        self.Character.Humanoid.Jump = true
    end
end



return SmoothLocomotionController