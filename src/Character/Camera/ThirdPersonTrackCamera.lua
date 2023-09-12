--[[
TheNexusAvenger

Third person camera that moves with the player.
--]]
--!strict

local THIRD_PERSON_ZOOM = 10



local Players = game:GetService("Players")

local NexusVRCharacterModel = script.Parent.Parent.Parent
local CommonCamera = require(NexusVRCharacterModel:WaitForChild("Character"):WaitForChild("Camera"):WaitForChild("CommonCamera"))

local ThirdPersonTrackCamera = {}
ThirdPersonTrackCamera.__index = ThirdPersonTrackCamera
setmetatable(ThirdPersonTrackCamera, CommonCamera)



--[[
Creates a third-person camera object.
--]]
function ThirdPersonTrackCamera.new(): any
    return setmetatable(CommonCamera.new(), ThirdPersonTrackCamera)
end

--[[
Enables the camera.
--]]
function ThirdPersonTrackCamera:Enable(): ()
    self.FetchInitialCFrame = true
end

--[[
Disables the camera.
--]]
function ThirdPersonTrackCamera:Disable(): ()
    self.FetchInitialCFrame = nil
end

--[[
Updates the camera.
--]]
function ThirdPersonTrackCamera:UpdateCamera(HeadsetCFrameWorld: CFrame): ()
    --Set the initial CFrame to use.
    if self.FetchInitialCFrame then
        self.BaseFaceAngleY = math.atan2(-HeadsetCFrameWorld.LookVector.X, -HeadsetCFrameWorld.LookVector.Z)
        self.BaseCFrame = CFrame.new(HeadsetCFrameWorld.Position) * CFrame.Angles(0, self.BaseFaceAngleY, 0)
        self.FetchInitialCFrame = nil
    end

    --Get the scale.
    local Scale = 1
    local Character = Players.LocalPlayer.Character
    if Character then
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then
            local BodyHeightScale = Humanoid:FindFirstChild("BodyHeightScale")
            if BodyHeightScale then
                Scale = BodyHeightScale.Value
            end
        end
    end

    --Calculate the third person CFrame.
    local HeadsetRelative = self.BaseCFrame:Inverse() * HeadsetCFrameWorld
    local TargetCFrame = self.BaseCFrame * CFrame.new(0, 0, -THIRD_PERSON_ZOOM * Scale) * CFrame.Angles(0, math.pi, 0) * HeadsetRelative

    --Update the camaera.
    CommonCamera.UpdateCamera(self, TargetCFrame)
end



return ThirdPersonTrackCamera