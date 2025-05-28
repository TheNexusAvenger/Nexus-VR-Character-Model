--Manages reeading UserCframes from Enigma.
--!strict

local THUMBSTICK_DEADZONE = 0.2

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VRService = game:GetService("VRService")

local NexusVRCharacterModel = script.Parent.Parent
local Enigma = require(NexusVRCharacterModel:WaitForChild("Packages"):WaitForChild("Enigma"))
local Head = require(NexusVRCharacterModel:WaitForChild("Character"):WaitForChild("Head"))

local EnigmaService = {}
EnigmaService.__index = EnigmaService
local StaticInstance = nil

export type EnigmaService = {
    Offsets: {
        LeftFoot: CFrame?,
        RightFoot: CFrame?,
    },
} & typeof(setmetatable({}, EnigmaService))
export type TrackerData = {
    LeftFoot: CFrame?,
    RightFoot: CFrame?,
}



--[[
Creates an Enigma service.
--]]
function EnigmaService.new(): EnigmaService
    return setmetatable({
        Offsets = {},
    }, EnigmaService) :: EnigmaService
end

--[[
Returns a singleton instance of the Enigma service.
--]]
function EnigmaService.GetInstance(): EnigmaService
    if not StaticInstance then
        StaticInstance = EnigmaService.new()
    end
    return StaticInstance
end

--[[
Returns the CFrames for the trackers.
--]]
function EnigmaService.GetCFrames(self: EnigmaService, Character: any): TrackerData
    if not Enigma.Enabled then return {} end
    local HeadsetWorldCFrame = Character.Parts.Head.CFrame * Character.Head:GetEyesOffset()
    local OriginWorldCFrame = HeadsetWorldCFrame * UserInputService:GetUserCFrame(Enum.UserCFrame.Head):Inverse()

    local LeftFootTrackerCFrame = Enigma:GetUserCFrame("LeftFoot")
    local RightFootTrackerCFrame = Enigma:GetUserCFrame("RightFoot")
    local Offsets = {}
    if LeftFootTrackerCFrame and self.Offsets.LeftFoot then
        Offsets.LeftFoot = OriginWorldCFrame * LeftFootTrackerCFrame * self.Offsets.LeftFoot
    end
    if RightFootTrackerCFrame and self.Offsets.RightFoot then
        Offsets.RightFoot = OriginWorldCFrame * RightFootTrackerCFrame * self.Offsets.RightFoot
    end
    return Offsets
end

--[[
Calibrates any inputs based on the current inputs.
--]]
function EnigmaService.Calibrate(self: EnigmaService, Character: any): ()
    if not Enigma.Enabled then return end
    local LeftFootTrackerCFrame = Enigma:GetUserCFrame("LeftFoot")
    local RightFootTrackerCFrame = Enigma:GetUserCFrame("RightFoot")
    if not LeftFootTrackerCFrame and not RightFootTrackerCFrame then return end
    local Attachments = Character.Attachments
    local HeadsetWorldCFrame = Workspace.CurrentCamera:GetRenderCFrame()
    local OriginWorldCFrame = HeadsetWorldCFrame * UserInputService:GetUserCFrame(Enum.UserCFrame.Head):Inverse()
    local FloorWorldCFrame = OriginWorldCFrame * UserInputService:GetUserCFrame(Enum.UserCFrame.Floor)
    
    local NewCharacterHead = Head.new(Character.Parts.Head)
    local HeadWorldCFrame = NewCharacterHead:GetHeadCFrame(HeadsetWorldCFrame)
    local NeckWorldCFrame = NewCharacterHead:GetNeckCFrame(HeadWorldCFrame)
    local LowerTorsoCFrame = NeckWorldCFrame * Attachments.UpperTorso.NeckRigAttachment.CFrame:Inverse() * Attachments.UpperTorso.WaistRigAttachment.CFrame * Attachments.LowerTorso.WaistRigAttachment.CFrame:Inverse()

    if LeftFootTrackerCFrame then
        local LeftFootTrackerWorldCFrame = OriginWorldCFrame * LeftFootTrackerCFrame
        local LeftUpperLegCFrame = LowerTorsoCFrame * Attachments.LowerTorso.LeftHipRigAttachment.CFrame * Attachments.LeftUpperLeg.LeftHipRigAttachment.CFrame:Inverse()
        local LeftLowerLegCFrame = LeftUpperLegCFrame * Attachments.LeftUpperLeg.LeftKneeRigAttachment.CFrame * Attachments.LeftLowerLeg.LeftKneeRigAttachment.CFrame:Inverse()
        local LeftFootCFrame = LeftLowerLegCFrame * Attachments.LeftLowerLeg.LeftAnkleRigAttachment.CFrame * Attachments.LeftFoot.LeftAnkleRigAttachment.CFrame:Inverse()
        local LeftFootBottomCFrame = LeftFootCFrame * Attachments.LeftFoot.LeftFootAttachment.CFrame
        LeftFootCFrame = CFrame.new(0, FloorWorldCFrame.Y - LeftFootBottomCFrame.Y, 0) * LeftFootCFrame
        self.Offsets.LeftFoot = LeftFootTrackerWorldCFrame:Inverse() * LeftFootCFrame
    end
    if RightFootTrackerCFrame then
        local RightFootTrackerWorldCFrame = OriginWorldCFrame * RightFootTrackerCFrame
        local RightUpperLegCFrame = LowerTorsoCFrame * Attachments.LowerTorso.RightHipRigAttachment.CFrame * Attachments.RightUpperLeg.RightHipRigAttachment.CFrame:Inverse()
        local RightLowerLegCFrame = RightUpperLegCFrame * Attachments.RightUpperLeg.RightKneeRigAttachment.CFrame * Attachments.RightLowerLeg.RightKneeRigAttachment.CFrame:Inverse()
        local RightFootCFrame = RightLowerLegCFrame * Attachments.RightLowerLeg.RightAnkleRigAttachment.CFrame * Attachments.RightFoot.RightAnkleRigAttachment.CFrame:Inverse()
        local RightFootBottomCFrame = RightFootCFrame * Attachments.RightFoot.RightFootAttachment.CFrame
        RightFootCFrame = CFrame.new(0, FloorWorldCFrame.Y - RightFootBottomCFrame.Y, 0) * RightFootCFrame
        self.Offsets.RightFoot = RightFootTrackerWorldCFrame:Inverse() * RightFootCFrame
    end
end

--[[
Enables Enigma.
--]]
function EnigmaService.Enable(self: EnigmaService): ()
    --Enable Enigma.
    Enigma:Enable()

    --Implement the inputs.
    --Pasting data interrupts the gamepad inputs.
    local LastLeftThumbstick = Vector3.zero
    local ButtonADown = false
    UserInputService.InputBegan:Connect(function(Input)
        if Input.KeyCode == Enum.KeyCode.ButtonA then
            ButtonADown = true
        end
    end)
    UserInputService.InputChanged:Connect(function(Input)
        if Input.KeyCode == Enum.KeyCode.Thumbstick1 then
            if Input.Position.Magnitude > THUMBSTICK_DEADZONE then
                LastLeftThumbstick = Input.Position
            else
                LastLeftThumbstick = Vector3.zero
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(Input)
        if Input.KeyCode == Enum.KeyCode.Thumbstick1 then
            LastLeftThumbstick = Vector3.zero
        elseif Input.KeyCode == Enum.KeyCode.ButtonA then
            ButtonADown = false
        end
    end)

    RunService:BindToRenderStep("EnigmaCustomMovement", Enum.RenderPriority.Input.Value + 1, function()
        --Return if Enigma isn't active.
        if not Enigma:IsActive() then return end

        --Return if the character is invalid.
        local Character = Players.LocalPlayer.Character
        if not Character then return end
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid or Humanoid.Health <= 0 then return end

        --Move the character.
        local MovementReferenceWorldCFrame = Workspace.CurrentCamera:GetRenderCFrame()
        local MovementReferenceRotation = CFrame.new(-MovementReferenceWorldCFrame.Position) * MovementReferenceWorldCFrame
        local MoveDirection = (MovementReferenceRotation * CFrame.new(LastLeftThumbstick.X, 0, -LastLeftThumbstick.Y)).Position
        if MoveDirection.Magnitude > 0.01 or not VRService.AvatarGestures then --Move is not overriden with AvatarGestures since it does continous movements when not walking.
            Players.LocalPlayer:Move(MoveDirection, false)
        end
        if ButtonADown then
            Humanoid.Jump = true
        end
    end)
end



return EnigmaService