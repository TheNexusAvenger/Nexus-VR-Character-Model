 --[[
TheNexusAvenger

Local character controller using teleporting.
--]]

local THUMBSTICK_DEADZONE_RADIUS = 0.2



local Players = game:GetService("Players")
local VRService = game:GetService("VRService")
local UserInputService = game:GetService("UserInputService")

local NexusVRCharacterModel = require(script.Parent.Parent.Parent)
local BaseController = NexusVRCharacterModel:GetInstance("Character.Controller.BaseController")
local VRInputService = NexusVRCharacterModel:GetInstance("State.VRInputService")

local SmoothLocomotionController = BaseController:Extend()
SmoothLocomotionController:SetClassName("SmoothLocomotionController")



--[[
Enables the controller.
--]]
function SmoothLocomotionController:Enable()
    self.super:Enable()
    VRService:SetTouchpadMode(Enum.VRTouchpad.Right,Enum.VRTouchpadMode.ABXY)

    --Connect requesting jumping.
    --ButtonA does not work with IsButtonDown.
    self.ButtonADown = false
    table.insert(self.Connections,UserInputService.InputBegan:Connect(function(Input,Processsed)
        if Processsed then return end
        if Input.KeyCode == Enum.KeyCode.ButtonA then
            self.ButtonADown = true
        end
    end))
    table.insert(self.Connections,UserInputService.InputEnded:Connect(function(Input)
        if Input.KeyCode == Enum.KeyCode.ButtonA then
            self.ButtonADown = false
        end
    end))
end

--[[
Disables the controller.
--]]
function SmoothLocomotionController:Disable()
    self.super:Disable()
    VRService:SetTouchpadMode(Enum.VRTouchpad.Right,Enum.VRTouchpadMode.VirtualThumbstick)
end

--[[
Updates the local character. Must also update the camara.
--]]
function SmoothLocomotionController:UpdateCharacter()
    --Update the base character.
    self.super:UpdateCharacter()
    if not self.Character then
        return
    end

    --Determine the direction to move the player.
    local ThumbstickPosition = VRInputService:GetThumbstickPosition(Enum.KeyCode.Thumbstick1)
    if ThumbstickPosition.Magnitude < THUMBSTICK_DEADZONE_RADIUS then
        ThumbstickPosition = Vector3.new(0,0,0)
    end
    local ForwardDirection = (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0) + (UserInputService:IsKeyDown(Enum.KeyCode.S) and -1 or 0) + ThumbstickPosition.Y
    local SideDirection = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) + (UserInputService:IsKeyDown(Enum.KeyCode.A) and -1 or 0) + ThumbstickPosition.X

    --Move the player in that direction.
    Players.LocalPlayer:Move(Vector3.new(SideDirection,0,-ForwardDirection),true)

    --Update the vehicle seat.
    self:UpdateVehicleSeat()

    --Jump the player.
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) or self.ButtonADown then
        self.Character.Humanoid.Jump = true
    end
end



return SmoothLocomotionController