--[[
TheNexusAvenger

Third person camera that moves with the player.
--]]

local THIRD_PERSON_ZOOM = 10



local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local NexusVRCharacterModel = require(script.Parent.Parent.Parent)
local NexusObject = NexusVRCharacterModel:GetResource("NexusInstance.NexusObject")

local ThirdPersonTrackCamera = NexusObject:Extend()
ThirdPersonTrackCamera:SetClassName("ThirdPersonTrackCamera")



--[[
Enables the camera.
--]]
function ThirdPersonTrackCamera:Enable()
    self.FetchInitialCFrame = true
end

--[[
Disables the camera.
--]]
function ThirdPersonTrackCamera:Disable()
    self.FetchInitialCFrame = nil
end

--[[
Updates the camera.
--]]
function ThirdPersonTrackCamera:UpdateCamera(HeadsetCFrameWorld)
    --Set the initial CFrame to use.
    if self.FetchInitialCFrame then
        self.BaseFaceAngleY = math.atan2(-HeadsetCFrameWorld.LookVector.X,-HeadsetCFrameWorld.LookVector.Z)
        self.BaseCFrame = CFrame.new(HeadsetCFrameWorld.Position) * CFrame.Angles(0,self.BaseFaceAngleY,0)
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

    --Set the third person CFrame.
    local HeadsetRelative = self.BaseCFrame:Inverse() * HeadsetCFrameWorld
    Workspace.CurrentCamera.CFrame = self.BaseCFrame * CFrame.new(0,0,-THIRD_PERSON_ZOOM * Scale) * CFrame.Angles(0,math.pi,0) * HeadsetRelative

    --Set the other camera requirements.
    Workspace.CurrentCamera.CameraType = "Scriptable"
    Workspace.CurrentCamera.HeadLocked = false
end



return ThirdPersonTrackCamera