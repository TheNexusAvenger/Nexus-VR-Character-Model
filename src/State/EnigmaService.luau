--Manages reeading UserCframes from Enigma.
--!strict

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local NexusVRCharacterModel = script.Parent.Parent
local Enigma = require(NexusVRCharacterModel:WaitForChild("Enigma"))
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
    local HeadsetWorldCFrame = Character.Parts.Head.CFrame * Character.Head:GetEyesOffset()
    local FloorWorldCFrame = HeadsetWorldCFrame * (UserInputService:GetUserCFrame(Enum.UserCFrame.Head):Inverse() * UserInputService:GetUserCFrame(Enum.UserCFrame.Floor))

    local LeftFootTrackerCFrame = Enigma:GetUserCFrame("LeftFoot")
    local RightFootTrackerCFrame = Enigma:GetUserCFrame("RightFoot")
    local Offsets = {}
    if LeftFootTrackerCFrame and self.Offsets.LeftFoot then
        Offsets.LeftFoot = FloorWorldCFrame * LeftFootTrackerCFrame * self.Offsets.LeftFoot
    end
    if RightFootTrackerCFrame and self.Offsets.RightFoot then
        Offsets.RightFoot = FloorWorldCFrame * RightFootTrackerCFrame * self.Offsets.RightFoot
    end
    return Offsets
end

--[[
Calibrates any inputs based on the current inputs.
--]]
function EnigmaService.Calibrate(self: EnigmaService, Character: any): ()
    local LeftFootTrackerCFrame = Enigma:GetUserCFrame("LeftFoot")
    local RightFootTrackerCFrame = Enigma:GetUserCFrame("RightFoot")
    if not LeftFootTrackerCFrame and not RightFootTrackerCFrame then return end
    local Attachments = Character.Attachments
    local HeadsetWorldCFrame = Workspace.CurrentCamera:GetRenderCFrame()
    local FloorWorldCFrame = HeadsetWorldCFrame * (UserInputService:GetUserCFrame(Enum.UserCFrame.Head):Inverse() * UserInputService:GetUserCFrame(Enum.UserCFrame.Floor))
    
    local NewCharacterHead = Head.new(Character.Parts.Head)
    local HeadWorldCFrame = NewCharacterHead:GetHeadCFrame(HeadsetWorldCFrame)
    local NeckWorldCFrame = NewCharacterHead:GetNeckCFrame(HeadWorldCFrame)
    local LowerTorsoCFrame = NeckWorldCFrame * Attachments.UpperTorso.NeckRigAttachment.CFrame:Inverse() * Attachments.UpperTorso.WaistRigAttachment.CFrame * Attachments.LowerTorso.WaistRigAttachment.CFrame:Inverse()

    if LeftFootTrackerCFrame then
        local LeftFootTrackerWorldCFrame = FloorWorldCFrame * LeftFootTrackerCFrame
        local LeftUpperLegCFrame = LowerTorsoCFrame * Attachments.LowerTorso.LeftHipRigAttachment.CFrame * Attachments.LeftUpperLeg.LeftHipRigAttachment.CFrame:Inverse()
        local LeftLowerLegCFrame = LeftUpperLegCFrame * Attachments.LeftUpperLeg.LeftKneeRigAttachment.CFrame * Attachments.LeftLowerLeg.LeftKneeRigAttachment.CFrame:Inverse()
        local LeftFootCFrame = LeftLowerLegCFrame * Attachments.LeftLowerLeg.LeftAnkleRigAttachment.CFrame * Attachments.LeftFoot.LeftAnkleRigAttachment.CFrame:Inverse()
        self.Offsets.LeftFoot = LeftFootTrackerWorldCFrame:Inverse() * LeftFootCFrame
    end
    if RightFootTrackerCFrame then
        local RightFootTrackerWorldCFrame = FloorWorldCFrame * RightFootTrackerCFrame
        local RightUpperLegCFrame = LowerTorsoCFrame * Attachments.LowerTorso.RightHipRigAttachment.CFrame * Attachments.RightUpperLeg.RightHipRigAttachment.CFrame:Inverse()
        local RightLowerLegCFrame = RightUpperLegCFrame * Attachments.RightUpperLeg.RightKneeRigAttachment.CFrame * Attachments.RightLowerLeg.RightKneeRigAttachment.CFrame:Inverse()
        local RightFootCFrame = RightLowerLegCFrame * Attachments.RightLowerLeg.RightAnkleRigAttachment.CFrame * Attachments.RightFoot.RightAnkleRigAttachment.CFrame:Inverse()
        self.Offsets.RightFoot = RightFootTrackerWorldCFrame:Inverse() * RightFootCFrame
    end
end

--[[
Enables Enigma.
--]]
function EnigmaService.Enable(self: EnigmaService): ()
    Enigma:Enable()
end



return EnigmaService