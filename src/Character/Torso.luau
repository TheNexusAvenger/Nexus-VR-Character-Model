 --Stores information about the torso of a character.
--!strict

local NexusVRCharacterModel = script.Parent.Parent
local NexusAppendage = require(script.Parent.Parent:WaitForChild("Packages"):WaitForChild("NexusAppendage"))
local Settings = require(NexusVRCharacterModel:WaitForChild("State"):WaitForChild("Settings")).GetInstance()

local Limb = NexusAppendage.Limb

local Torso = {}
Torso.__index = Torso
setmetatable(Torso, Limb)

export type Torso = {
    LowerTorso: BasePart,
    UpperTorso: BasePart,
} & typeof(setmetatable({}, Torso)) & NexusAppendage.Limb



--[[
Creates a torso.
--]]
function Torso.new(LowerTorso: BasePart, UpperTorso: BasePart): Torso
    local self = setmetatable(Limb.new() :: any, Torso) :: Torso
    self.LowerTorso = LowerTorso
    self.UpperTorso = UpperTorso
    return self
end

--[[
Returns the lower and upper torso CFrames
for the given neck CFrame in global world space.
--]]
function Torso.GetTorsoCFrames(self: Torso, NeckCFrame: CFrame): (CFrame, CFrame)
    --Determine the upper torso CFrame.
    local UpperTorsoCFrame = NeckCFrame * self:GetAttachmentCFrame(self.UpperTorso, "NeckRigAttachment"):Inverse()

    --Determine the center CFrame with bending.
    local MaxTorsoBend = Settings:GetSetting("Appearance.MaxTorsoBend") or math.rad(10)
    local NeckTilt = math.asin(NeckCFrame.LookVector.Y)
    local LowerTorsoAngle = math.sign(NeckTilt) * math.min(math.abs(NeckTilt), MaxTorsoBend)
    local TorsoCenterCFrame = UpperTorsoCFrame * self:GetAttachmentCFrame(self.UpperTorso, "WaistRigAttachment") * CFrame.Angles(-LowerTorsoAngle, 0, 0)

    --Return the lower and upper CFrames.
    return TorsoCenterCFrame * self:GetAttachmentCFrame(self.LowerTorso, "WaistRigAttachment"):Inverse(), UpperTorsoCFrame
end

--[[
Returns the CFrames of the joints for
the appendages.
--]]
function Torso.GetAppendageJointCFrames(self: Torso, LowerTorsoCFrame: CFrame, UpperTorsoCFrame: CFrame): {[string]: CFrame}
    return {
        RightShoulder = UpperTorsoCFrame * self:GetAttachmentCFrame(self.UpperTorso, "RightShoulderRigAttachment"),
        LeftShoulder = UpperTorsoCFrame * self:GetAttachmentCFrame(self.UpperTorso, "LeftShoulderRigAttachment"),
        LeftHip = LowerTorsoCFrame * self:GetAttachmentCFrame(self.LowerTorso, "LeftHipRigAttachment"),
        RightHip = LowerTorsoCFrame * self:GetAttachmentCFrame(self.LowerTorso, "RightHipRigAttachment"),
    }
end



return Torso