 --[[
TheNexusAvenger

Local character controller using teleporting.
--]]
--!strict

local THUMBSTICK_DEADZONE_RADIUS = 0.2



local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local NexusVRCharacterModel = script.Parent.Parent.Parent
local NexusVRCharacterModelApi = require(NexusVRCharacterModel).Api
local BaseController = require(script.Parent:WaitForChild("BaseController"))
local VRInputService = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("VRInputService")).GetInstance()

local SmoothLocomotionController = {}
SmoothLocomotionController.__index = SmoothLocomotionController
setmetatable(SmoothLocomotionController, BaseController)



--[[
Creates a smooth locomotion controller object.
--]]
function SmoothLocomotionController.new(): any
    return setmetatable(BaseController.new(), SmoothLocomotionController)
end

--[[
Enables the controller.
--]]
function SmoothLocomotionController:Enable(): ()
    BaseController.Enable(self)

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
function SmoothLocomotionController:Disable(): ()
    BaseController.Disable(self)
    self.JoystickState = nil
end

--[[
Updates the local character. Must also update the camara.
--]]
function SmoothLocomotionController:UpdateCharacter(): ()
    --Update the base character.
    BaseController.UpdateCharacter(self)
    if not self.Character then
        return
    end

    --Determine the direction to move the player.
    local ThumbstickPosition = VRInputService:GetThumbstickPosition(Enum.KeyCode.Thumbstick1)
    local LeftHandInputActive = (not NexusVRCharacterModelApi.Controller or NexusVRCharacterModelApi.Controller:IsControllerInputEnabled(Enum.UserCFrame.LeftHand))
    local RightHandInputActive = (not NexusVRCharacterModelApi.Controller or NexusVRCharacterModelApi.Controller:IsControllerInputEnabled(Enum.UserCFrame.RightHand))
    if ThumbstickPosition.Magnitude < THUMBSTICK_DEADZONE_RADIUS or not LeftHandInputActive then
        ThumbstickPosition = Vector3.zero
    end
    local WDown, SDown = not UserInputService:GetFocusedTextBox() and UserInputService:IsKeyDown(Enum.KeyCode.W), not UserInputService:GetFocusedTextBox() and UserInputService:IsKeyDown(Enum.KeyCode.S)
    local DDown, ADown = not UserInputService:GetFocusedTextBox() and UserInputService:IsKeyDown(Enum.KeyCode.D), not UserInputService:GetFocusedTextBox() and UserInputService:IsKeyDown(Enum.KeyCode.A)
    local ForwardDirection = (WDown and 1 or 0) + (SDown and -1 or 0) + ThumbstickPosition.Y
    local SideDirection = (DDown and 1 or 0) + (ADown and -1 or 0) + ThumbstickPosition.X

    --Move the player in that direction.
    Players.LocalPlayer:Move(Vector3.new(SideDirection, 0, -ForwardDirection), true)

    --Update the vehicle seat.
    self:UpdateVehicleSeat()

    --Jump the player.
    if (not UserInputService:GetFocusedTextBox() and UserInputService:IsKeyDown(Enum.KeyCode.Space)) or self.ButtonADown then
        self.Character.Humanoid.Jump = true
    end
end



return SmoothLocomotionController