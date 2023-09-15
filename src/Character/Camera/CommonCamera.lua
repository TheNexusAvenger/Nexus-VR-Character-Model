--[[
TheNexusAvenger

Common camera functionality.
--]]
--!strict

local Workspace = game:GetService("Workspace")
local VRService = game:GetService("VRService")

local NexusVRCharacterModel = script.Parent.Parent.Parent
local Settings = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("Settings")).GetInstance()

local CommonCamera = {}
CommonCamera.__index = CommonCamera



--[[
Creates the common camera.
--]]
function CommonCamera.new(): any
    return setmetatable({}, CommonCamera)
end

--[[
Enables the camera.
--]]
function CommonCamera:Enable(): ()

end

--[[
Disables the camera.
--]]
function CommonCamera:Disable(): ()

end

--[[
Updates the camera.
--]]
function CommonCamera:UpdateCamera(HeadsetCFrameWorld: CFrame): ()

end

--[[
Sets the camera CFrame.
--]]
function CommonCamera:SetCFrame(HeadsetCFrameWorld: CFrame): ()
    --Lock HeadLocked to false.
    --The default behavior is to do it for backwards compatibility with 2.6.0 and earlier.
    local Camera = Workspace.CurrentCamera
    if Settings:GetSetting("Camera.DisableHeadLocked") ~= false then
        Camera.HeadLocked = false
    end

    --Set the camera CFrame.
    local TargetCFrame = HeadsetCFrameWorld
    if Camera.HeadLocked then
        local HeadCFrame = VRService:GetUserCFrame(Enum.UserCFrame.Head)
        TargetCFrame = HeadsetCFrameWorld * (CFrame.new(HeadCFrame.Position * (Workspace.CurrentCamera.HeadScale - 1)) * HeadCFrame):Inverse()
        Camera.VRTiltAndRollEnabled = true
    end
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = TargetCFrame
    Camera.Focus = TargetCFrame
end



return CommonCamera