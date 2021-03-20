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
    --Update the base character.
    self.super:UpdateCharacter()
    if not self.Character then
        return
    end

    --TODO: Implement jumping and moving
end



return SmoothLocomotionController