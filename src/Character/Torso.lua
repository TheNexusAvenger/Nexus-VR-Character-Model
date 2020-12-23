 --[[
TheNexusAvenger

Stores information about the torso of a character.
--]]

local NexusVRCharacterModel = require(script.Parent.Parent)
local Limb = NexusVRCharacterModel:GetResource("Character.Limb")
local Settings = NexusVRCharacterModel:GetInstance("State.Settings")

local Torso = Limb:Extend()
Torso:SetClassName("Torso")



--[[
Creates a torso.
--]]
function Torso:__new(LowerTorso,UpperTorso)
    self:InitializeSuper()

    --Store the parts.
    self.LowerTorso = LowerTorso
    self.UpperTorso = UpperTorso
end

--[[
Returns the lower and upper torso CFrames
for the given neck CFrame in global world space.
--]]
function Torso:GetTorsoCFrames(NeckCFrame)
    --Determine the upper torso CFrame.
    local UpperTorsoCFrame = NeckCFrame * self:GetAttachmentCFrame(self.UpperTorso,"NeckRigAttachment"):inverse()

    --Determine the center CFrame with bending.
    local MaxTorsoBend = Settings:GetSetting("Appearance.MaxTorsoBend") or math.rad(10)
    local NeckTilt = math.asin(NeckCFrame.LookVector.Y)
    local LowerTorsoAngle = math.sign(NeckTilt) * math.min(math.abs(NeckTilt),MaxTorsoBend)
    local TorsoCenterCFrame = UpperTorsoCFrame * self:GetAttachmentCFrame(self.UpperTorso,"WaistRigAttachment") * CFrame.Angles(-LowerTorsoAngle,0,0)

    --Return the lower and upper CFrames.
    return TorsoCenterCFrame * self:GetAttachmentCFrame(self.LowerTorso,"WaistRigAttachment"):inverse(),UpperTorsoCFrame
end

--[[
Returns the CFrames of the joints for
the appendages.
--]]
function Torso:GetAppendageJointCFrames(LowerTorsoCFrame,UpperTorsoCFrame)
    return {
        RightShoulder = UpperTorsoCFrame * self:GetAttachmentCFrame(self.UpperTorso,"RightShoulderRigAttachment"),
        LeftShoulder = UpperTorsoCFrame * self:GetAttachmentCFrame(self.UpperTorso,"LeftShoulderRigAttachment"),
        LeftHip = LowerTorsoCFrame * self:GetAttachmentCFrame(self.LowerTorso,"LeftHipRigAttachment"),
        RightHip = LowerTorsoCFrame * self:GetAttachmentCFrame(self.LowerTorso,"RightHipRigAttachment"),
    }
end



return Torso