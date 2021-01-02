 --[[
TheNexusAvenger

Local character controller using teleporting.
--]]

local NexusVRCharacterModel = require(script.Parent.Parent.Parent)
local BaseController = NexusVRCharacterModel:GetInstance("Character.Controller.BaseController")
local CameraService = NexusVRCharacterModel:GetInstance("State.CameraService")
local VRInputService = NexusVRCharacterModel:GetInstance("State.VRInputService")

local TeleportController = BaseController:Extend()
TeleportController:SetClassName("TeleportController")



--[[
Updates the local character. Must also update the camara.
--]]
function TeleportController:UpdateCharacter()
    --Update the world CFrame reference.
    self:UpdateReferenceWorldCFrame()
    if not self.Character then
        return
    end
    self.Character.TweenComponents = false

    --Get the VR inputs and convert them to world space.
    local VRInputs = VRInputService:GetVRInputs()
    for _,InputEnum in pairs({Enum.UserCFrame.Head,Enum.UserCFrame.LeftHand,Enum.UserCFrame.RightHand}) do
        VRInputs[InputEnum] = self.ReferenceWorldCFrame * self:ScaleInput(VRInputs[InputEnum])
    end

    --Update the character.
    self.Character:UpdateFromInputs(VRInputs[Enum.UserCFrame.Head],VRInputs[Enum.UserCFrame.LeftHand],VRInputs[Enum.UserCFrame.RightHand])

    --Update the camera.
    CameraService:UpdateCamera(VRInputs[Enum.UserCFrame.Head])
end



return TeleportController