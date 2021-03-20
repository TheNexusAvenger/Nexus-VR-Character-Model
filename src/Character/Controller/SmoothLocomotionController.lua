 --[[
TheNexusAvenger

Local character controller using teleporting.
--]]

local THUMBSTICK_DEADZONE_RADIUS = 0.2



local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local VRService = game:GetService("VRService")
local UserInputService = game:GetService("UserInputService")

local NexusVRCharacterModel = require(script.Parent.Parent.Parent)
local BaseController = NexusVRCharacterModel:GetInstance("Character.Controller.BaseController")

local SmoothLocomotionController = BaseController:Extend()
SmoothLocomotionController:SetClassName("SmoothLocomotionController")



--[[
Enables the controller.
--]]
function SmoothLocomotionController:Enable()
    self.super:Enable()
    VRService:SetTouchpadMode(Enum.VRTouchpad.Right,Enum.VRTouchpadMode.ABXY)

    --Connect requesting movement.
    self.WDown,self.SDown,self.ADown,self.DDown = false,false,false,false
    self.ThumbstickPosition = Vector3.new(0,0,0)
    table.insert(self.Connections,UserInputService.InputBegan:Connect(function(Input,Processsed)
        if Processsed then return end
        if Input.KeyCode == Enum.KeyCode.W then
            self.WDown = true
        elseif Input.KeyCode == Enum.KeyCode.S then
            self.SDown = true
        elseif Input.KeyCode == Enum.KeyCode.A then
            self.ADown = true
        elseif Input.KeyCode == Enum.KeyCode.D then
            self.DDown = true
        end
    end))
    table.insert(self.Connections,UserInputService.InputEnded:Connect(function(Input)
        if Input.KeyCode == Enum.KeyCode.W then
            self.WDown = false
        elseif Input.KeyCode == Enum.KeyCode.S then
            self.SDown = false
        elseif Input.KeyCode == Enum.KeyCode.A then
            self.ADown = false
        elseif Input.KeyCode == Enum.KeyCode.D then
            self.DDown = false
        end
    end))
    table.insert(self.Connections,UserInputService.InputChanged:Connect(function(Input,Processsed)
        if Processsed then return end
        if Input.KeyCode == Enum.KeyCode.Thumbstick1 then
            self.ThumbstickPosition = Input.Position
        end
    end))

    --Connect requesting jumping.
    self.ButtonADown,self.SpaceDown = false,false
    table.insert(self.Connections,UserInputService.InputBegan:Connect(function(Input,Processsed)
        if Processsed then return end
        if Input.KeyCode == Enum.KeyCode.ButtonA then
            self.ButtonADown = true
        elseif Input.KeyCode == Enum.KeyCode.Space then
            self.SpaceDown = true
        end
    end))
    table.insert(self.Connections,UserInputService.InputEnded:Connect(function(Input)
        if Input.KeyCode == Enum.KeyCode.ButtonA then
            self.ButtonADown = false
        elseif Input.KeyCode == Enum.KeyCode.Space then
            self.SpaceDown = false
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
    local ForwardDirection = (self.WDown and 1 or 0) + (self.SDown and -1 or 0) + self.ThumbstickPosition.Y
    local SideDirection = (self.DDown and 1 or 0) + (self.ADown and -1 or 0) + self.ThumbstickPosition.X
    if math.sqrt((ForwardDirection ^ 2) + (SideDirection ^ 2)) < THUMBSTICK_DEADZONE_RADIUS then
        ForwardDirection = 0
        SideDirection = 0
    end

    --Move the player in that direction.
    Players.LocalPlayer:Move(Vector3.new(SideDirection,0,-ForwardDirection),true)

    --Jump the player.
    if self.SpaceDown or self.ButtonADown then
        self.Character.Humanoid.Jump = true
    end
end



return SmoothLocomotionController